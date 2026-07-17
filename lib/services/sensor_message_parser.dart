import '../models/sensor_state.dart';

class ParsedReading {
  final int sensor;
  final SensorState state;
  final int timestampMs;

  const ParsedReading({
    required this.sensor,
    required this.state,
    required this.timestampMs,
  });
}

enum RejectReason {
  missingDeviceId,
  missingState,
  missingTimestamp,
  sensorOutOfRange,
  invalidState,
  deviceIdTopicPayloadMismatch,
  malformed,
}

class ParseResult {
  final String? deviceId;
  final List<ParsedReading> readings;
  final RejectReason? rejectReason;

  const ParseResult.ok(this.deviceId, this.readings) : rejectReason = null;

  const ParseResult.rejected(this.rejectReason)
    : deviceId = null,
      readings = const [];

  bool get isAccepted => rejectReason == null;
}

class SensorMessageParser {
  ParseResult parse(
    Map<String, dynamic> payload, {
    required String topicDeviceId,
  }) {
    final payloadDeviceId = payload['deviceId'] as String?;
    if (payloadDeviceId == null) {
      return const ParseResult.rejected(RejectReason.missingDeviceId);
    }

    if (payloadDeviceId != topicDeviceId) {
      return const ParseResult.rejected(
        RejectReason.deviceIdTopicPayloadMismatch,
      );
    }

    final timestampMs = _asInt(payload['timestampMs']);
    if (timestampMs == null) {
      return const ParseResult.rejected(RejectReason.missingTimestamp);
    }

    if (payload['sensors'] is List) {
      final readings = <ParsedReading>[];
      for (final rawItem in payload['sensors'] as List) {
        if (rawItem is! Map) {
          return const ParseResult.rejected(RejectReason.malformed);
        }

        final reading = _parseSingle(
          sensorRaw: rawItem['sensor'] ?? rawItem['channel'],
          stateRaw: rawItem['state'],
          timestampMs: timestampMs,
        );
        if (reading == null) {
          return const ParseResult.rejected(RejectReason.invalidState);
        }
        readings.add(reading);
      }

      if (readings.isEmpty) {
        return const ParseResult.rejected(RejectReason.malformed);
      }

      return ParseResult.ok(topicDeviceId, readings);
    }

    final reading = _parseSingle(
      sensorRaw: payload['sensor'] ?? payload['channel'],
      stateRaw: payload['state'],
      timestampMs: timestampMs,
    );
    if (reading == null) {
      final sensorNum = _asInt(payload['sensor'] ?? payload['channel']);
      if (sensorNum == null || sensorNum < 1 || sensorNum > 6) {
        return const ParseResult.rejected(RejectReason.sensorOutOfRange);
      }
      if (payload['state'] == null) {
        return const ParseResult.rejected(RejectReason.missingState);
      }
      return const ParseResult.rejected(RejectReason.invalidState);
    }

    return ParseResult.ok(topicDeviceId, [reading]);
  }

  ParsedReading? _parseSingle({
    required Object? sensorRaw,
    required Object? stateRaw,
    required int timestampMs,
  }) {
    final sensor = _asInt(sensorRaw);
    if (sensor == null || sensor < 1 || sensor > 6) return null;

    final state = SensorState.tryParse(stateRaw);
    if (state == null) return null;

    return ParsedReading(
      sensor: sensor,
      state: state,
      timestampMs: timestampMs,
    );
  }

  int? _asInt(Object? raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is double) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }
}
