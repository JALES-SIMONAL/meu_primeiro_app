# Manual do Usuário — Monkey Tech Data Logger

Este manual explica o que é o aplicativo **Monkey Tech Data Logger** e como usar cada uma de suas funções para operar o equipamento **Gerador UFRN BT** (também identificado como "HardwareFisica" nas telas do app).

## Sumário

1. [O que é o aplicativo](#1-o-que-é-o-aplicativo)
2. [Antes de começar](#2-antes-de-começar)
3. [Conectando ao equipamento](#3-conectando-ao-equipamento)
4. [Navegação geral](#4-navegação-geral)
5. [Aba Experimentos](#5-aba-experimentos)
6. [Aba Análise de Dados](#6-aba-análise-de-dados)
7. [Aba Configurações](#7-aba-configurações)
8. [Rascunhos locais](#8-rascunhos-locais)
9. [Significado das cores](#9-significado-das-cores)
10. [Solução de problemas](#10-solução-de-problemas)

---

## 1. O que é o aplicativo

O **Monkey Tech Data Logger** é o aplicativo complementar do equipamento didático **Gerador UFRN BT**: uma bancada com sensores (canais) que registra eventos de transição (nível alto/baixo) durante experimentos de física, salva os dados em um cartão SD e os transmite por Bluetooth Low Energy (BLE) para o celular ou computador.

Com o aplicativo você pode, sem precisar tocar no encoder do equipamento:

- Ligar e acompanhar experimentos em tempo real;
- Testar cada canal/sensor individualmente;
- Gerenciar, baixar e compartilhar os arquivos `.csv` gravados no equipamento;
- Analisar os dados coletados (movimento linear ou circular), com gráficos;
- Ajustar as configurações do equipamento (brilho, volume, canais, senha, nome do Bluetooth etc.).

O app está disponível para **Android** e **Windows**.

---

## 2. Antes de começar

- O equipamento precisa estar ligado e com o Bluetooth ativo (ele anuncia sozinho ao ligar).
- No celular/computador, o Bluetooth também precisa estar ligado. No Android, o próprio app consegue ligá-lo para você (veja a seção 3).
- No Android, conceder ao app as permissões de Bluetooth e localização é necessário para o escaneamento funcionar (exigência do próprio sistema operacional para apps que escaneiam dispositivos BLE).

---

## 3. Conectando ao equipamento

Há dois caminhos para abrir a tela de Bluetooth:

- Tocando no ícone de Bluetooth que fica sempre visível no canto superior direito do app (em qualquer aba);
- Pela aba **Configurações → Bluetooth**.

Na tela de Bluetooth:

1. Se o Bluetooth do aparelho estiver desligado, um aviso aparece com um botão **Ativar** (no Android, liga o Bluetooth direto pelo app).
2. Toque em **Escanear** para procurar equipamentos por perto. Os dispositivos encontrados aparecem em uma lista, com nome, endereço e força do sinal (RSSI).
3. Toque em **Conectar** ao lado do equipamento desejado.
4. Quando conectado, o ícone de Bluetooth no topo do app fica verde (🔵➜🟢) e a etiqueta muda para "Conectado".

**Reconexão automática:** se a conexão cair inesperadamente (equipamento fora de alcance, descarregou etc.), o app tenta reconectar sozinho ao mesmo equipamento. Se você mesmo pedir para desconectar (botão **Desconectar**), o app não tenta reconectar automaticamente.

---

## 4. Navegação geral

O aplicativo é organizado em três abas principais, sempre visíveis na parte inferior (ou lateral, em telas largas):

| Aba | Para que serve |
|---|---|
| **Experimentos** | Rodar experimentos, testar canais e gerenciar os arquivos do equipamento |
| **Análise de Dados** | Calcular velocidade, aceleração e RPM a partir dos dados coletados |
| **Configurações** | Ajustar o equipamento e a conexão |

A maior parte das telas exige uma conexão Bluetooth ativa — se você não estiver conectado, o app mostra um aviso pedindo para conectar primeiro.

---

## 5. Aba Experimentos

### 5.1 Rodar experimento livre

1. Toque em **Rodar experimento livre**.
2. Informe o número de **Repetições** desejado e toque em **Iniciar**.
3. Durante a execução, a tela mostra a repetição atual, o tempo decorrido e a lista de **eventos ao vivo** (canal, estado e tempo, atualizados em tempo real conforme o equipamento detecta transições).
4. Você tem três ações disponíveis a qualquer momento:
   - **Finalizar repetição** — encerra a repetição atual e avança para a próxima (ou para a nomeação do arquivo, se for a última);
   - **Reiniciar repetição** — descarta os eventos já registrados na repetição atual e recomeça a contagem dela do zero (pede confirmação);
   - **Cancelar experimento** — interrompe tudo e descarta a medição inteira (pede confirmação).
5. Ao concluir a última repetição, o app mostra um formulário para **nomear a medição**: nome de até 20 caracteres, apenas letras e números (sem espaços/acentos/símbolos). Toque em **Salvar** para gravar o arquivo `.csv` no cartão SD do equipamento. Se já existir um arquivo com o mesmo nome, o app pergunta se deseja sobrescrever.

> **Se a conexão cair antes de você nomear a medição**, não se preocupe: os eventos recebidos até aquele momento ficam guardados automaticamente no celular/computador, em **Rascunhos locais** (veja a seção 8). Você pode continuar de onde parou depois.

### 5.2 Teste de canal/sensor

Mostra, para cada canal do equipamento, o nível elétrico atual (**LOW**/**HIGH**) e um indicador colorido:

- 🟢 **Verde** = nível **LOW**
- 🔴 **Vermelho** = nível **HIGH**

A cada transição detectada em um canal, o indicador correspondente **pisca** (aumenta de tamanho e brilha por um instante) — a mesma transição também faz o LED físico daquele canal no equipamento piscar, mesmo que o teste tenha sido iniciado só pelo aplicativo. O contador "N mudanças" mostra quantas transições já ocorreram desde que o equipamento ligou.

### 5.3 Gerenciamento de arquivos

Lista todos os arquivos `.csv` salvos no cartão SD do equipamento. Tocando em um arquivo, você tem acesso a:

- **Ver dados** — tabela com todas as linhas (canal, estado, tempo) do arquivo, organizadas por repetição;
- **Compartilhar** — abre o menu nativo de compartilhamento (e-mail, Drive, WhatsApp etc.). *Não disponível no Windows* (o compartilhamento nativo do Windows não tem suporte estável a esse tipo de arquivo);
- **Baixar** — salva uma cópia do arquivo no celular/computador (no Windows, abre a caixa de diálogo "Salvar como"; no Android, abre o seletor de local de salvamento);
- **Renomear** — muda o nome do arquivo no cartão SD;
- **Excluir** — apaga o arquivo do cartão SD (pede confirmação).

No fim da lista de arquivos, a opção **Excluir todos os arquivos .csv** apaga de uma vez todas as coletas salvas no cartão do equipamento — ação irreversível, usada com cautela (pede confirmação).

---

## 6. Aba Análise de Dados

> Esta aba só aparece habilitada se a função **Análise de dados** estiver ativada nas Configurações do equipamento (veja a seção 7). Se estiver desativada, tocar na aba mostra um aviso pedindo para ativá-la em Configurações — a aba nunca se ativa sozinha só por ser tocada.

1. Escolha um arquivo `.csv` já salvo no equipamento.
2. Escolha o tipo de análise:
   - **Análise linear** — velocidade média entre dois eventos e uma distância informada por você;
   - **Mov. circular** — velocidade, aceleração e RPM a partir do raio de um disco/roda com vãos (fendas), considerando todas as repetições do arquivo.

### Análise linear

Na tabela de eventos da repetição, toque no evento que marca o **início** do intervalo e depois no evento que marca o **fim**. Em seguida, informe a **distância** (em centímetros) percorrida entre esses dois eventos e toque em **Calcular** — o app mostra o tempo decorrido e a velocidade média.

### Movimento circular

Informe o **raio** do disco/roda (em milímetros, de 1 a 500) e a quantidade de **vãos** (fendas) por volta (de 1 a 200), depois toque em **Calcular**. O app busca automaticamente todas as repetições do arquivo pelo Bluetooth e calcula velocidade, aceleração e RPM, com gráficos e médias entre repetições.

---

## 7. Aba Configurações

### Configurações do equipamento

- **Conexão com app** — mostra o status da conexão, endereço MAC, ID do dispositivo e nome anunciado no Bluetooth. A partir daqui você pode:
  - **Renomear** o nome Bluetooth do equipamento (pede senha — veja abaixo);
  - **Reconectar** — força uma desconexão/reconexão;
  - **Trocar senha** — define uma nova senha (3 a 10 caracteres), pedindo a senha atual antes.
- **Modo de operação** — alterna entre "Controle pelo hardware" (uso local, via encoder) e "Controle pelo aplicativo".
- **Brilho da tela** e **Volume** — ajustam o display e o bipe do equipamento (0 a 30).
- **Config. canais/sensores** — define, para cada canal, qual transição conta como evento válido: **H para L**, **L para H**, **Ambos** ou **Desabilitado**. Também é possível configurar todos os canais de uma vez, visualizar a configuração atual, ou restaurar o padrão ("Ambos" para todos).
- **Manual** — exibe um QR Code para o manual do equipamento.
- **Sobre** — versão do firmware, autor e informações do equipamento.
- **Análise de dados** — interruptor para ativar/desativar o acesso à aba Análise de Dados. **Exige senha** para ser alterado (veja "Senha" abaixo).

### Senha

Duas ações são protegidas por senha, tanto pelo app quanto localmente no equipamento: **renomear o Bluetooth** e **ativar/desativar a Análise de dados**. Ao tentar uma dessas ações, o app pede a senha uma vez; enquanto a conexão atual durar, ela não é pedida de novo. Se você trocar a senha em um dos dois lugares (app ou equipamento), a mudança vale para os dois — é a mesma senha, guardada no equipamento.

### Outras opções da aba Configurações

- **Bluetooth** — atalho para a tela de escaneamento/conexão, com botão de desconectar.
- **Rascunhos locais** — veja a seção 8.
- **Logs** — histórico técnico de eventos do app (útil para diagnóstico).
- **Sobre** — informações sobre o próprio aplicativo.

---

## 8. Rascunhos locais

Quando uma medição termina no equipamento (última repetição concluída) mas a conexão cai **antes** de você conseguir dar um nome e salvar, o app guarda automaticamente uma cópia dos eventos recebidos até aquele momento — isso é um **rascunho local**. Ele fica salvo no armazenamento do próprio celular/computador, não no cartão SD do equipamento.

Acesse **Configurações → Rascunhos locais** para ver a lista. Em cada rascunho você pode:

- **Baixar** ou **Compartilhar** a cópia local — funciona mesmo **sem o equipamento conectado**, já que os dados já estão salvos no aparelho;
- **Enviar ao equipamento** — grava definitivamente o rascunho como um arquivo `.csv` no cartão SD (precisa estar conectado via Bluetooth);
- **Excluir rascunho** — descarta a cópia local (ação definitiva; se os dados não tiverem sido enviados ao equipamento antes, eles se perdem).

---

## 9. Significado das cores

### Na tela do aplicativo

| Cor/indicador | Significado |
|---|---|
| 🟢 Ícone de Bluetooth verde no topo | Conectado ao equipamento |
| ⚪ Ícone de Bluetooth sem cor no topo | Desconectado |
| 🟢 Verde no Teste de canal/sensor | Canal em nível **LOW** |
| 🔴 Vermelho no Teste de canal/sensor | Canal em nível **HIGH** |
| Piscada (aumenta e brilha) no indicador de canal | Uma transição (evento) acabou de ser registrada naquele canal |

### No equipamento físico (LEDs coloridos)

O equipamento também dá retorno visual por meio de 6 LEDs coloridos, que valem a pena conhecer mesmo operando tudo pelo app:

| Cor/padrão | Significado |
|---|---|
| Vermelho, azul e verde em sequência, ao ligar | Autoteste de inicialização (não indica erro) |
| Verde/vermelho piscando durante um experimento | Evento registrado no canal correspondente (verde = subiu de nível, vermelho = desceu de nível) |
| Vermelho/verde fixo durante o teste de canais | Nível atual do canal (vermelho = HIGH, verde = LOW) — mesma convenção da tela do app |
| Todos os LEDs piscando em **azul**, duas vezes, com dois bipes curtos | Conexão Bluetooth com o app **bem-sucedida** |
| Todos os LEDs piscando em **amarelo**, uma vez | O app **desconectou** do equipamento |

---

## 10. Solução de problemas

- **Não encontro o equipamento ao escanear**: confirme que ele está ligado e que o Bluetooth do celular/computador está ativo; aproxime-se do equipamento e tente escanear novamente.
- **A conexão cai sozinha com frequência**: afaste-se menos do equipamento; o app tenta reconectar automaticamente assim que possível.
- **Uma aba/opção aparece "cinza"/desabilitada**: normalmente é a aba Análise de Dados — ative-a em Configurações (pode pedir senha).
- **Esqueci a senha**: apenas quem tem acesso físico ao equipamento (ou ao manual técnico) pode restaurar/trocar a senha — solicite ao responsável pelo equipamento.
- **O botão Baixar/Compartilhar falhou**: tente novamente; no Windows, use sempre "Baixar" (Compartilhar não é oferecido nessa plataforma).
- **Uma medição "sumiu"**: verifique **Rascunhos locais** — se a conexão caiu antes de nomear, ela provavelmente está lá.
