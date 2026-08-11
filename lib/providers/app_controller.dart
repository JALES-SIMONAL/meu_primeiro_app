import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/analysis_event.dart';
import '../models/app_log_entry.dart';
import '../models/app_state.dart';
import '../models/channel_edge_mode.dart';
import '../models/channel_live_state.dart';
import '../models/circular_analysis_result.dart';
import '../models/device_file.dart';
import '../models/esp32_device.dart';
import '../models/esp32_device_state.dart';
import '../models/file_data_row.dart';
import '../models/local_measurement_draft.dart';
import '../services/ble_foreground_service.dart';
import '../services/bluetooth_service.dart';
import '../services/circular_analysis_calculator.dart';
import '../services/local_draft_store.dart';

/// Mesmo teto de experimentos::iniciar() / MAX_REPETICOES no firmware — limite
/// de segurança para o loop que descobre quantas repetições um arquivo tem
/// (ver AppController._descobrirRepeticoes).
const int _kMaxRepeticoes = 100;

final appControllerProvider = NotifierProvider<AppController, AppState>(
  AppController.new,
);

class AppController extends Notifier<AppState> {
  AppController({
    BluetoothAppService? bluetoothService,
    CircularAnalysisCalculator? circularCalculator,
    LocalDraftStore? localDraftStore,
  }) : _bluetoothService = bluetoothService ?? FlutterBlueService(),
       _circularCalculator =
           circularCalculator ?? const CircularAnalysisCalculator(),
       _localDraftStore = localDraftStore ?? const LocalDraftStore();

  final BluetoothAppService _bluetoothService;
  final CircularAnalysisCalculator _circularCalculator;
  final LocalDraftStore _localDraftStore;

  StreamSubscription<BleConnectionStateUi>? _bleConnectionSubscription;
  StreamSubscription<String>? _bleLinesSubscription;
  StreamSubscription<List<BleDeviceInfo>>? _bleScanResultsSubscription;
  final Map<String, String> _knownDeviceNames = {};

  // Alimentado por _handleAnaliseEventosMessage — permite que
  // _aguardarRepeticao() espere pela resposta de um "load_repetition"
  // específico sem depender de polling do AppState.
  final _analiseEventosController =
      StreamController<List<AnalysisEvent>>.broadcast();

  // Alimentado por _handleDadosArquivoMessage — permite que
  // _aguardarPaginaArquivo() espere a página pedida a "read_file_data" sem
  // depender/mexer em `state.fileDataRows` (que é da tabela rolante na
  // tela). Carrega só a página nova (não a lista acumulada).
  final _dadosArquivoController =
      StreamController<({List<FileDataRow> linhas, bool temMais})>.broadcast();

  // Alimentado por _handleResultadoNomeMedicaoMessage — permite que
  // saveMeasurementName() espere a resposta de "save_measurement_name".
  final _resultadoNomeMedicaoController =
      StreamController<({bool ok, bool nomeExiste})>.broadcast();

  // Acumula o CSV da medição inteira (todas as repetições já finalizadas,
  // no mesmo formato reconstruído por downloadFileContent) a partir dos
  // eventos ao vivo — rede de segurança para salvar um rascunho local (ver
  // LocalDraftStore) se a medição terminar sem conexão pra nomear/salvar no
  // equipamento. Zerado a cada novo experimento; cada repetição finalizada
  // é "commitada" aqui a partir de liveExperimentEvents antes dele ser
  // limpo (ver _commitarRepeticaoAtual).
  final StringBuffer _medicaoCsvBuffer = StringBuffer();

  // Id do rascunho local criado para a medição ATUALMENTE aguardando nome
  // no equipamento (null se nenhum rascunho foi necessário — ex.: o app só
  // reconectou depois da medição já ter terminado, sem eventos ao vivo
  // acumulados). Apagado quando o nome é salvo com sucesso.
  String? _idRascunhoPendente;

  // Guarda o último dispositivo conectado: quando a conexão BLE cai, o
  // serviço já pode ter limpo seu próprio estado interno, então o evento de
  // desconexão sozinho não carrega mais o deviceId.
  String? _lastDeviceId;

  // Controla a reconexao automatica: uma queda inesperada de conexao (fora
  // do alcance, firmware reiniciou, interferencia) deve levar o app a tentar
  // reconectar sozinho, sem exigir que o usuario va em Bluetooth > Conectar
  // de novo. So NAO tenta quando o proprio usuario pediu a desconexao (botao
  // "Desconectar"). O firmware tem sua propria logica de voltar a anunciar
  // apos perder a conexao (bluetooth_app.cpp) — isso aqui cobre soh o lado
  // do app.
  Timer? _reconnectTimer;
  bool _userInitiatedDisconnect = false;
  static const _reconnectDelay = Duration(seconds: 5);

  @override
  AppState build() {
    _bleConnectionSubscription ??= _bluetoothService.connectionStateChanges
        .listen(_handleConnectionStateChange);
    _bleLinesSubscription ??= _bluetoothService.lines.listen(
      _handleIncomingLine,
    );
    _bleScanResultsSubscription ??= _bluetoothService.scanResults.listen(
      _handleScanResults,
    );
    ref.onDispose(shutdown);
    return AppState.initial(devices: _buildInitialDevices());
  }

  void shutdown() {
    _reconnectTimer?.cancel();
    _bleConnectionSubscription?.cancel();
    _bleLinesSubscription?.cancel();
    _bleScanResultsSubscription?.cancel();
    _analiseEventosController.close();
    _dadosArquivoController.close();
    _resultadoNomeMedicaoController.close();
    _bluetoothService.disconnect();
    BleForegroundService.stop();
  }

  static Map<String, Esp32DeviceState> _buildInitialDevices() => {};

  void addLog(String message, {AppLogLevel level = AppLogLevel.info}) {
    final updatedLogs = List<AppLogEntry>.from(state.logs)
      ..add(
        AppLogEntry(timestamp: DateTime.now(), level: level, message: message),
      );
    const maxLogs = 200;
    if (updatedLogs.length > maxLogs) {
      updatedLogs.removeRange(0, updatedLogs.length - maxLogs);
    }
    state = state.copyWith(logs: updatedLogs, statusMessage: message);
  }

  void clearLogs() {
    state = state.copyWith(logs: const [], statusMessage: null);
  }

  void clearStatusMessage() {
    state = state.copyWith(statusMessage: null);
  }

  void selectDevice(String deviceId) {
    if (!state.devices.containsKey(deviceId)) return;
    state = state.copyWith(selectedDeviceId: deviceId);
  }

  Future<void> startBleScan() async {
    state = state.copyWith(bleScanning: true, bleScanResults: const []);
    addLog('Procurando dispositivos Bluetooth...', level: AppLogLevel.info);
    try {
      await _bluetoothService.startScan();
    } catch (error) {
      addLog('Falha ao escanear Bluetooth: $error', level: AppLogLevel.error);
    } finally {
      state = state.copyWith(bleScanning: false);
    }
  }

  Future<void> stopBleScan() async {
    await _bluetoothService.stopScan();
    state = state.copyWith(bleScanning: false);
  }

  Future<void> connectToDevice(String deviceId) async {
    _userInitiatedDisconnect = false;
    _reconnectTimer?.cancel();
    await stopBleScan();
    try {
      await _bluetoothService.connect(deviceId);
      addLog(
        'Bluetooth conectado a ${_knownDeviceNames[deviceId] ?? deviceId}.',
        level: AppLogLevel.success,
      );
    } catch (error) {
      state = state.copyWith(bleConnected: false);
      addLog('Falha ao conectar Bluetooth: $error', level: AppLogLevel.error);
    }
  }

  Future<void> disconnectBluetooth() async {
    _userInitiatedDisconnect = true;
    _reconnectTimer?.cancel();
    await _bluetoothService.disconnect();
    await BleForegroundService.stop();
    addLog('Bluetooth desconectado.', level: AppLogLevel.info);
  }

  /// Agenda uma nova tentativa de conexao ao ultimo dispositivo apos uma
  /// queda inesperada. Reagendado pelo proprio _handleConnectionStateChange
  /// enquanto a tentativa continuar falhando, ate reconectar ou o usuario
  /// desconectar manualmente.
  void _scheduleReconnect(String deviceId) {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () => _attemptReconnect(deviceId));
  }

  Future<void> _attemptReconnect(String deviceId) async {
    if (_userInitiatedDisconnect || state.bleConnected) return;
    addLog(
      'Tentando reconectar Bluetooth a ${_knownDeviceNames[deviceId] ?? deviceId}...',
      level: AppLogLevel.info,
    );
    try {
      await _bluetoothService.connect(deviceId);
    } catch (_) {
      // connectionStateChanges emite "disconnected" nesse caso, o que
      // reagenda a proxima tentativa via _handleConnectionStateChange.
    }
  }

  void _handleScanResults(List<BleDeviceInfo> results) {
    for (final result in results) {
      _knownDeviceNames[result.id] = result.name;
    }
    state = state.copyWith(bleScanResults: results);
  }

  void _handleConnectionStateChange(BleConnectionStateUi connectionState) {
    switch (connectionState) {
      case BleConnectionStateUi.connected:
        final deviceId = _bluetoothService.connectedDeviceId;
        state = state.copyWith(bleConnected: true);
        if (deviceId != null) {
          _lastDeviceId = deviceId;
          _handleBleConnected(deviceId);
        }
        break;
      case BleConnectionStateUi.disconnected:
        state = state.copyWith(bleConnected: false);
        final deviceId = _lastDeviceId;
        if (deviceId != null) _handleBleDisconnected(deviceId);
        if (deviceId != null && !_userInitiatedDisconnect) {
          _scheduleReconnect(deviceId);
        }
        break;
      case BleConnectionStateUi.connecting:
      case BleConnectionStateUi.disconnecting:
        break;
    }
  }

  /// A própria conexão BLE (GATT connect/disconnect) é o sinal de
  /// online/offline do equipamento — o protocolo não tem mais um tópico
  /// "status" separado como no MQTT antigo. "tempo_us" dos eventos é relativo
  /// à repetição do experimento e reseta a cada repetição, então continua não
  /// servindo como heurística de uptime/reboot.
  void _handleBleConnected(String deviceId) {
    final existed = state.devices.containsKey(deviceId);
    final wasOnline = state.devices[deviceId]?.device.isOnline ?? false;
    _ensureDevice(deviceId, online: true);

    var deviceState = state.devices[deviceId]!;
    deviceState = deviceState.copyWith(
      device: deviceState.device.copyWith(
        isOnline: true,
        lastSeen: DateTime.now(),
      ),
    );

    if (existed && !wasOnline) {
      deviceState = deviceState.copyWith(
        device: deviceState.device.copyWith(
          bootSession: deviceState.device.bootSession + 1,
        ),
        rebootCount: deviceState.rebootCount + 1,
      );
      addLog(
        'Reinicio/reconexao detectado em $deviceId.',
        level: AppLogLevel.warning,
      );
    }

    final updatedDevices = Map<String, Esp32DeviceState>.from(state.devices)
      ..[deviceId] = deviceState;
    state = state.copyWith(devices: updatedDevices);
    selectDevice(deviceId);
    setDateTime();

    // Sem efeito fora do Android (ver BleForegroundService) — mantem o app
    // vivo em segundo plano enquanto durar esta conexao, inclusive apos uma
    // reconexao automatica (_scheduleReconnect/_attemptReconnect chegam
    // aqui pelo mesmo caminho).
    BleForegroundService.start(
      _knownDeviceNames[deviceId] ?? deviceId,
      onError: (mensagem) => addLog(mensagem, level: AppLogLevel.warning),
    );
  }

  void _handleBleDisconnected(String deviceId) {
    final deviceState = state.devices[deviceId];
    if (deviceState == null) return;

    final updatedDevices = Map<String, Esp32DeviceState>.from(state.devices)
      ..[deviceId] = deviceState.copyWith(
        device: deviceState.device.copyWith(
          isOnline: false,
          lastSeen: DateTime.now(),
        ),
      );
    state = state.copyWith(devices: updatedDevices);
  }

  void _handleIncomingLine(String line) {
    if (line.length > 64 * 1024) {
      addLog(
        'Mensagem Bluetooth muito grande descartada.',
        level: AppLogLevel.warning,
      );
      return;
    }

    final deviceId = _bluetoothService.connectedDeviceId ?? _lastDeviceId;
    if (deviceId == null) return;

    Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(line);
      if (decoded is! Map) {
        addLog(
          'Payload Bluetooth invalido recebido.',
          level: AppLogLevel.warning,
        );
        return;
      }
      json = Map<String, dynamic>.from(decoded);
    } catch (error) {
      addLog('JSON invalido recebido: $error', level: AppLogLevel.warning);
      return;
    }

    switch (json['topico']) {
      case 'state':
        _handleStateMessage(deviceId, json);
        break;
      case 'channels':
        _handleChannelsMessage(deviceId, json);
        break;
      case 'info':
        _handleInfoMessage(deviceId, json);
        break;
      case 'teste_canais':
        _handleTesteCanaisMessage(json);
        break;
      case 'files':
        _handleFilesMessage(json);
        break;
      case 'analise_eventos':
        _handleAnaliseEventosMessage(json);
        break;
      case 'event':
        _handleEventoAoVivoMessage(json);
        break;
      case 'dados_arquivo':
        _handleDadosArquivoMessage(json);
        break;
      case 'resultado_nome_medicao':
        _handleResultadoNomeMedicaoMessage(json);
        break;
      default:
        break;
    }
  }

  /// JSON publicado a cada ~1s ("topico":"state",
  /// bluetooth_app.cpp::publicarEstado) com a telemetria operacional do
  /// equipamento.
  void _handleStateMessage(String deviceId, Map<String, dynamic> payload) {
    _ensureDevice(deviceId, online: true);
    final deviceState = state.devices[deviceId]!;

    final channelCount = _asInt(payload['num_canais']);
    final modoOperacao = payload['modo_operacao'];

    // O firmware avança repeticao_atual sozinho ao terminar uma repetição e
    // iniciar a próxima (sem esperar um comando do app) — some se perder
    // esse aviso e não zerar aqui, os eventos ao vivo da repetição anterior
    // ficariam misturados com os da nova na tela de execução. Antes de
    // limpar, commita a repetição recém-finalizada no buffer da medição
    // inteira (ver _commitarRepeticaoAtual/_medicaoCsvBuffer).
    final novaRepeticao = _asInt(payload['repeticao_atual']);
    if (novaRepeticao != null &&
        novaRepeticao != deviceState.device.repetitionCurrent) {
      _commitarRepeticaoAtual();
      state = state.copyWith(liveExperimentEvents: const []);
    }

    final device = deviceState.device.copyWith(
      isOnline: true,
      lastSeen: DateTime.now(),
      channelCount: (channelCount != null && channelCount > 0)
          ? channelCount
          : deviceState.device.channelCount,
      operationMode: modoOperacao == 'app'
          ? DeviceOperationMode.app
          : modoOperacao == 'hardware'
          ? DeviceOperationMode.hardware
          : deviceState.device.operationMode,
      brightness: _asInt(payload['brilho']) ?? deviceState.device.brightness,
      volume: _asInt(payload['volume']) ?? deviceState.device.volume,
      sdCardAvailable: payload['sd_disponivel'] is bool
          ? payload['sd_disponivel'] as bool
          : deviceState.device.sdCardAvailable,
      sdErrorCount:
          _asInt(payload['sd_erros']) ?? deviceState.device.sdErrorCount,
      experimentActive: payload['experimento_ativo'] is bool
          ? payload['experimento_ativo'] as bool
          : deviceState.device.experimentActive,
      repetitionCurrent:
          _asInt(payload['repeticao_atual']) ??
          deviceState.device.repetitionCurrent,
      repetitionsTotal:
          _asInt(payload['repeticoes_totais']) ??
          deviceState.device.repetitionsTotal,
      experimentElapsedSeconds:
          _asInt(payload['tempo_decorrido_s']) ??
          deviceState.device.experimentElapsedSeconds,
      sdUsedKb: _asInt(payload['sd_usado_kb']) ?? deviceState.device.sdUsedKb,
      sdTotalKb: _asInt(payload['sd_total_kb']) ?? deviceState.device.sdTotalKb,
      // Sempre explícito (nunca "?? valor anterior"): precisa voltar para
      // false/vazio assim que o firmware parar de mandar aguardando_nome
      // (medição salva ou nenhuma medição pendente), não só quando true.
      awaitingMeasurementName: payload['aguardando_nome'] == true,
      suggestedMeasurementName:
          payload['nome_sugerido']?.toString() ?? '',
    );

    final updatedDevices = Map<String, Esp32DeviceState>.from(state.devices)
      ..[deviceId] = deviceState.copyWith(device: device);
    state = state.copyWith(devices: updatedDevices);

    final estavaAguardandoNome = deviceState.device.awaitingMeasurementName;
    if (!estavaAguardandoNome && device.awaitingMeasurementName) {
      // Medição acabou de terminar (última repetição): commita o que
      // sobrou em liveExperimentEvents (ainda não passou pelo commit de
      // troca de repetição, já que não há uma "próxima" depois da última)
      // e tenta guardar um rascunho local — vira no-op se o buffer estiver
      // vazio (ver _persistirRascunhoLocal), ex.: medição que já estava
      // pendente antes desta conexão, sem eventos capturados ao vivo aqui.
      _commitarRepeticaoAtual();
      state = state.copyWith(liveExperimentEvents: const []);
      unawaited(
        _persistirRascunhoLocal(deviceId, device.suggestedMeasurementName),
      );
    } else if (estavaAguardandoNome && !device.awaitingMeasurementName) {
      // Resolvida (nomeada/salva) — pelo app (saveMeasurementName) ou pelo
      // menu físico do equipamento, tanto faz: o rascunho local, se existir,
      // não é mais necessário.
      final id = _idRascunhoPendente;
      _idRascunhoPendente = null;
      _medicaoCsvBuffer.clear();
      if (id != null) unawaited(_localDraftStore.excluir(id));
    }
  }

  /// Chamada ao detectar que uma medição acabou de entrar em "aguardando
  /// nome" (ver _handleStateMessage). Só cria o rascunho se houver algo
  /// acumulado localmente — não faz sentido gravar um rascunho vazio (ex.:
  /// o app só reconectou depois da medição já ter terminado, sem receber
  /// nenhum evento ao vivo dela).
  Future<void> _persistirRascunhoLocal(
    String deviceId,
    String nomeSugerido,
  ) async {
    if (_medicaoCsvBuffer.isEmpty) return;
    final conteudo = 'canal,estado,tempo_us\n${_medicaoCsvBuffer.toString()}';
    _medicaoCsvBuffer.clear();

    try {
      final draft = await _localDraftStore.salvar(
        suggestedName: nomeSugerido,
        csvContent: conteudo,
        deviceLabel: _knownDeviceNames[deviceId] ?? deviceId,
      );
      _idRascunhoPendente = draft.id;
      addLog(
        'Medicao "$nomeSugerido" finalizada e salva como rascunho local '
        '(ainda nao nomeada no equipamento).',
        level: AppLogLevel.info,
      );
    } catch (error) {
      addLog('Falha ao salvar rascunho local: $error', level: AppLogLevel.warning);
    }
  }

  /// JSON publicado com a config de canais ("topico":"channels",
  /// bluetooth_app.cpp::publicarConfiguracaoCanais):
  /// `{"canais":[{"canal":i,"modo":m}]}` — usado pela tela "Config. canais".
  void _handleChannelsMessage(String deviceId, Map<String, dynamic> payload) {
    _ensureDevice(deviceId, online: true);

    final canais = payload['canais'];
    if (canais is! List) return;

    final configs = <ChannelConfig>[];
    for (final item in canais) {
      if (item is! Map) continue;
      final canal = _asInt(item['canal']);
      final modo = _asInt(item['modo']);
      if (canal == null || modo == null) continue;
      configs.add(
        ChannelConfig(channel: canal, mode: ChannelEdgeMode.fromValue(modo)),
      );
    }
    state = state.copyWith(channelConfigs: configs);
  }

  /// JSON publicado uma vez por conexão ("topico":"info",
  /// bluetooth_app.cpp::publicarInfoDispositivo) com os dados estáticos do
  /// equipamento — equivalente aos campos fixos da tela "Sobre".
  void _handleInfoMessage(String deviceId, Map<String, dynamic> payload) {
    _ensureDevice(deviceId, online: true);
    final deviceState = state.devices[deviceId]!;

    final device = deviceState.device.copyWith(
      name: payload['equipamento']?.toString() ?? deviceState.device.name,
      firmwareVersion:
          payload['versao_firmware']?.toString() ??
          deviceState.device.firmwareVersion,
      author: payload['autor']?.toString() ?? deviceState.device.author,
      macAddress: payload['mac']?.toString() ?? deviceState.device.macAddress,
      manualUrl:
          payload['manual_url']?.toString() ?? deviceState.device.manualUrl,
      bleDeviceName:
          payload['nome_bt']?.toString() ?? deviceState.device.bleDeviceName,
    );

    final updatedDevices = Map<String, Esp32DeviceState>.from(state.devices)
      ..[deviceId] = deviceState.copyWith(device: device);
    state = state.copyWith(devices: updatedDevices);
  }

  /// JSON periódico ("topico":"teste_canais",
  /// bluetooth_app.cpp::publicarTesteCanais) com o nível ao vivo de cada
  /// canal — equivalente à tela "Teste de canais".
  void _handleTesteCanaisMessage(Map<String, dynamic> payload) {
    final canais = payload['canais'];
    if (canais is! List) return;

    final live = <ChannelLiveState>[];
    for (final item in canais) {
      if (item is! Map) continue;
      final canal = _asInt(item['canal']);
      if (canal == null) continue;
      live.add(
        ChannelLiveState(
          channel: canal,
          high: item['nivel'] == 'H',
          changeCount: _asInt(item['mudancas']) ?? 0,
        ),
      );
    }
    state = state.copyWith(channelLiveStates: live);
  }

  /// JSON sob demanda ("topico":"files",
  /// bluetooth_app.cpp::publicarListaArquivos) — equivalente às telas
  /// "Gerenciamento de arquivos" e "Selecionar arquivo" (análise).
  void _handleFilesMessage(Map<String, dynamic> payload) {
    final arquivos = payload['arquivos'];
    if (arquivos is! List) return;

    final files = <DeviceFile>[];
    for (final item in arquivos) {
      if (item is! Map) continue;
      final nome = item['nome']?.toString();
      final tamanho = _asInt(item['tamanho']);
      if (nome == null || tamanho == null) continue;
      files.add(DeviceFile(name: nome, sizeBytes: tamanho));
    }
    state = state.copyWith(deviceFiles: files);
  }

  /// JSON sob demanda ("topico":"analise_eventos",
  /// bluetooth_app.cpp::publicarEventosAnalise) — equivalente à tela
  /// "Eventos" da análise de dados. Array vazio = repetição sem eventos.
  void _handleAnaliseEventosMessage(Map<String, dynamic> payload) {
    final eventos = payload['eventos'];
    if (eventos is! List) return;

    final events = <AnalysisEvent>[];
    for (final item in eventos) {
      if (item is! Map) continue;
      final canal = _asInt(item['canal']);
      final estado = item['estado']?.toString();
      final tempoUs = _asInt(item['tempo_us']);
      if (canal == null || estado == null || tempoUs == null) continue;
      events.add(
        AnalysisEvent(channel: canal, state: estado, timestampUs: tempoUs),
      );
    }
    state = state.copyWith(loadedAnalysisEvents: events);
    _analiseEventosController.add(events);

    if (events.isEmpty) {
      addLog('Repeticao sem eventos.', level: AppLogLevel.warning);
    }
  }

  /// JSON publicado em tempo real a cada evento válido durante um
  /// experimento ativo ("topico":"event", bluetooth_app.cpp::publicarEvento
  /// <- experimentos::aoReceberEventoValido), já com tempo_us relativo ao
  /// primeiro evento da repetição. Acumulado em liveExperimentEvents, que a
  /// tela de execução do experimento mostra ao vivo — distinto de
  /// loadedAnalysisEvents (repetição já salva, carregada sob demanda).
  void _handleEventoAoVivoMessage(Map<String, dynamic> payload) {
    final canal = _asInt(payload['canal']);
    final estado = payload['estado']?.toString();
    final tempoUs = _asInt(payload['tempo_us']);
    if (canal == null || estado == null || tempoUs == null) return;

    final evento = AnalysisEvent(
      channel: canal,
      state: estado,
      timestampUs: tempoUs,
    );
    state = state.copyWith(
      liveExperimentEvents: [...state.liveExperimentEvents, evento],
    );
  }

  /// JSON em resposta a "save_measurement_name" ("topico":
  /// "resultado_nome_medicao", bluetooth_app.cpp::publicarResultadoNomeMedicao).
  void _handleResultadoNomeMedicaoMessage(Map<String, dynamic> payload) {
    final ok = payload['ok'] == true;
    final nomeExiste = payload['nome_existe'] == true;
    _resultadoNomeMedicaoController.add((ok: ok, nomeExiste: nomeExiste));
  }

  /// Acrescenta liveExperimentEvents (repetição recém-finalizada) ao CSV
  /// acumulado da medição inteira, no mesmo formato de downloadFileContent
  /// (linha em branco SEPARANDO repetições, não uma sobrando no fim). Não
  /// mexe em liveExperimentEvents — quem chama decide se/quando limpar.
  void _commitarRepeticaoAtual() {
    final eventos = state.liveExperimentEvents;
    if (eventos.isEmpty) return;
    if (_medicaoCsvBuffer.isNotEmpty) _medicaoCsvBuffer.writeln();
    for (final evento in eventos) {
      _medicaoCsvBuffer.writeln(
        '${evento.channel},${evento.state},${evento.timestampUs}',
      );
    }
  }

  /// JSON sob demanda ("topico":"dados_arquivo",
  /// bluetooth_app.cpp::publicarDadosArquivo) — uma página da tabela rolante
  /// de dados do arquivo. offset==0 é sempre o início de uma nova consulta
  /// (substitui as linhas atuais); offset>0 é a próxima página (acrescenta).
  void _handleDadosArquivoMessage(Map<String, dynamic> payload) {
    final linhas = payload['linhas'];
    if (linhas is! List) return;

    final offset = _asInt(payload['offset']) ?? 0;
    final novasLinhas = <FileDataRow>[];
    for (final item in linhas) {
      if (item is! Map) continue;
      final repeticao = _asInt(item['repeticao']);
      final canal = _asInt(item['canal']);
      final estado = item['estado']?.toString();
      final tempoUs = _asInt(item['tempo_us']);
      if (repeticao == null ||
          canal == null ||
          estado == null ||
          tempoUs == null) {
        continue;
      }
      novasLinhas.add(
        FileDataRow(
          repetition: repeticao,
          channel: canal,
          state: estado,
          timestampUs: tempoUs,
        ),
      );
    }

    final linhasCompletas = offset == 0
        ? novasLinhas
        : (List<FileDataRow>.from(state.fileDataRows)..addAll(novasLinhas));

    final temMais = payload['tem_mais'] == true;
    state = state.copyWith(
      fileDataRows: linhasCompletas,
      fileDataHasMore: temMais,
    );
    _dadosArquivoController.add((linhas: novasLinhas, temMais: temMais));
  }

  /// Equivalente a analise_dados::calcularIntervalo +
  /// analise_dados::calcularVelocidade, calculado localmente em Dart — os
  /// dois eventos já chegaram ao app na mensagem "analise_eventos", então não
  /// precisa de um comando/mensagem BLE dedicado para o resultado.
  ({int deltaTUs, double velocidadeMs}) computeAnalysisResult(
    AnalysisEvent inicio,
    AnalysisEvent fim,
    double distanciaCm,
  ) {
    final deltaTUs = fim.deltaUsFrom(inicio);
    if (deltaTUs <= 0) return (deltaTUs: deltaTUs, velocidadeMs: 0);

    final distanciaMetros = distanciaCm / 100.0;
    final velocidadeMs = distanciaMetros / (deltaTUs / 1000000.0);
    return (deltaTUs: deltaTUs, velocidadeMs: velocidadeMs);
  }

  // ---------------------------------------------------------------------
  // Envio de comandos para o dispositivo selecionado (característica RX do
  // serviço BLE, bluetooth_app.cpp::processarLinha). Vocabulário de "action"
  // espelha comandos::CommandType do firmware.
  // ---------------------------------------------------------------------

  void _sendCommand(Map<String, dynamic> action) {
    final deviceId = state.selectedDeviceId;
    if (deviceId == null) {
      addLog(
        'Nenhum dispositivo selecionado para enviar comando.',
        level: AppLogLevel.warning,
      );
      return;
    }
    if (!state.bleConnected) {
      addLog(
        'Bluetooth desconectado: comando nao enviado.',
        level: AppLogLevel.warning,
      );
      return;
    }

    _bluetoothService.sendCommand(action);
    addLog(
      'Comando enviado para $deviceId: ${action['action']}.',
      level: AppLogLevel.info,
    );
  }

  void sendNext() => _sendCommand({'action': 'next'});
  void sendPrevious() => _sendCommand({'action': 'previous'});
  void sendConfirm() => _sendCommand({'action': 'confirm'});
  void sendBack() => _sendCommand({'action': 'back'});

  void setBrightness(int nivel) =>
      _sendCommand({'action': 'set_brightness', 'value': nivel});

  void setVolume(int nivel) =>
      _sendCommand({'action': 'set_volume', 'value': nivel});

  void setOperationMode(bool appMode) =>
      _sendCommand({'action': 'set_operation_mode', 'value': appMode ? 1 : 0});

  void startExperiment(int repetitions) {
    // Reenvia a hora antes de iniciar: se o "set_datetime" da conexao (ver
    // _handleBleConnected) tiver se perdido (write BLE sem confirmacao), o
    // nome do arquivo cairia no fallback "MEDICAOn" em vez de "Tddmmaaaa_hhmm"
    // (ver tempo.cpp/experimentos::gerarNomeSugerido no firmware).
    setDateTime();
    state = state.copyWith(liveExperimentEvents: const []);
    _medicaoCsvBuffer.clear();
    _idRascunhoPendente = null;
    _sendCommand({'action': 'start_experiment', 'repetitions': repetitions});
  }

  void stopExperiment() => _sendCommand({'action': 'stop_experiment'});

  void cancelExperiment() {
    state = state.copyWith(liveExperimentEvents: const []);
    _medicaoCsvBuffer.clear();
    _idRascunhoPendente = null;
    _sendCommand({'action': 'cancel_experiment'});
  }

  void finishRepetition() => _sendCommand({'action': 'finish_repetition'});

  /// Descarta os eventos ja coletados na repeticao atual e a reinicia do
  /// zero, sem sair do experimento (equivalente ao "Reiniciar repeticao" da
  /// tela fisica — maquina_estados::confirmarReiniciarRepeticaoSim /
  /// CommandType::RestartRepetition). Zera liveExperimentEvents otimisticamente
  /// (sem esperar confirmacao do equipamento) — o firmware nao manda um
  /// evento dedicado avisando que descartou o buffer da repeticao.
  void restartRepetition() {
    state = state.copyWith(liveExperimentEvents: const []);
    _sendCommand({'action': 'restart_repetition'});
  }

  void reconnectDevice() => _sendCommand({'action': 'reconnect'});

  /// Troca o nome anunciado no BLE (persistido no equipamento) — o mesmo
  /// efeito do "Renomear" na tela física "Conexao com app".
  void setDeviceName(String nome) =>
      _sendCommand({'action': 'set_device_name', 'nome': nome});

  /// Informa a hora atual ao equipamento, que não tem RTC nem noção de fuso
  /// horário próprios (formata o epoch recebido direto como UTC, ver
  /// tempo.cpp). Por isso o epoch enviado aqui usa os campos do horário
  /// *local* do celular "disfarçados" de UTC, para que a hora exibida no
  /// equipamento bata com o relógio de parede do usuário em vez de UTC.
  /// Enviado uma vez a cada conexão BLE (ver _handleBleConnected) para que o
  /// nome sugerido de uma nova medição possa usar data/hora reais em vez de
  /// cair no fallback "MEDICAOn".
  void setDateTime() {
    final agora = DateTime.now();
    final epochLocalComoUtc =
        DateTime.utc(
          agora.year,
          agora.month,
          agora.day,
          agora.hour,
          agora.minute,
          agora.second,
        ).millisecondsSinceEpoch ~/
        1000;
    _sendCommand({'action': 'set_datetime', 'epoch': epochLocalComoUtc});
  }

  void setChannelMode(int canal, ChannelEdgeMode modo) => _sendCommand({
    'action': 'set_channel_mode',
    'channel': canal,
    'mode': modo.value,
  });

  void setAllChannelsMode(ChannelEdgeMode modo) =>
      _sendCommand({'action': 'set_all_channels_mode', 'mode': modo.value});

  void restoreChannelDefaults() =>
      _sendCommand({'action': 'restore_channel_defaults'});

  /// Pede a config. de canais atual sob demanda — chamado ao abrir uma tela
  /// que exibe esse estado, para nunca mostrar um valor obsoleto (de antes
  /// da conexão, ou de uma mudança feita pelo encoder local enquanto o app
  /// estava em outra tela/desconectado).
  void getChannels() => _sendCommand({'action': 'get_channels'});

  void listFiles() => _sendCommand({'action': 'list_files'});

  void renameFile(String from, String to) =>
      _sendCommand({'action': 'rename_file', 'from': from, 'to': to});

  void deleteFile(String nome) =>
      _sendCommand({'action': 'delete_file', 'nome': nome});

  /// Exclui todos os ".csv" do cartão (equivalente ao "Excluir todos" da
  /// tela física — maquina_estados::confirmarExcluirTodosArquivosSim /
  /// CommandType::DeleteAllFiles). O equipamento responde com "files"
  /// atualizado, igual ao delete_file.
  void deleteAllFiles() => _sendCommand({'action': 'delete_all_files'});

  /// Envia o nome escolhido para a medição pendente (ver
  /// awaitingMeasurementName/suggestedMeasurementName em Esp32Device) e
  /// espera a resposta do equipamento ("topico":"resultado_nome_medicao").
  /// Se nomeExiste vier true, o app deve perguntar ao usuário se quer
  /// sobrescrever e, em caso positivo, chamar de novo com
  /// sobrescrever:true — mesmo fluxo de Tela::ExperimentoSobrescreverConfirmar
  /// no menu físico.
  Future<({bool ok, bool nomeExiste})> saveMeasurementName(
    String nome, {
    bool sobrescrever = false,
  }) {
    final resposta = _resultadoNomeMedicaoController.stream.first.timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        addLog(
          'Sem resposta do equipamento ao salvar o nome da medicao.',
          level: AppLogLevel.warning,
        );
        return (ok: false, nomeExiste: false);
      },
    );
    _sendCommand({
      'action': 'save_measurement_name',
      'nome': nome,
      'sobrescrever': sobrescrever,
    });
    return resposta;
  }

  /// Rascunhos locais (ver LocalDraftStore) — funcionam mesmo sem conexão
  /// BLE, já que vivem só no armazenamento do celular/PC.
  Future<List<LocalMeasurementDraft>> listLocalDrafts() =>
      _localDraftStore.listar();

  Future<String?> readLocalDraftContent(String id) =>
      _localDraftStore.lerConteudo(id);

  Future<void> deleteLocalDraft(String id) => _localDraftStore.excluir(id);

  void loadRepetition(String arquivo, int repeticao) => _sendCommand({
    'action': 'load_repetition',
    'arquivo': arquivo,
    'repeticao': repeticao,
  });

  /// Pede a repetição "repeticao" de "arquivo" e espera a resposta
  /// "analise_eventos" correspondente (a característica BLE só tem uma
  /// pergunta em voo por vez nesse protocolo, sem id de correlação — mesma
  /// premissa de loadedAnalysisEvents). Array vazio de volta = repetição
  /// inexistente (analise_dados::carregarRepeticao retornou 0 no firmware)
  /// ou timeout (equipamento não respondeu).
  Future<List<AnalysisEvent>> _aguardarRepeticao(
    String arquivo,
    int repeticao,
  ) {
    final resposta = _analiseEventosController.stream.first.timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        addLog(
          'Sem resposta do equipamento para a repeticao $repeticao de $arquivo.',
          level: AppLogLevel.warning,
        );
        return const <AnalysisEvent>[];
      },
    );
    loadRepetition(arquivo, repeticao);
    return resposta;
  }

  /// Equivalente ao fluxo local "Raio e vaos" -> "Calcular" (tela física):
  /// busca cada repetição de "arquivo" via BLE (o firmware não expõe
  /// analise_circular por BLE, só os eventos brutos — ver
  /// CircularAnalysisCalculator), reproduz localmente
  /// analise_circular::calcular() para cada uma e depois a média entre as
  /// repetições válidas (analise_circular::calcularMediaRepeticoes()).
  Future<void> runCircularAnalysis(
    String arquivo, {
    required int raioMm,
    required int vaosQtd,
  }) async {
    state = state.copyWith(
      circularAnalysisLoading: true,
      circularRaioMm: raioMm,
      circularVaosQtd: vaosQtd,
      circularAverageResult: null,
      circularPerRepetitionResults: const [],
    );

    final raioMetros = raioMm / 1000.0;
    final porRepeticao = <CircularCalcResult?>[];
    for (var indice = 0; indice < _kMaxRepeticoes; indice++) {
      final eventos = await _aguardarRepeticao(arquivo, indice);
      if (eventos.isEmpty) break;
      porRepeticao.add(
        _circularCalculator.calcular(
          eventos,
          raioMetros: raioMetros,
          vaos: vaosQtd,
        ),
      );
    }

    final media = _circularCalculator.calcularMediaRepeticoes(porRepeticao);
    state = state.copyWith(
      circularAnalysisLoading: false,
      circularAverageResult: media,
      circularPerRepetitionResults: porRepeticao,
    );
  }

  /// Prepara os pontos do gráfico "kind" ('velocidade'/'aceleracao'/'rpm')
  /// para exibição: de uma repetição específica (já calculada por
  /// runCircularAnalysis, reaproveitada sem nova consulta BLE) ou a curva
  /// média entre todas (repeticaoIndice==null — equivalente ao item "Media"
  /// de Tela::AnaliseCircularEscolherRepeticao, analise_circular::calcularMediaGrafico()).
  void loadCircularGraph({required String kind, int? repeticaoIndice}) {
    final porRepeticao = state.circularPerRepetitionResults;
    final resultado = repeticaoIndice == null
        ? _circularCalculator.calcularMediaGrafico(
            porRepeticao,
            raioMetros: state.circularRaioMm / 1000.0,
            vaos: state.circularVaosQtd,
          )
        : porRepeticao[repeticaoIndice];

    final List<CircularPoint> pontos;
    final String titulo;
    switch (kind) {
      case 'aceleracao':
        pontos = resultado?.aceleracao ?? const [];
        titulo = 'Aceleracao (m/s2)';
        break;
      case 'rpm':
        pontos = resultado?.rpm ?? const [];
        titulo = 'RPM';
        break;
      default:
        pontos = resultado?.velocidade ?? const [];
        titulo = 'Velocidade (m/s)';
    }

    state = state.copyWith(
      circularGraphPoints: pontos,
      circularGraphTitle: titulo,
    );
  }

  /// Pede uma página (offset em linhas de dados) da tabela rolante de dados
  /// do arquivo. offset==0 começa uma nova consulta (a resposta substitui
  /// `fileDataRows`); offset>0 é rolagem/paginação (a resposta acrescenta).
  void readFileData(String arquivo, int offset) => _sendCommand({
    'action': 'read_file_data',
    'arquivo': arquivo,
    'offset': offset,
  });

  /// Pede a página em "offset" e espera a resposta "dados_arquivo"
  /// correspondente — mesma premissa de _aguardarRepeticao (uma pergunta em
  /// voo por vez, sem id de correlação). Página vazia com tem_mais=false de
  /// volta = fim do arquivo; timeout também encerra (com aviso).
  Future<({List<FileDataRow> linhas, bool temMais})> _aguardarPaginaArquivo(
    String arquivo,
    int offset,
  ) {
    final resposta = _dadosArquivoController.stream.first.timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        addLog(
          'Sem resposta do equipamento ao ler $arquivo (offset $offset).',
          level: AppLogLevel.warning,
        );
        return (linhas: const <FileDataRow>[], temMais: false);
      },
    );
    readFileData(arquivo, offset);
    return resposta;
  }

  /// Busca o arquivo inteiro via "read_file_data" (paginado) e reconstrói o
  /// mesmo texto que armazenamento::abrirNovoArquivo()/enfileirarLinha()
  /// grava no cartão SD do equipamento: cabeçalho "canal,estado,tempo_us",
  /// linhas "canal,estado,tempo_us" e uma linha em branco entre repetições
  /// (armazenamento::enfileirarLinhaEmBranco()). Usada para compartilhar ou
  /// baixar o arquivo — não existe comando BLE que devolva os bytes brutos
  /// do arquivo, só os dados já interpretados linha a linha. Retorna null se
  /// o arquivo não tiver nenhuma linha (vazio ou SD indisponível).
  Future<String?> downloadFileContent(String arquivo) async {
    final linhas = <FileDataRow>[];
    var offset = 0;
    while (true) {
      final pagina = await _aguardarPaginaArquivo(arquivo, offset);
      if (pagina.linhas.isEmpty) break;
      linhas.addAll(pagina.linhas);
      if (!pagina.temMais) break;
      offset = linhas.length;
    }
    if (linhas.isEmpty) return null;

    final buffer = StringBuffer('canal,estado,tempo_us\n');
    int? repeticaoAnterior;
    for (final linha in linhas) {
      if (repeticaoAnterior != null && linha.repetition != repeticaoAnterior) {
        buffer.writeln();
      }
      buffer.writeln('${linha.channel},${linha.state},${linha.timestampUs}');
      repeticaoAnterior = linha.repetition;
    }
    return buffer.toString();
  }

  void _ensureDevice(String deviceId, {bool online = true}) {
    if (state.devices.containsKey(deviceId)) return;

    final device = Esp32Device(
      deviceId: deviceId,
      name: _knownDeviceNames[deviceId] ?? deviceId,
      channelCount: 6,
      isOnline: online,
      lastSeen: DateTime.now(),
    );
    final updatedDevices = Map<String, Esp32DeviceState>.from(state.devices)
      ..[deviceId] = Esp32DeviceState.initial(device);
    state = state.copyWith(devices: updatedDevices);
  }

  int? _asInt(Object? raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is double) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }
}
