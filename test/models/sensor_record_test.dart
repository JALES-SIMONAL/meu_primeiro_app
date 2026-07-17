import 'package:flutter_test/flutter_test.dart';
import 'package:meu_primeiro_app/models/sensor_record.dart';
import 'package:meu_primeiro_app/models/sensor_state.dart';

void main() {
  test('formats elapsed time and CSV rows', () {
    final record = SensorRecord(
      deviceId: 'esp32_001',
      sensor: 1,
      state: SensorState.high,
      timestampMs: 15480,
      receivedAt: DateTime.parse('2026-07-17T09:30:00.150-03:00'),
      bootSession: 1,
    );

    expect(record.elapsedTimeFormatted, '00:00:15.480');
    expect(record.elapsedTimeSecondsFormatted, '15,480 s');
    expect(record.elapsedTimeMsFormatted, '15480 ms');
    expect(
      record.toCsvRow(),
      contains('esp32_001;1;H;HIGH;15480;00:00:15.480'),
    );
  });

  test('escapes CSV fields', () {
    final record = SensorRecord(
      deviceId: 'esp32;001',
      sensor: 1,
      state: SensorState.low,
      timestampMs: 10,
      receivedAt: DateTime.parse('2026-07-17T09:30:00.150-03:00'),
      bootSession: 2,
    );

    expect(record.toCsvRow(), startsWith('"esp32;001";'));
  });
}
