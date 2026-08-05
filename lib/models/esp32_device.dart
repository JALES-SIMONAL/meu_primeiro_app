/// Modo de operação reportado pelo firmware (configuracoes::ModoOperacao).
enum DeviceOperationMode { hardware, app }

class Esp32Device {
  final String deviceId;
  final String? name;
  final String? macAddress;
  final String? firmwareVersion;
  final int channelCount;
  final bool isOnline;
  final DateTime? lastSeen;
  final int? uptimeMs;
  final int bootSession;

  // Telemetria vinda do "topico":"state" do firmware (bluetooth_app.cpp::publicarEstado).
  final DeviceOperationMode? operationMode;
  final int? brightness;
  final int? volume;
  final bool? sdCardAvailable;
  final int? sdErrorCount;
  final bool? experimentActive;
  final int? repetitionCurrent;
  final int? repetitionsTotal;
  final int? experimentElapsedSeconds;
  final int? sdUsedKb;
  final int? sdTotalKb;

  // Dados estáticos vindos do "topico":"info" (bluetooth_app.cpp::publicarInfoDispositivo),
  // enviados uma única vez logo após conectar.
  final String? author;
  final String? manualUrl;

  const Esp32Device({
    required this.deviceId,
    this.name,
    this.macAddress,
    this.firmwareVersion,
    this.channelCount = 6,
    this.isOnline = false,
    this.lastSeen,
    this.uptimeMs,
    this.bootSession = 1,
    this.operationMode,
    this.brightness,
    this.volume,
    this.sdCardAvailable,
    this.sdErrorCount,
    this.experimentActive,
    this.repetitionCurrent,
    this.repetitionsTotal,
    this.experimentElapsedSeconds,
    this.sdUsedKb,
    this.sdTotalKb,
    this.author,
    this.manualUrl,
  });

  String get displayName {
    final value = name?.trim();
    return (value != null && value.isNotEmpty) ? value : deviceId;
  }

  Esp32Device copyWith({
    String? name,
    String? macAddress,
    String? firmwareVersion,
    int? channelCount,
    bool? isOnline,
    DateTime? lastSeen,
    int? uptimeMs,
    int? bootSession,
    DeviceOperationMode? operationMode,
    int? brightness,
    int? volume,
    bool? sdCardAvailable,
    int? sdErrorCount,
    bool? experimentActive,
    int? repetitionCurrent,
    int? repetitionsTotal,
    int? experimentElapsedSeconds,
    int? sdUsedKb,
    int? sdTotalKb,
    String? author,
    String? manualUrl,
  }) {
    return Esp32Device(
      deviceId: deviceId,
      name: name ?? this.name,
      macAddress: macAddress ?? this.macAddress,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      channelCount: channelCount ?? this.channelCount,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      uptimeMs: uptimeMs ?? this.uptimeMs,
      bootSession: bootSession ?? this.bootSession,
      operationMode: operationMode ?? this.operationMode,
      brightness: brightness ?? this.brightness,
      volume: volume ?? this.volume,
      sdCardAvailable: sdCardAvailable ?? this.sdCardAvailable,
      sdErrorCount: sdErrorCount ?? this.sdErrorCount,
      experimentActive: experimentActive ?? this.experimentActive,
      repetitionCurrent: repetitionCurrent ?? this.repetitionCurrent,
      repetitionsTotal: repetitionsTotal ?? this.repetitionsTotal,
      experimentElapsedSeconds:
          experimentElapsedSeconds ?? this.experimentElapsedSeconds,
      sdUsedKb: sdUsedKb ?? this.sdUsedKb,
      sdTotalKb: sdTotalKb ?? this.sdTotalKb,
      author: author ?? this.author,
      manualUrl: manualUrl ?? this.manualUrl,
    );
  }
}
