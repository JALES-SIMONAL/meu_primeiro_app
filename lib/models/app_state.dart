import 'analysis_event.dart';
import 'app_log_entry.dart';
import 'channel_edge_mode.dart';
import 'channel_live_state.dart';
import 'circular_analysis_result.dart';
import 'device_file.dart';
import 'esp32_device_state.dart';
import 'file_data_row.dart';
import '../services/bluetooth_service.dart';

class AppState {
  static const Object _unset = Object();

  final Map<String, Esp32DeviceState> devices;
  final String? selectedDeviceId;
  final bool bleConnected;
  final bool bleScanning;
  final List<BleDeviceInfo> bleScanResults;
  final List<AppLogEntry> logs;
  final String? statusMessage;

  // Dados do menu do equipamento (só fazem sentido para o dispositivo BLE
  // atualmente conectado — não há mais de uma conexão ativa por vez).
  final List<ChannelConfig> channelConfigs;
  final List<DeviceFile> deviceFiles;
  final List<ChannelLiveState> channelLiveStates;
  final List<AnalysisEvent> loadedAnalysisEvents;

  // Eventos da repeticao em andamento, chegando ao vivo via BLE ("topico":
  // "event", bluetooth_app.cpp::publicarEvento) enquanto o experimento
  // esta ativo — distinto de loadedAnalysisEvents, que carrega uma
  // repeticao ja salva sob demanda ("load_repetition"). Zerado a cada novo
  // experimento/repeticao (ver AppController).
  final List<AnalysisEvent> liveExperimentEvents;
  final List<FileDataRow> fileDataRows;
  final bool fileDataHasMore;

  // Análise de movimento circular (Raio/Vãos) — replica local de
  // analise_circular.cpp (o firmware não expõe esse cálculo por BLE, só os
  // eventos brutos por repetição). "circularPerRepetitionResults" guarda um
  // item por repetição do arquivo (null = repetição com menos de 2 eventos),
  // reaproveitado tanto para a tela "Resultado" quanto para montar a curva de
  // um gráfico sem precisar buscar tudo de novo por BLE.
  final bool circularAnalysisLoading;
  final int circularRaioMm;
  final int circularVaosQtd;
  final CircularAverageResult? circularAverageResult;
  final List<CircularCalcResult?> circularPerRepetitionResults;
  final List<CircularPoint> circularGraphPoints;
  final String? circularGraphTitle;

  const AppState({
    required this.devices,
    required this.selectedDeviceId,
    required this.bleConnected,
    required this.bleScanning,
    required this.bleScanResults,
    required this.logs,
    required this.statusMessage,
    required this.channelConfigs,
    required this.deviceFiles,
    required this.channelLiveStates,
    required this.loadedAnalysisEvents,
    this.liveExperimentEvents = const [],
    required this.fileDataRows,
    required this.fileDataHasMore,
    this.circularAnalysisLoading = false,
    this.circularRaioMm = 10,
    this.circularVaosQtd = 20,
    this.circularAverageResult,
    this.circularPerRepetitionResults = const [],
    this.circularGraphPoints = const [],
    this.circularGraphTitle,
  });

  factory AppState.initial({required Map<String, Esp32DeviceState> devices}) {
    return AppState(
      devices: devices,
      selectedDeviceId: devices.isEmpty ? null : devices.keys.first,
      bleConnected: false,
      bleScanning: false,
      bleScanResults: const [],
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

  AppState copyWith({
    Map<String, Esp32DeviceState>? devices,
    Object? selectedDeviceId = _unset,
    bool? bleConnected,
    bool? bleScanning,
    List<BleDeviceInfo>? bleScanResults,
    List<AppLogEntry>? logs,
    Object? statusMessage = _unset,
    List<ChannelConfig>? channelConfigs,
    List<DeviceFile>? deviceFiles,
    List<ChannelLiveState>? channelLiveStates,
    List<AnalysisEvent>? loadedAnalysisEvents,
    List<AnalysisEvent>? liveExperimentEvents,
    List<FileDataRow>? fileDataRows,
    bool? fileDataHasMore,
    bool? circularAnalysisLoading,
    int? circularRaioMm,
    int? circularVaosQtd,
    Object? circularAverageResult = _unset,
    List<CircularCalcResult?>? circularPerRepetitionResults,
    List<CircularPoint>? circularGraphPoints,
    Object? circularGraphTitle = _unset,
  }) {
    return AppState(
      devices: devices ?? this.devices,
      selectedDeviceId: selectedDeviceId == _unset
          ? this.selectedDeviceId
          : selectedDeviceId as String?,
      bleConnected: bleConnected ?? this.bleConnected,
      bleScanning: bleScanning ?? this.bleScanning,
      bleScanResults: bleScanResults ?? this.bleScanResults,
      logs: logs ?? this.logs,
      statusMessage: statusMessage == _unset
          ? this.statusMessage
          : statusMessage as String?,
      channelConfigs: channelConfigs ?? this.channelConfigs,
      deviceFiles: deviceFiles ?? this.deviceFiles,
      channelLiveStates: channelLiveStates ?? this.channelLiveStates,
      loadedAnalysisEvents: loadedAnalysisEvents ?? this.loadedAnalysisEvents,
      liveExperimentEvents:
          liveExperimentEvents ?? this.liveExperimentEvents,
      fileDataRows: fileDataRows ?? this.fileDataRows,
      fileDataHasMore: fileDataHasMore ?? this.fileDataHasMore,
      circularAnalysisLoading:
          circularAnalysisLoading ?? this.circularAnalysisLoading,
      circularRaioMm: circularRaioMm ?? this.circularRaioMm,
      circularVaosQtd: circularVaosQtd ?? this.circularVaosQtd,
      circularAverageResult: circularAverageResult == _unset
          ? this.circularAverageResult
          : circularAverageResult as CircularAverageResult?,
      circularPerRepetitionResults:
          circularPerRepetitionResults ?? this.circularPerRepetitionResults,
      circularGraphPoints: circularGraphPoints ?? this.circularGraphPoints,
      circularGraphTitle: circularGraphTitle == _unset
          ? this.circularGraphTitle
          : circularGraphTitle as String?,
    );
  }
}
