import 'package:flutter_test/flutter_test.dart';
import 'package:meu_primeiro_app/models/sensor_state.dart';
import 'package:meu_primeiro_app/services/sensor_message_parser.dart';

void main() {
  final parser = SensorMessageParser();

  test('parses a firmware event payload', () {
    final result = parser.parseEvent({
      'canal': 1,
      'estado': 'H',
      'tempo_us': 15480000,
    });

    expect(result.isAccepted, isTrue);
    expect(result.reading!.sensor, 1);
    expect(result.reading!.state, SensorState.high);
    expect(result.reading!.timestampMs, 15480);
  });

  test('rejects channel out of range', () {
    final result = parser.parseEvent({
      'canal': 7,
      'estado': 'H',
      'tempo_us': 1000,
    });

    expect(result.rejectReason, RejectReason.sensorOutOfRange);
  });

  test('rejects missing state', () {
    final result = parser.parseEvent({'canal': 1, 'tempo_us': 1000});

    expect(result.rejectReason, RejectReason.missingState);
  });

  test('rejects invalid state', () {
    final result = parser.parseEvent({
      'canal': 1,
      'estado': 'X',
      'tempo_us': 1000,
    });

    expect(result.rejectReason, RejectReason.invalidState);
  });

  test('rejects malformed payload missing tempo_us', () {
    final result = parser.parseEvent({'canal': 1, 'estado': 'H'});

    expect(result.rejectReason, RejectReason.malformed);
  });
}
