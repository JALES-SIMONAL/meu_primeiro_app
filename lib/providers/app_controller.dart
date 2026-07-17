import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/app_log_entry.dart';
import '../models/app_state.dart';
import '../models/boot_session_service.dart';
import '../models/collection_session.dart';
import '../models/esp32_device.dart';
import '../models/esp32_device_state.dart';
import '../models/mqtt_settings.dart';
import '../models/mqtt_topics.dart';
import '../models/sensor_record.dart';
import '../models/sensor_state.dart';
import '../services/csv_service.dart';
import '../services/demo_service.dart';
import '../services/mqtt_service.dart';
import '../services/sensor_message_parser.dart';
import '../core/utils/formatters.dart';

final appControllerProvider = NotifierProvider<AppController, AppState>(
  AppController.new,
);

class AppController extends Notifier<AppState> {
  AppController({
    DemoService? demoService,
    MqttService? mqttService,
    CsvService? csvService,
    SensorMessageParser? parser,
    BootSessionService? bootSessionService,
  }) : _demoService = demoService ?? DemoService(),
       _mqttService = mqttService ?? MqttClientService(),
       _csvService = csvService ?? CsvService(),
       _parser = parser ?? SensorMessageParser(),
       _bootSessionService = bootSessionService ?? BootSessionService();

  final DemoService _demoService;
  final MqttService _mqttService;
  final CsvService _csvService;
  final SensorMessageParser _parser;
  final BootSessionService _bootSessionService;
  final Uuid _uuid = const Uuid();

  Timer? _demoTimer;
  StreamSubscription<MqttConnectionStateUi>? _mqttConnectionSubscription;
  StreamSubscription<MqttIncomingMessage>? _mqttMessageSubscription;
  final Map<String, int> _demoTimestampByDevice = {};

  @override
  AppState build() {
    _mqttConnectionSubscription ??=
        _mqttService.connectionStateChanges.listen(_handleConnectionStateChange);
    _mqttMessageSubscription ??=
        _mqttService.messages.listen(_handleIncomingMqttMessage);
    ref.onDispose(shutdown);
    return AppState.initial(devices: _buildInitialDevices());
  }

  void shutdown() {
    _demoTimer?.cancel();
    _mqttConnectionSubscription?.cancel();
    _mqttMessageSubscription?.cancel();
    _mqttService.disconnect();
  }

  static Map<String, Esp32DeviceState> _buildInitialDevices() {
    final demoDevices = DemoService(seed: 42).createDemoDevices();
    return {
      for (final device in demoDevices)
        device.deviceId: Esp32DeviceState.initial(
          device.copyWith(isOnline: false),
        ),
    };
  }

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

  void updateMqttSettings(MqttSettings settings) {
    state = state.copyWith(mqttSettings: settings);
  }

  Future<void> connectMqtt() async {
    final settings = state.mqttSettings;
    if (settings.broker.trim().isEmpty) {
      addLog('Broker MQTT nao configurado.', level: AppLogLevel.warning);
      return;
    }

    try {
      await _mqttService.connect(settings);
      state = state.copyWith(mqttConnected: true);
      addLog(
        'MQTT conectado em ${settings.broker}:${settings.port}.',
        level: AppLogLevel.success,
      );
      _mqttService.subscribeTopic(MqttTopics.discoveryStatusWildcard);
      _mqttService.subscribeTopic(MqttTopics.discoveryInfoWildcard);
    } catch (error) {
      state = state.copyWith(mqttConnected: false);
      addLog('Falha ao conectar MQTT: $error', level: AppLogLevel.error);
    }
  }

  Future<void> disconnectMqtt() async {
    await _mqttService.disconnect();
    state = state.copyWith(mqttConnected: false);
    addLog('MQTT desconectado.', level: AppLogLevel.info);
  }

  void toggleDemoMode(bool enabled) {
    if (enabled == state.demoMode) return;

    state = state.copyWith(demoMode: enabled);
    if (enabled) {
      addLog('Modo demonstracao ativado.', level: AppLogLevel.success);
      _seedDemoDevices();
      _startDemoTimer();
    } else {
      _demoTimer?.cancel();
      _demoTimer = null;
      addLog('Modo demonstracao desativado.', level: AppLogLevel.info);
    }
  }

  void _seedDemoDevices() {
    final updatedDevices = Map<String, Esp32DeviceState>.from(state.devices);
    for (final device in updatedDevices.values) {
      if (!device.device.deviceId.startsWith('esp32_demo_')) continue;
      updatedDevices[device.device.deviceId] = device.copyWith(
        device: device.device.copyWith(
          isOnline: true,
          lastSeen: DateTime.now(),
          firmwareVersion: device.device.firmwareVersion ?? '1.0.0-demo',
        ),
      );
    }
    state = state.copyWith(devices: updatedDevices);
  }

  void _startDemoTimer() {
    _demoTimer?.cancel();
    _demoTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _emitDemoSnapshot(),
    );
  }

  void simulateDeviceReboot(String deviceId) {
    final deviceState = state.devices[deviceId];
    if (deviceState == null) return;

    _demoTimestampByDevice[deviceId] = 0;
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

  void processIncomingPayload(String topic, Map<String, dynamic> payload) {
    final topicDeviceId =
        MqttTopics.deviceIdFromTopic(topic) ?? payload['deviceId']?.toString();
    if (topicDeviceId == null || topicDeviceId.isEmpty) {
      addLog(
        'Mensagem rejeitada: deviceId ausente.',
        level: AppLogLevel.warning,
      );
      return;
    }

    _ensureDevice(topicDeviceId);

    final parseResult = _parser.parse(payload, topicDeviceId: topicDeviceId);
    if (!parseResult.isAccepted) {
      addLog(
        'Mensagem rejeitada para $topicDeviceId: ${parseResult.rejectReason}',
        level: AppLogLevel.warning,
      );
      _bumpInvalidCount(topicDeviceId);
      return;
    }

    final uptimeMs = _asInt(payload['uptimeMs']);
    final statusPayload = payload['online'] ?? payload['isOnline'];
    final online = statusPayload is bool ? statusPayload : true;
    final name = payload['name']?.toString();
    final macAddress = payload['macAddress']?.toString();
    final firmwareVersion = payload['firmwareVersion']?.toString();
    final channelCount = _asInt(payload['channelCount']);

    final records = <SensorRecord>[];
    final currentDeviceState = state.devices[topicDeviceId]!;
    var workingDeviceState = _applyDeviceMetadata(
      currentDeviceState,
      online: online,
      lastSeen: DateTime.now(),
      uptimeMs: uptimeMs,
      name: name,
      macAddress: macAddress,
      firmwareVersion: firmwareVersion,
      channelCount: channelCount,
    );

    final timestampEvent = _bootSessionService.classify(
      lastTimestampMs: currentDeviceState.lastTimestampMs,
      newTimestampMs: parseResult.readings.first.timestampMs,
      lastUptimeMs: currentDeviceState.lastUptimeMs,
      newUptimeMs: uptimeMs,
    );

    if (timestampEvent == TimestampEvent.reboot) {
      workingDeviceState = workingDeviceState.copyWith(
        device: workingDeviceState.device.copyWith(
          bootSession: workingDeviceState.device.bootSession + 1,
          uptimeMs: uptimeMs,
        ),
        rebootCount: workingDeviceState.rebootCount + 1,
      );
      addLog(
        'Reinicio detectado em $topicDeviceId.',
        level: AppLogLevel.warning,
      );
    } else if (timestampEvent == TimestampEvent.millisOverflow) {
      addLog(
        'Possivel overflow de millis em $topicDeviceId.',
        level: AppLogLevel.info,
      );
    } else if (timestampEvent == TimestampEvent.outOfOrder) {
      addLog(
        'Mensagem fora de ordem recebida de $topicDeviceId.',
        level: AppLogLevel.info,
      );
    }

    for (final reading in parseResult.readings) {
      final nextChannelState = _updateChannel(
        workingDeviceState.channels[reading.sensor],
        reading,
      );
      final updatedChannels = Map<int, ChannelState>.from(
        workingDeviceState.channels,
      )..[reading.sensor] = nextChannelState;

      final record = SensorRecord(
        deviceId: topicDeviceId,
        sensor: reading.sensor,
        state: reading.state,
        timestampMs: reading.timestampMs,
        receivedAt: DateTime.now(),
        bootSession: workingDeviceState.device.bootSession,
      );
      records.add(record);

      workingDeviceState = workingDeviceState.copyWith(
        channels: updatedChannels,
        totalMessages: workingDeviceState.totalMessages + 1,
        lastTimestampMs: reading.timestampMs,
        lastUptimeMs: uptimeMs,
      );

      if (state.collectionSession != null &&
          state.collectionSession!.stage == CollectionStage.running &&
          state.collectionSession!.deviceId == topicDeviceId) {
        _appendCollectionRecord(record);
      }
    }

    final updatedDevices = Map<String, Esp32DeviceState>.from(state.devices)
      ..[topicDeviceId] = workingDeviceState;

    final updatedRecords = _appendRecords(topicDeviceId, records);
    state = state.copyWith(
      devices: updatedDevices,
      recordsByDevice: updatedRecords,
    );
  }

  void _handleConnectionStateChange(MqttConnectionStateUi connectionState) {
    switch (connectionState) {
      case MqttConnectionStateUi.connected:
        state = state.copyWith(mqttConnected: true);
        break;
      case MqttConnectionStateUi.disconnected:
        state = state.copyWith(mqttConnected: false);
        break;
      case MqttConnectionStateUi.connecting:
      case MqttConnectionStateUi.reconnecting:
      case MqttConnectionStateUi.error:
        break;
    }
  }

  void _handleIncomingMqttMessage(MqttIncomingMessage message) {
    if (message.payload.length > 64 * 1024) {
      addLog(
        'Mensagem MQTT muito grande descartada.',
        level: AppLogLevel.warning,
      );
      return;
    }

    try {
      final decoded = jsonDecode(message.payload);
      if (decoded is Map<String, dynamic>) {
        processIncomingPayload(message.topic, decoded);
      } else if (decoded is Map) {
        processIncomingPayload(
          message.topic,
          Map<String, dynamic>.from(decoded.cast<String, dynamic>()),
        );
      } else {
        addLog('Payload MQTT invalido recebido.', level: AppLogLevel.warning);
      }
    } catch (error) {
      addLog('JSON invalido recebido: $error', level: AppLogLevel.warning);
    }
  }

  void _emitDemoSnapshot() {
    if (!state.demoMode) return;

    final demoDevices = state.devices.values.where(
      (deviceState) => deviceState.device.deviceId.startsWith('esp32_demo_'),
    );
    for (final deviceState in demoDevices) {
      final deviceId = deviceState.device.deviceId;
      final currentTimestamp = _demoTimestampByDevice[deviceId] ?? 0;
      final nextTimestamp = _demoService.nextTimestamp(currentTimestamp);
      _demoTimestampByDevice[deviceId] = nextTimestamp;

      final sensors = <Map<String, dynamic>>[];
      for (var sensor = 1; sensor <= 6; sensor++) {
        final currentState =
            deviceState.channels[sensor]?.state ?? SensorState.low;
        final nextState = _demoService.nextState(currentState);
        sensors.add({'sensor': sensor, 'state': nextState.shortCode});
      }

      processIncomingPayload(MqttTopics.data(deviceId), {
        'deviceId': deviceId,
        'timestampMs': nextTimestamp,
        'uptimeMs': nextTimestamp,
        'sensors': sensors,
        'online': true,
      });
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

    if (!state.mqttConnected && !state.demoMode) {
      addLog(
        'Conecte no MQTT ou ative o modo demonstracao.',
        level: AppLogLevel.warning,
      );
      return;
    }

    if (!(state.devices[selectedDeviceId]?.device.isOnline ?? false) &&
        !state.demoMode) {
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

  void _ensureDevice(String deviceId) {
    if (state.devices.containsKey(deviceId)) return;

    final device = Esp32Device(
      deviceId: deviceId,
      name: deviceId,
      channelCount: 6,
      isOnline: true,
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

  Esp32DeviceState _applyDeviceMetadata(
    Esp32DeviceState deviceState, {
    required bool online,
    required DateTime lastSeen,
    int? uptimeMs,
    String? name,
    String? macAddress,
    String? firmwareVersion,
    int? channelCount,
  }) {
    var device = deviceState.device.copyWith(
      isOnline: online,
      lastSeen: lastSeen,
      uptimeMs: uptimeMs ?? deviceState.device.uptimeMs,
      name: name ?? deviceState.device.name,
      macAddress: macAddress ?? deviceState.device.macAddress,
      firmwareVersion: firmwareVersion ?? deviceState.device.firmwareVersion,
      channelCount: channelCount ?? deviceState.device.channelCount,
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

    return deviceState.copyWith(device: device, channels: channels);
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
