import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/analysis_event.dart';
import '../models/app_log_entry.dart';
import '../models/app_state.dart';
import '../models/channel_edge_mode.dart';
import '../models/channel_live_state.dart';
import '../models/collection_session.dart';
import '../models/device_file.dart';
import '../models/esp32_device.dart';
import '../models/esp32_device_state.dart';
import '../models/file_data_row.dart';
import '../models/sensor_record.dart';
import '../services/bluetooth_service.dart';
import '../services/csv_service.dart';
import '../services/sensor_message_parser.dart';
import '../core/utils/formatters.dart';

final appControllerProvider = NotifierProvider<AppController, AppState>(
  AppController.new,
);

class AppController extends Notifier<AppState> {
  AppController({
    BluetoothAppService? bluetoothService,
    CsvService? csvService,
    SensorMessageParser? parser,
  }) : _bluetoothService = bluetoothService ?? FlutterBlueService(),
       _csvService = csvService ?? CsvService(),
       _parser = parser ?? SensorMessageParser();

  final BluetoothAppService _bluetoothService;
  final CsvService _csvService;
  final SensorMessageParser _parser;
  final Uuid _uuid = const Uuid();

  StreamSubscription<BleConnectionStateUi>? _bleConnectionSubscription;
  StreamSubscription<String>? _bleLinesSubscription;
  StreamSubscription<List<BleDeviceInfo>>? _bleScanResultsSubscription;
  final Map<String, String> _knownDeviceNames = {};

  // Guarda o último dispositivo conectado: quando a conexão BLE cai, o
  // serviço já pode ter limpo seu próprio estado interno, então o evento de
  // desconexão sozinho não carrega mais o deviceId.
  String? _lastDeviceId;

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
    _bleConnectionSubscription?.cancel();
    _bleLinesSubscription?.cancel();
    _bleScanResultsSubscription?.cancel();
    _bluetoothService.disconnect();
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
    final collection = state.collectionSession;
    if (collection != null &&
        collection.stage == CollectionStage.running &&
        state.selectedDeviceId != deviceId) {
      addLog(
        'Selecao bloqueada durante a coleta ativa.',
        level: AppLogLevel.warning,
      );
      return;
    }

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
    await _bluetoothService.disconnect();
    addLog('Bluetooth desconectado.', level: AppLogLevel.info);
  }

  void simulateDeviceReboot(String deviceId) {
    final deviceState = state.devices[deviceId];
    if (deviceState == null) return;

    final updatedDevice = deviceState.copyWith(
      device: deviceState.device.copyWith(
        bootSession: deviceState.device.bootSession + 1,
        uptimeMs: 0,
        lastSeen: DateTime.now(),
        isOnline: true,
      ),
      rebootCount: deviceState.rebootCount + 1,
      lastTimestampMs: 0,
      lastUptimeMs: 0,
    );

    final updatedDevices = Map<String, Esp32DeviceState>.from(state.devices)
      ..[deviceId] = updatedDevice;
    state = state.copyWith(devices: updatedDevices);
    addLog('Reinicio simulado para $deviceId.', level: AppLogLevel.warning);
  }

  void setDeviceOnline(String deviceId, bool online) {
    final deviceState = state.devices[deviceId];
    if (deviceState == null) return;

    final updatedDevices = Map<String, Esp32DeviceState>.from(state.devices)
      ..[deviceId] = deviceState.copyWith(
        device: deviceState.device.copyWith(
          isOnline: online,
          lastSeen: DateTime.now(),
        ),
      );
    state = state.copyWith(devices: updatedDevices);
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
        addLog('Payload Bluetooth invalido recebido.', level: AppLogLevel.warning);
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
      case 'event':
        _handleEventMessage(deviceId, json);
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
      case 'dados_arquivo':
        _handleDadosArquivoMessage(json);
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
      sdErrorCount: _asInt(payload['sd_erros']) ?? deviceState.device.sdErrorCount,
      experimentActive: payload['experimento_ativo'] is bool
          ? payload['experimento_ativo'] as bool
          : deviceState.device.experimentActive,
      repetitionCurrent:
          _asInt(payload['repeticao_atual']) ?? deviceState.device.repetitionCurrent,
      repetitionsTotal:
          _asInt(payload['repeticoes_totais']) ?? deviceState.device.repetitionsTotal,
      experimentElapsedSeconds: _asInt(payload['tempo_decorrido_s']) ??
          deviceState.device.experimentElapsedSeconds,
      sdUsedKb: _asInt(payload['sd_usado_kb']) ?? deviceState.device.sdUsedKb,
      sdTotalKb: _asInt(payload['sd_total_kb']) ?? deviceState.device.sdTotalKb,
    );

    var channels = deviceState.channels;
    if (channelCount != null &&
        channelCount > 0 &&
        channelCount != deviceState.channels.length) {
      channels = {
        for (var sensor = 1; sensor <= channelCount; sensor++)
          sensor: deviceState.channels[sensor] ?? ChannelState.empty(sensor),
      };
    }

    final updatedDevices = Map<String, Esp32DeviceState>.from(state.devices)
      ..[deviceId] = deviceState.copyWith(device: device, channels: channels);
    state = state.copyWith(devices: updatedDevices);
  }

  /// JSON publicado por transição de canal ("topico":"event",
  /// bluetooth_app.cpp::publicarEvento): `{"canal":N,"estado":"H"/"L","tempo_us":N}`.
  void _handleEventMessage(String deviceId, Map<String, dynamic> payload) {
    _ensureDevice(deviceId, online: true);

    final result = _parser.parseEvent(payload);
    if (!result.isAccepted) {
      addLog(
        'Evento rejeitado de $deviceId: ${result.rejectReason}',
        level: AppLogLevel.warning,
      );
      _bumpInvalidCount(deviceId);
      return;
    }

    _ingestReading(deviceId, result.reading!);
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
      firmwareVersion: payload['versao_firmware']?.toString() ??
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

    if (events.isEmpty) {
      addLog('Repeticao sem eventos.', level: AppLogLevel.warning);
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
      if (repeticao == null || canal == null || estado == null || tempoUs == null) {
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

    state = state.copyWith(
      fileDataRows: linhasCompletas,
      fileDataHasMore: payload['tem_mais'] == true,
    );
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

  void _ingestReading(String deviceId, ParsedReading reading) {
    _ensureDevice(deviceId, online: true);

    var workingDeviceState = state.devices[deviceId]!;
    workingDeviceState = workingDeviceState.copyWith(
      device: workingDeviceState.device.copyWith(
        isOnline: true,
        lastSeen: DateTime.now(),
      ),
    );

    final nextChannelState = _updateChannel(
      workingDeviceState.channels[reading.sensor],
      reading,
    );
    final updatedChannels = Map<int, ChannelState>.from(
      workingDeviceState.channels,
    )..[reading.sensor] = nextChannelState;

    final record = SensorRecord(
      deviceId: deviceId,
      sensor: reading.sensor,
      state: reading.state,
      timestampMs: reading.timestampMs,
      receivedAt: DateTime.now(),
      bootSession: workingDeviceState.device.bootSession,
    );

    workingDeviceState = workingDeviceState.copyWith(
      channels: updatedChannels,
      totalMessages: workingDeviceState.totalMessages + 1,
      lastTimestampMs: reading.timestampMs,
    );

    final updatedDevices = Map<String, Esp32DeviceState>.from(state.devices)
      ..[deviceId] = workingDeviceState;
    final updatedRecords = _appendRecords(deviceId, [record]);

    state = state.copyWith(devices: updatedDevices, recordsByDevice: updatedRecords);

    if (state.collectionSession != null &&
        state.collectionSession!.stage == CollectionStage.running &&
        state.collectionSession!.deviceId == deviceId) {
      _appendCollectionRecord(record);
    }
  }

  void startCollection({String? fileName, String delimiter = ';'}) {
    final selectedDeviceId = state.selectedDeviceId;
    if (selectedDeviceId == null) {
      addLog(
        'Selecione um dispositivo antes de iniciar a coleta.',
        level: AppLogLevel.warning,
      );
      return;
    }

    if (state.collectionSession != null &&
        state.collectionSession!.stage == CollectionStage.running) {
      addLog('Ja existe uma coleta ativa.', level: AppLogLevel.warning);
      return;
    }

    if (!state.bleConnected) {
      addLog(
        'Conecte via Bluetooth para iniciar a coleta.',
        level: AppLogLevel.warning,
      );
      return;
    }

    if (!(state.devices[selectedDeviceId]?.device.isOnline ?? false)) {
      addLog(
        'O dispositivo selecionado esta offline.',
        level: AppLogLevel.warning,
      );
      return;
    }

    final normalizedName = _csvService.suggestFileName(
      selectedDeviceId,
      label: sanitizeFileName(fileName ?? 'ensaio_01', fallback: 'ensaio_01'),
    );

    final session = CollectionSession.initial(
      sessionId: _uuid.v4(),
      deviceId: selectedDeviceId,
      fileName: normalizedName,
      delimiter: delimiter,
      startedAt: DateTime.now(),
    );
    state = state.copyWith(collectionSession: session);
    addLog(
      'Coleta iniciada para $selectedDeviceId.',
      level: AppLogLevel.success,
    );
  }

  void pauseCollection() {
    final session = state.collectionSession;
    if (session == null || session.stage != CollectionStage.running) return;

    state = state.copyWith(
      collectionSession: session.copyWith(
        stage: CollectionStage.paused,
        pausedAt: DateTime.now(),
      ),
    );
    addLog('Coleta pausada.', level: AppLogLevel.info);
  }

  void resumeCollection() {
    final session = state.collectionSession;
    if (session == null || session.stage != CollectionStage.paused) return;

    state = state.copyWith(
      collectionSession: session.copyWith(
        stage: CollectionStage.running,
        pausedAt: null,
      ),
    );
    addLog('Coleta retomada.', level: AppLogLevel.info);
  }

  void finishCollection() {
    final session = state.collectionSession;
    if (session == null) return;

    state = state.copyWith(
      collectionSession: session.copyWith(stage: CollectionStage.finished),
    );
    addLog('Coleta finalizada.', level: AppLogLevel.success);
  }

  void cancelCollection() {
    final session = state.collectionSession;
    if (session == null) return;

    state = state.copyWith(
      collectionSession: session.copyWith(stage: CollectionStage.cancelled),
    );
    addLog('Coleta cancelada.', level: AppLogLevel.warning);
  }

  String buildSelectedDeviceCsv({String delimiter = ';'}) {
    final selectedDeviceId = state.selectedDeviceId;
    if (selectedDeviceId == null) return SensorRecord.csvHeader;
    return _csvService.buildCsv(
      state.recordsFor(selectedDeviceId),
      delimiter: delimiter,
    );
  }

  String suggestCollectionFileName() {
    final selectedDeviceId = state.selectedDeviceId ?? 'dispositivo';
    return _csvService.suggestFileName(selectedDeviceId);
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
      addLog('Bluetooth desconectado: comando nao enviado.', level: AppLogLevel.warning);
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

  void setOperationMode(bool appMode) => _sendCommand({
    'action': 'set_operation_mode',
    'value': appMode ? 1 : 0,
  });

  void startExperiment(int repetitions) => _sendCommand({
    'action': 'start_experiment',
    'repetitions': repetitions,
  });

  void stopExperiment() => _sendCommand({'action': 'stop_experiment'});
  void cancelExperiment() => _sendCommand({'action': 'cancel_experiment'});
  void finishRepetition() => _sendCommand({'action': 'finish_repetition'});
  void reconnectDevice() => _sendCommand({'action': 'reconnect'});

  /// Troca o nome anunciado no BLE (persistido no equipamento) — o mesmo
  /// efeito do "Renomear" na tela física "Conexao com app".
  void setDeviceName(String nome) =>
      _sendCommand({'action': 'set_device_name', 'nome': nome});

  void setChannelMode(int canal, ChannelEdgeMode modo) => _sendCommand({
    'action': 'set_channel_mode',
    'channel': canal,
    'mode': modo.value,
  });

  void setAllChannelsMode(ChannelEdgeMode modo) => _sendCommand({
    'action': 'set_all_channels_mode',
    'mode': modo.value,
  });

  void restoreChannelDefaults() =>
      _sendCommand({'action': 'restore_channel_defaults'});

  /// Pede a config. de canais atual sob demanda — chamado ao abrir uma tela
  /// que exibe esse estado, para nunca mostrar um valor obsoleto (de antes
  /// da conexão, ou de uma mudança feita pelo encoder local enquanto o app
  /// estava em outra tela/desconectado).
  void getChannels() => _sendCommand({'action': 'get_channels'});

  void listFiles() => _sendCommand({'action': 'list_files'});

  void renameFile(String from, String to) => _sendCommand({
    'action': 'rename_file',
    'from': from,
    'to': to,
  });

  void deleteFile(String nome) =>
      _sendCommand({'action': 'delete_file', 'nome': nome});

  void loadRepetition(String arquivo, int repeticao) => _sendCommand({
    'action': 'load_repetition',
    'arquivo': arquivo,
    'repeticao': repeticao,
  });

  /// Pede uma página (offset em linhas de dados) da tabela rolante de dados
  /// do arquivo. offset==0 começa uma nova consulta (a resposta substitui
  /// `fileDataRows`); offset>0 é rolagem/paginação (a resposta acrescenta).
  void readFileData(String arquivo, int offset) => _sendCommand({
    'action': 'read_file_data',
    'arquivo': arquivo,
    'offset': offset,
  });

  void _appendCollectionRecord(SensorRecord record) {
    final session = state.collectionSession;
    if (session == null) return;

    final updatedSession = session.copyWith(
      recordCount: session.recordCount + 1,
      sizeEstimateBytes:
          session.sizeEstimateBytes +
          record.toCsvRow(delimiter: session.delimiter).length +
          1,
      lastRecord: record,
    );
    state = state.copyWith(collectionSession: updatedSession);
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
    final updatedRecords = Map<String, List<SensorRecord>>.from(
      state.recordsByDevice,
    )..putIfAbsent(deviceId, () => <SensorRecord>[]);
    state = state.copyWith(
      devices: updatedDevices,
      recordsByDevice: updatedRecords,
    );
  }

  ChannelState _updateChannel(ChannelState? current, ParsedReading reading) {
    final previousState = current?.state;
    final changed = previousState != null && previousState != reading.state;
    return (current ?? ChannelState.empty(reading.sensor)).copyWith(
      state: reading.state,
      timestampMs: reading.timestampMs,
      receivedAt: DateTime.now(),
      messageCount: (current?.messageCount ?? 0) + 1,
      changeCount: (current?.changeCount ?? 0) + (changed ? 1 : 0),
    );
  }

  Map<String, List<SensorRecord>> _appendRecords(
    String deviceId,
    List<SensorRecord> records,
  ) {
    final updated = Map<String, List<SensorRecord>>.from(state.recordsByDevice);
    final current = List<SensorRecord>.from(
      updated[deviceId] ?? const <SensorRecord>[],
    );
    current.addAll(records);
    updated[deviceId] = current;
    return updated;
  }

  void _bumpInvalidCount(String deviceId) {
    final deviceState = state.devices[deviceId];
    if (deviceState == null) return;

    final updatedDevices = Map<String, Esp32DeviceState>.from(state.devices)
      ..[deviceId] = deviceState.copyWith(
        totalInvalidMessages: deviceState.totalInvalidMessages + 1,
      );
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
