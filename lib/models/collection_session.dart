import 'sensor_record.dart';

enum CollectionStage { idle, running, paused, finished, cancelled }

class CollectionSession {
  final String sessionId;
  final String deviceId;
  final String fileName;
  final String delimiter;
  final DateTime startedAt;
  final DateTime? pausedAt;
  final CollectionStage stage;
  final int recordCount;
  final int sizeEstimateBytes;
  final SensorRecord? lastRecord;

  const CollectionSession({
    required this.sessionId,
    required this.deviceId,
    required this.fileName,
    required this.delimiter,
    required this.startedAt,
    required this.pausedAt,
    required this.stage,
    required this.recordCount,
    required this.sizeEstimateBytes,
    required this.lastRecord,
  });

  factory CollectionSession.initial({
    required String sessionId,
    required String deviceId,
    required String fileName,
    required String delimiter,
    required DateTime startedAt,
  }) {
    return CollectionSession(
      sessionId: sessionId,
      deviceId: deviceId,
      fileName: fileName,
      delimiter: delimiter,
      startedAt: startedAt,
      pausedAt: null,
      stage: CollectionStage.running,
      recordCount: 0,
      sizeEstimateBytes: 0,
      lastRecord: null,
    );
  }

  CollectionSession copyWith({
    String? deviceId,
    String? fileName,
    String? delimiter,
    DateTime? startedAt,
    DateTime? pausedAt,
    CollectionStage? stage,
    int? recordCount,
    int? sizeEstimateBytes,
    SensorRecord? lastRecord,
  }) {
    return CollectionSession(
      sessionId: sessionId,
      deviceId: deviceId ?? this.deviceId,
      fileName: fileName ?? this.fileName,
      delimiter: delimiter ?? this.delimiter,
      startedAt: startedAt ?? this.startedAt,
      pausedAt: pausedAt ?? this.pausedAt,
      stage: stage ?? this.stage,
      recordCount: recordCount ?? this.recordCount,
      sizeEstimateBytes: sizeEstimateBytes ?? this.sizeEstimateBytes,
      lastRecord: lastRecord ?? this.lastRecord,
    );
  }
}
