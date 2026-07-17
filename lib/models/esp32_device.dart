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
    );
  }
}
