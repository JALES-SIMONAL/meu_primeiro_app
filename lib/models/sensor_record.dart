import '../core/utils/formatters.dart';
import 'sensor_state.dart';

class SensorRecord {
  final String deviceId;
  final int sensor;
  final SensorState state;
  final int timestampMs;
  final DateTime receivedAt;
  final int bootSession;

  const SensorRecord({
    required this.deviceId,
    required this.sensor,
    required this.state,
    required this.timestampMs,
    required this.receivedAt,
    required this.bootSession,
  });

  String get trackingKey => '$deviceId|$bootSession|$sensor|$timestampMs';

  String get elapsedTimeFormatted => formatElapsedTime(timestampMs);

  String get elapsedTimeSecondsFormatted => formatElapsedSeconds(timestampMs);

  String get elapsedTimeMsFormatted => '$timestampMs ms';

  String toCsvRow({String delimiter = ';'}) {
    final receivedAtFormatted = formatReceivedAt(receivedAt);
    final fields = <String>[
      deviceId,
      sensor.toString(),
      state.shortCode,
      state.description,
      timestampMs.toString(),
      elapsedTimeFormatted,
      receivedAtFormatted,
      bootSession.toString(),
    ];

    return fields
        .map((field) => _escapeCsvField(field, delimiter))
        .join(delimiter);
  }

  static const String csvHeader =
      'device_id;sensor;state;state_description;timestamp_ms;elapsed_time;received_at;boot_session';

  SensorRecord copyWith({
    String? deviceId,
    int? sensor,
    SensorState? state,
    int? timestampMs,
    DateTime? receivedAt,
    int? bootSession,
  }) {
    return SensorRecord(
      deviceId: deviceId ?? this.deviceId,
      sensor: sensor ?? this.sensor,
      state: state ?? this.state,
      timestampMs: timestampMs ?? this.timestampMs,
      receivedAt: receivedAt ?? this.receivedAt,
      bootSession: bootSession ?? this.bootSession,
    );
  }

  static String _escapeCsvField(String value, String delimiter) {
    final needsQuotes =
        value.contains(delimiter) ||
        value.contains(';') ||
        value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');
    if (!needsQuotes) return value;
    return '"${value.replaceAll('"', '""')}"';
  }
}
