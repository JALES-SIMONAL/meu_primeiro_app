import 'analysis_event.dart';
import 'app_log_entry.dart';
import 'channel_edge_mode.dart';
import 'channel_live_state.dart';
import 'collection_session.dart';
import 'device_file.dart';
import 'esp32_device_state.dart';
import 'file_data_row.dart';
import 'sensor_record.dart';
import '../services/bluetooth_service.dart';

class AppState {
  static const Object _unset = Object();

  final Map<String, Esp32DeviceState> devices;
  final String? selectedDeviceId;
  final bool bleConnected;
  final bool bleScanning;
  final List<BleDeviceInfo> bleScanResults;
  final CollectionSession? collectionSession;
  final Map<String, List<SensorRecord>> recordsByDevice;
  final List<AppLogEntry> logs;
  final String? statusMessage;

  // Dados do menu do equipamento (só fazem sentido para o dispositivo BLE
  // atualmente conectado — não há mais de uma conexão ativa por vez).
  final List<ChannelConfig> channelConfigs;
  final List<DeviceFile> deviceFiles;
  final List<ChannelLiveState> channelLiveStates;
  final List<AnalysisEvent> loadedAnalysisEvents;
  final List<FileDataRow> fileDataRows;
  final bool fileDataHasMore;

  const AppState({
    required this.devices,
    required this.selectedDeviceId,
    required this.bleConnected,
    required this.bleScanning,
    required this.bleScanResults,
    required this.collectionSession,
    required this.recordsByDevice,
    required this.logs,
    required this.statusMessage,
    required this.channelConfigs,
    required this.deviceFiles,
    required this.channelLiveStates,
    required this.loadedAnalysisEvents,
    required this.fileDataRows,
    required this.fileDataHasMore,
  });

  factory AppState.initial({required Map<String, Esp32DeviceState> devices}) {
    return AppState(
      devices: devices,
      selectedDeviceId: devices.isEmpty ? null : devices.keys.first,
      bleConnected: false,
      bleScanning: false,
      bleScanResults: const [],
      collectionSession: null,
      recordsByDevice: {
        for (final deviceId in devices.keys) deviceId: <SensorRecord>[],
      },
      logs: const [],
      statusMessage: null,
      channelConfigs: const [],
      deviceFiles: const [],
      channelLiveStates: const [],
      loadedAnalysisEvents: const [],
      fileDataRows: const [],
      fileDataHasMore: false,
    );
  }

  Esp32DeviceState? get selectedDevice =>
      selectedDeviceId == null ? null : devices[selectedDeviceId];

  List<SensorRecord> recordsFor(String deviceId) =>
      recordsByDevice[deviceId] ?? const <SensorRecord>[];

  AppState copyWith({
    Map<String, Esp32DeviceState>? devices,
    Object? selectedDeviceId = _unset,
    bool? bleConnected,
    bool? bleScanning,
    List<BleDeviceInfo>? bleScanResults,
    Object? collectionSession = _unset,
    Map<String, List<SensorRecord>>? recordsByDevice,
    List<AppLogEntry>? logs,
    Object? statusMessage = _unset,
    List<ChannelConfig>? channelConfigs,
    List<DeviceFile>? deviceFiles,
    List<ChannelLiveState>? channelLiveStates,
    List<AnalysisEvent>? loadedAnalysisEvents,
    List<FileDataRow>? fileDataRows,
    bool? fileDataHasMore,
  }) {
    return AppState(
      devices: devices ?? this.devices,
      selectedDeviceId: selectedDeviceId == _unset
          ? this.selectedDeviceId
          : selectedDeviceId as String?,
      bleConnected: bleConnected ?? this.bleConnected,
      bleScanning: bleScanning ?? this.bleScanning,
      bleScanResults: bleScanResults ?? this.bleScanResults,
      collectionSession: collectionSession == _unset
          ? this.collectionSession
          : collectionSession as CollectionSession?,
      recordsByDevice: recordsByDevice ?? this.recordsByDevice,
      logs: logs ?? this.logs,
      statusMessage: statusMessage == _unset
          ? this.statusMessage
          : statusMessage as String?,
      channelConfigs: channelConfigs ?? this.channelConfigs,
      deviceFiles: deviceFiles ?? this.deviceFiles,
      channelLiveStates: channelLiveStates ?? this.channelLiveStates,
      loadedAnalysisEvents: loadedAnalysisEvents ?? this.loadedAnalysisEvents,
      fileDataRows: fileDataRows ?? this.fileDataRows,
      fileDataHasMore: fileDataHasMore ?? this.fileDataHasMore,
    );
  }
}
