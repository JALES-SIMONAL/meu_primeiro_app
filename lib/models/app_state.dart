import 'app_log_entry.dart';
import 'collection_session.dart';
import 'esp32_device_state.dart';
import 'mqtt_settings.dart';
import 'sensor_record.dart';

class AppState {
  static const Object _unset = Object();

  final Map<String, Esp32DeviceState> devices;
  final String? selectedDeviceId;
  final MqttSettings mqttSettings;
  final bool mqttConnected;
  final bool demoMode;
  final CollectionSession? collectionSession;
  final Map<String, List<SensorRecord>> recordsByDevice;
  final List<AppLogEntry> logs;
  final String? statusMessage;

  const AppState({
    required this.devices,
    required this.selectedDeviceId,
    required this.mqttSettings,
    required this.mqttConnected,
    required this.demoMode,
    required this.collectionSession,
    required this.recordsByDevice,
    required this.logs,
    required this.statusMessage,
  });

  factory AppState.initial({required Map<String, Esp32DeviceState> devices}) {
    return AppState(
      devices: devices,
      selectedDeviceId: devices.isEmpty ? null : devices.keys.first,
      mqttSettings: MqttSettings.defaults(),
      mqttConnected: false,
      demoMode: false,
      collectionSession: null,
      recordsByDevice: {
        for (final deviceId in devices.keys) deviceId: <SensorRecord>[],
      },
      logs: const [],
      statusMessage: null,
    );
  }

  Esp32DeviceState? get selectedDevice =>
      selectedDeviceId == null ? null : devices[selectedDeviceId];

  List<SensorRecord> recordsFor(String deviceId) =>
      recordsByDevice[deviceId] ?? const <SensorRecord>[];

  AppState copyWith({
    Map<String, Esp32DeviceState>? devices,
    Object? selectedDeviceId = _unset,
    MqttSettings? mqttSettings,
    bool? mqttConnected,
    bool? demoMode,
    Object? collectionSession = _unset,
    Map<String, List<SensorRecord>>? recordsByDevice,
    List<AppLogEntry>? logs,
    Object? statusMessage = _unset,
  }) {
    return AppState(
      devices: devices ?? this.devices,
      selectedDeviceId: selectedDeviceId == _unset
          ? this.selectedDeviceId
          : selectedDeviceId as String?,
      mqttSettings: mqttSettings ?? this.mqttSettings,
      mqttConnected: mqttConnected ?? this.mqttConnected,
      demoMode: demoMode ?? this.demoMode,
      collectionSession: collectionSession == _unset
          ? this.collectionSession
          : collectionSession as CollectionSession?,
      recordsByDevice: recordsByDevice ?? this.recordsByDevice,
      logs: logs ?? this.logs,
      statusMessage: statusMessage == _unset
          ? this.statusMessage
          : statusMessage as String?,
    );
  }
}
