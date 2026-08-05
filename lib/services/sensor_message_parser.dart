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

enum RejectReason { missingState, sensorOutOfRange, invalidState, malformed }

class ParseResult {
  final ParsedReading? reading;
  final RejectReason? rejectReason;

  const ParseResult.ok(this.reading) : rejectReason = null;

  const ParseResult.rejected(this.rejectReason) : reading = null;

  bool get isAccepted => rejectReason == null;
}

/// Interpreta o payload publicado pelo firmware no tópico "event"
/// (bluetooth_app.cpp::publicarEvento): `{"canal":N,"estado":"H"/"L","tempo_us":N}`.
/// "canal" é 1-based (1..NUM_CHANNELS) e "tempo_us" é o tempo relativo à
/// repetição de experimento atual, em microssegundos.
class SensorMessageParser {
  ParseResult parseEvent(Map<String, dynamic> payload) {
    final sensor = _asInt(payload['canal']);
    if (sensor == null || sensor < 1 || sensor > 6) {
      return const ParseResult.rejected(RejectReason.sensorOutOfRange);
    }

    if (payload['estado'] == null) {
      return const ParseResult.rejected(RejectReason.missingState);
    }

    final state = SensorState.tryParse(payload['estado']);
    if (state == null) {
      return const ParseResult.rejected(RejectReason.invalidState);
    }

    final tempoUs = _asInt(payload['tempo_us']);
    if (tempoUs == null) {
      return const ParseResult.rejected(RejectReason.malformed);
    }

    return ParseResult.ok(
      ParsedReading(
        sensor: sensor,
        state: state,
        timestampMs: tempoUs ~/ 1000,
      ),
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
