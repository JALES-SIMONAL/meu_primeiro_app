# Manual Técnico — Monkey Tech Data Logger / Gerador UFRN BT

Documentação técnica do sistema completo: aplicativo Flutter (**Monkey Tech Data Logger**) e firmware ESP32 (**Gerador UFRN BT** / "HardwareFisica"), incluindo o protocolo de comunicação Bluetooth entre eles.

- Repositório do app: `meu_primeiro_app` (Flutter/Dart)
- Repositório do firmware: `HardwareFisicaV2.0` (PlatformIO/Arduino, ESP32)

## Sumário

1. [Visão geral da arquitetura](#1-visão-geral-da-arquitetura)
2. [Firmware](#2-firmware)
3. [Aplicativo](#3-aplicativo)
4. [Protocolo BLE](#4-protocolo-ble)
5. [Segurança e senha](#5-segurança-e-senha)
6. [Significado das cores](#6-significado-das-cores)
7. [Build e testes](#7-build-e-testes)

---

## 1. Visão geral da arquitetura

```
┌─────────────────────────┐        BLE (Nordic UART Service)       ┌──────────────────────────┐
│   App (Flutter/Dart)    │ <-------------------------------------> │  Firmware (ESP32/Arduino) │
│  Riverpod: AppController│         JSON por linha ("\n")           │  maquina_estados.cpp       │
└─────────────────────────┘                                         └──────────────────────────┘
```

O equipamento físico ("Gerador UFRN BT") roda em um ESP32 (framework Arduino, gerenciado via PlatformIO) com display TFT, encoder rotativo + tecla, 6 LEDs NeoPixel endereçáveis, buzzer, cartão microSD e até 6 canais de sensores digitais. Toda a lógica de navegação/estado é centralizada em `maquina_estados.cpp`, que recebe comandos **tanto** do encoder local **quanto** do Bluetooth através da mesma estrutura (`comandos::Command`) — não existe lógica de funcionamento duplicada entre as duas origens.

O aplicativo (Flutter, gerenciamento de estado via Riverpod) se conecta ao equipamento por BLE, envia comandos e recebe mensagens de estado/dados em JSON. Ele também mantém um armazenamento **local** (rascunhos de medições) independente do cartão SD do equipamento.

---

## 2. Firmware

### 2.1 Módulos principais

| Módulo | Responsabilidade |
|---|---|
| `main.cpp` | `setup()`/`loop()`; cria a tarefa de aquisição/armazenamento no núcleo 0 |
| `maquina_estados.cpp` | Dono único da navegação entre telas, transições e confirmações; despacha comandos locais e remotos |
| `ihm.cpp` | Display TFT, encoder/tecla, LEDs NeoPixel, buzzer, brilho (PWM) — única camada que toca hardware de IHM |
| `bluetooth_app.cpp` | Servidor BLE (NimBLE), parsing de comandos JSON recebidos, publicação das mensagens de estado |
| `experimentos.cpp` | Ciclo de vida do experimento livre (repetições, buffer de eventos, nome sugerido, LEDs de evento) |
| `armazenamento.cpp` | Leitura/escrita no cartão microSD |
| `configuracoes.cpp` | Persistência em NVS/Preferences (brilho, volume, modo de operação, senha, análise de dados habilitada) |
| `canais.cpp` / `aquisicao.cpp` | Configuração de modo de borda por canal e leitura/filtragem dos eventos válidos |
| `comandos.hpp` | Vocabulário compartilhado (`CommandType`, `Command`, `EdgeMode`, `Origem`) entre entrada local e remota |

### 2.2 Núcleos e tarefas (FreeRTOS)

- **Núcleo 0** (`tarefaAquisicaoArmazenamento`): faz *polling* dos canais de sensores, drena a fila de linhas CSV para o cartão SD e atualiza os LEDs de evento — em loop apertado (`vTaskDelay(1)`), **independente** da tela exibida.
- **Núcleo 1** (`loop()` padrão do Arduino-ESP32): chama `maquina_estados::tick()` continuamente, que por sua vez chama `bluetooth_app::loop()`, lê o encoder/tecla local e redesenha a tela quando necessário.

Como a aquisição roda em uma tarefa própria, **um experimento continua coletando dados em segundo plano mesmo que o usuário navegue para outra tela** (local ou remotamente) — não é preciso ficar na tela de execução para a coleta continuar.

### 2.3 Máquina de estados local

- Entrada local: só três comandos são gerados pelo encoder físico — `Next` (giro horário), `Previous` (giro anti-horário) e `Confirm` (clique da tecla KEY). **Não existe um botão de "Voltar" físico dedicado** — toda tela navegável localmente precisa oferecer um item "Voltar" na própria lista (ou, no editor de texto reaproveitado, um marcador "ESC" no alfabeto).
- `CommandType::Back` existe no vocabulário, mas só é produzido pelo Bluetooth (o app pode enviar `{"action":"back"}`); é tratado de forma equivalente ao "Voltar" local onde faz sentido.
- Navegação em pilha (`pilhaNavegacao`, até 16 níveis): cada `navegarPara()` empilha a tela de origem; `voltarUmNivel()` desempilha. Se o destino de `navegarPara()` já é um ancestral na pilha atual, ela é truncada até lá em vez de crescer (evita reabrir uma tela de confirmação já resolvida).
- A tela de execução do experimento (`Tela::ExperimentoExecucao`) tem 4 itens: **Finalizar repetição**, **Reiniciar repetição**, **Cancelar experimento** e **Voltar** — este último sai da tela **sem cancelar** a medição (que continua rodando em segundo plano, ver 2.2). Selecionar "Rodar experimento livre" novamente com uma medição já em andamento retoma essa mesma tela ao vivo, em vez de tentar configurar uma medição nova (`experimentos::iniciar()` recusa reiniciar quando já há uma em andamento, por segurança).

### 2.4 Armazenamento (cartão SD)

- Arquivo de trabalho fixo `_tmp_exp.csv`, reaberto a cada novo experimento (`experimentos::iniciar()`).
- Formato de cada linha de dado: `canal,estado,tempo_us` (ex.: `3,H,125340`), onde `tempo_us` é relativo ao **primeiro evento válido da repetição** (não ao instante em que a repetição começou).
- Uma **linha em branco** separa repetições dentro do mesmo arquivo.
- Ao finalizar a última repetição, o arquivo é fechado e o firmware entra em `Fase::AguardandoNome`, sugerindo um nome (data/hora, se conhecida via `set_datetime`; senão `MEDICAOn` com contador persistido em NVS) até que app ou encoder local confirmem o nome final (renomeando `_tmp_exp.csv` para `<nome>.csv`).
- `experimentos::iniciar()` recusa iniciar uma nova medição enquanto a anterior ainda está em `Executando` **ou** `AguardandoNome` — evita sobrescrever silenciosamente `_tmp_exp.csv` e perder dados não salvos.

### 2.5 Configurações persistidas (NVS/Preferences)

Brilho (0–30), volume (0–30), modo de operação (`Hardware`/`App`), nome anunciado no BLE, análise de dados habilitada (bool) e a senha de ações protegidas — todos sobrevivem a reinicializações. Ver seção 5 para detalhes da senha.

---

## 3. Aplicativo

### 3.1 Arquitetura

- **Gerenciamento de estado**: Riverpod, `NotifierProvider<AppController, AppState>` (`appControllerProvider`) como fonte única de verdade — dispositivos, conexão, arquivos, eventos ao vivo, resultados de análise etc.
- **Camada de transporte BLE**: interface `BluetoothAppService`, implementada por `FlutterBlueService` (pacote `flutter_blue_plus`); expõe streams de conexão, dispositivos escaneados, mensagens recebidas e estado do adaptador Bluetooth (`adapterOn`, com `turnOnAdapter()` no Android).
- **Rascunhos locais**: `LocalDraftStore`, persistência independente do BLE (arquivos no armazenamento do próprio app) para medições finalizadas sem nome salvo no equipamento.

### 3.2 Estrutura de pastas (`lib/`)

```
app/            MaterialApp raiz
core/           tema, utilitários (formatação)
features/       uma pasta por tela/fluxo (bluetooth, equipment/experimentos,
                equipment/analise, equipment/configuracoes, settings, logs, about, shell)
models/         classes de dados (Esp32Device, ChannelLiveState, AnalysisEvent, ...)
providers/      app_controller.dart (toda a lógica de negócio do app)
services/       bluetooth_service.dart, ble_foreground_service.dart (Android)
widgets/        componentes reaproveitados (BorderedListTile, ZebraRow, CsvExportTiles, ...)
```

### 3.3 Exportação de arquivos (Baixar/Compartilhar)

`CsvExportTiles` (widget reaproveitado por arquivos do equipamento e rascunhos locais):

- **Baixar**: no Windows usa `file_selector` (diálogo nativo `IFileSaveDialog`, escrita dos bytes em Dart); nas demais plataformas usa `file_saver` (`saveAs`, com diálogo nativo de salvamento). O `saveAs` do `file_saver` no Windows usa uma API legada (`GetSaveFileName`) sem tratamento de exceção em C++ e podia derrubar o processo — por isso o Windows usa `file_selector` em vez disso.
- **Compartilhar**: `share_plus`, disponível em **todas as plataformas exceto Windows** (o compartilhamento nativo do Windows tem suporte instável a apps-alvo fora do controle do app).

### 3.4 Rascunhos locais

Quando o firmware publica `"aguardando_nome": true` (medição finalizada sem nome) e a conexão cai antes do usuário salvá-la, o `AppController` já acumulou os eventos ao vivo (`"topico":"event"`) recebidos durante aquela repetição/medição; esse conteúdo é persistido pelo `LocalDraftStore` como um rascunho local, associado ao dispositivo de origem. O rascunho pode ser baixado/compartilhado offline, ou enviado ao equipamento (`save_measurement_name`) quando a conexão for restabelecida — nesse caso o app apaga o rascunho local automaticamente ao ver `aguardando_nome` voltar para `false`.

---

## 4. Protocolo BLE

### 4.1 Transporte

- Perfil: **Nordic UART Service (NUS)**.
- UUIDs:
  - Serviço: `6E400001-B5A3-F393-E0A9-E50E24DCCA9E`
  - Característica RX (app → firmware, `WRITE`/`WRITE_NR`): `6E400002-B5A3-F393-E0A9-E50E24DCCA9E`
  - Característica TX (firmware → app, `NOTIFY`): `6E400003-B5A3-F393-E0A9-E50E24DCCA9E`
- Formato: uma mensagem **JSON por linha**, terminada em `\n` (ou `\r`). O app identifica o tipo de mensagem recebida pelo campo `"topico"`; o firmware identifica o comando recebido pelo campo `"action"`.
- Nome anunciado (advertising) padrão: `Gerador_UFRN_BT` (alterável, ver `set_device_name`).

### 4.2 Mensagens do firmware → app (`"topico"`)

| Tópico | Quando é enviada | Principais campos |
|---|---|---|
| `state` | A cada conexão e depois 1x/segundo (`INTERVALO_PUBLICACAO_ESTADO_MS`) | `modo_operacao`, `brilho`, `volume`, `sd_disponivel`, `sd_erros`, `experimento_ativo`, `repeticao_atual`, `repeticoes_totais`, `eventos_repeticao`, `num_canais`, `tempo_decorrido_s`, `sd_usado_kb`, `sd_total_kb`, `aguardando_nome`, `nome_sugerido` (só se aguardando), `analise_dados_habilitada` |
| `info` | Ao conectar, e após `set_device_name` | `equipamento`, `versao_firmware`, `autor`, `device_id`, `mac`, `manual_url`, `nome_bt` |
| `teste_canais` | A cada conexão e depois a cada ~300ms (`INTERVALO_PUBLICACAO_TESTE_CANAIS_MS`), sempre que conectado | `canais`: lista de `{canal, nivel ("H"/"L"), mudancas}` |
| `channels` | Ao conectar, após qualquer mudança de modo, e sob demanda (`get_channels`) | `canais`: lista de `{canal, modo}` (0=Falling, 1=Rising, 2=Both, 3=Disabled) |
| `event` | Em tempo real, a cada evento válido durante um experimento ativo | `canal`, `estado` ("H"/"L"), `tempo_us` (relativo ao 1º evento da repetição) |
| `files` | Sob demanda (`list_files`) e após qualquer operação que mude a lista | `arquivos`: lista de `{nome, tamanho}` |
| `analise_eventos` | Sob demanda (`load_repetition`) | `eventos`: lista de `{canal, estado, tempo_us}` da repetição carregada |
| `dados_arquivo` | Sob demanda (`read_file_data`), paginado | `arquivo`, `offset`, `linhas`: lista de `{repeticao, canal, estado, tempo_us}`, `tem_mais` |
| `resultado_nome_medicao` | Resposta a `save_measurement_name` | `ok`, `nome_existe` |
| `resultado_acao_protegida` | Resposta a `set_device_name` / `set_data_analysis_enabled` / `set_password` | `acao`, `ok` |

### 4.3 Comandos do app → firmware (`"action"`)

| Action | Campos | Efeito |
|---|---|---|
| `next` / `previous` / `confirm` / `back` | — | Equivalente ao encoder/tecla local |
| `set_brightness` | `value` (0–30) | Brilho da tela |
| `set_volume` | `value` (0–30) | Volume do buzzer |
| `set_operation_mode` | `value` (0=Hardware, 1=App) | Modo de operação |
| `set_channel_mode` | `channel`, `mode` (0–3) | Modo de borda de um canal |
| `set_all_channels_mode` | `mode` | Modo de borda de todos os canais |
| `restore_channel_defaults` | — | Restaura todos os canais para "Ambos" |
| `get_channels` | — | Pede publicação de `channels` sob demanda |
| `start_experiment` | `repetitions` | Inicia experimento livre |
| `stop_experiment` / `cancel_experiment` | — | Cancela o experimento em andamento |
| `finish_repetition` | — | Finaliza a repetição atual |
| `restart_repetition` | — | Descarta eventos da repetição atual e reinicia sua contagem |
| `save_measurement_name` | `nome`, `sobrescrever` (bool) | Salva a medição pendente com o nome informado |
| `set_channel_test_active` | `ativo` (bool) | Avisa que a tela de teste de canais foi aberta/fechada no app — aciona os NeoPixels físicos mesmo quando o teste é só remoto |
| `list_files` | — | Pede publicação de `files` |
| `rename_file` | `from`, `to` | Renomeia um arquivo no cartão SD |
| `delete_file` | `nome` | Exclui um arquivo |
| `delete_all_files` | — | Exclui todos os `.csv` do cartão SD |
| `read_file_data` | `arquivo`, `offset` | Pede uma página de `dados_arquivo` |
| `load_repetition` | `arquivo`, `repeticao` | Carrega uma repetição para análise (`analise_eventos`) |
| `set_device_name` | `nome`, `senha` | **Protegido por senha** — renomeia o Bluetooth |
| `set_datetime` | `epoch` (segundos, UTC) | Informa data/hora atual (usada para sugerir nome de medição) |
| `set_data_analysis_enabled` | `habilitado` (bool), `senha` | **Protegido por senha** — ativa/desativa a aba Análise de Dados |
| `set_password` | `senha_atual`, `nova_senha` | **Protegido por senha** — troca a senha de ações protegidas |
| `reconnect` | — | Força o firmware a derrubar a conexão BLE atual |

---

## 5. Segurança e senha

- **Senha padrão de fábrica: `fisica123`** (`configuracoes::SENHA_PADRAO`).
- Tamanho permitido: **3 a 10 caracteres** (`SENHA_TAMANHO_MINIMO`/`SENHA_TAMANHO_MAXIMO`).
- Comparação **case-insensitive** (`senhasIguaisSemCase`): o teclado físico do equipamento (alfabeto do editor de texto reaproveitado) só produz letras maiúsculas, então a validação ignora maiúsculas/minúsculas para que a senha padrão em minúsculas continue funcionando também pelo encoder local.
- Guardada em **texto puro** na NVS — não é criptografia forte, apenas um PIN simples para evitar alterações acidentais/não autorizadas por quem tiver acesso físico ou BLE ao equipamento.
- **Ações protegidas** (as mesmas, seja pelo app ou pelo encoder local): renomear o dispositivo Bluetooth e ativar/desativar a "Análise de dados". Trocar a senha também exige a senha atual.
- **Cache por sessão**: tanto o firmware (`senhaValidadaNestaSessao`, válida desde o boot) quanto o app (`_senhaValidadaNestaConexao`/`_senhaCache`, reiniciado a cada nova conexão BLE) evitam pedir a senha repetidamente — uma vez validada durante a sessão/conexão atual, as próximas ações protegidas não pedem a senha de novo.
- Alterar a senha em um dos dois lados (app ou encoder físico) reflete imediatamente no outro, pois ambos leem/gravam o mesmo valor persistido no firmware — o app não guarda senha própria, apenas o cache de sessão citado acima.

---

## 6. Significado das cores

### 6.1 NeoPixels do equipamento (6 LEDs, `ihm::controlarLED`/`controlarTodosLeds`)

| Situação | Cor / padrão | Detalhe |
|---|---|---|
| Autoteste de boot | Vermelho → Azul → Verde → Apagado | ~500ms cada, decorativo/diagnóstico, não indica erro |
| Evento durante experimento (`experimentos::aoReceberEventoValido`) | Verde = L→H · Vermelho = H→L | Apenas o LED do canal correspondente, por 150ms (`DURACAO_PISCA_LED_MS`) |
| Teste de canais (local ou remoto via app, `set_channel_test_active`) | Vermelho = HIGH · Verde = LOW | Todos os LEDs relevantes, atualizado continuamente (nível, não pulso) enquanto a tela/teste estiver ativo |
| Conexão BLE bem-sucedida (`ihm::iniciarIndicacaoConexao`) | Todos piscam **azul**, 2x, com 2 bipes curtos (~80ms cada) | Não-bloqueante, dura exatamente **1.5s** (dois ciclos de 375ms on/off) |
| Desconexão BLE (`ihm::iniciarIndicacaoDesconexao`) | Todos piscam **amarelo**, 1x | 400ms, sem bipe |

A indicação de conexão/desconexão tem prioridade visual sobre os LEDs do teste de canais quando os dois coincidem (chamada depois, em `maquina_estados::tick()`).

### 6.2 Tela do aplicativo

| Situação | Cor | Detalhe |
|---|---|---|
| Ícone de Bluetooth no topo do app | Verde = conectado · Padrão = desconectado | `state.bleConnected` |
| Teste de canal/sensor | Verde = LOW · Vermelho = HIGH | Mesma convenção do NeoPixel físico (invertida em relação a uma primeira versão do app, corrigida para bater com o firmware) |
| Piscada no indicador de canal | Escala/brilho aumentam por 200ms | Disparada por incremento do contador `mudancas` (mesmo campo publicado em `teste_canais`) |

---

## 7. Build e testes

### Firmware (PlatformIO)

```bash
platformio run -e esp32doit-devkit-v1              # build de produção
platformio run -e esp32doit-devkit-v1-selftest      # build com autotestes (ENABLE_FIRMWARE_SELF_TESTS)
```

### Aplicativo (Flutter)

```bash
flutter analyze          # análise estática
flutter test             # suíte de testes (providers, services, widgets)
flutter build apk        # build Android
flutter build windows    # build Windows
```

Os testes de `AppController` (`test/providers/app_controller_test.dart`) usam duplos de teste (`_FakeBluetoothService`, `_FakeLocalDraftStore`) e o pacote `fake_async` para simular temporizadores (reconexão automática, cache de senha por conexão) sem depender de tempo real.
