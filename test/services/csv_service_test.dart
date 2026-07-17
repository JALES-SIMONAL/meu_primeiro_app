import 'package:flutter_test/flutter_test.dart';
import 'package:meu_primeiro_app/models/sensor_record.dart';
import 'package:meu_primeiro_app/models/sensor_state.dart';
import 'package:meu_primeiro_app/services/csv_service.dart';

void main() {
  test('builds CSV and sanitizes file names', () {
    final service = CsvService();
    final csv = service.buildCsv([
      SensorRecord(
        deviceId: 'esp32_001',
        sensor: 1,
        state: SensorState.high,
        timestampMs: 15480,
        receivedAt: DateTime.parse('2026-07-17T09:30:00.150-03:00'),
        bootSession: 1,
      ),
    ]);

    expect(csv, startsWith(SensorRecord.csvHeader));
    expect(
      service.suggestFileName('esp32 001', label: 'ensaio 01'),
      'esp32_001_ensaio_01.csv',
    );
  });

  test('escapes CSV content with alternate delimiter', () {
    final service = CsvService();
    final csv = service.buildCsv([
      SensorRecord(
        deviceId: 'esp32;001',
        sensor: 1,
        state: SensorState.low,
        timestampMs: 10,
        receivedAt: DateTime.parse('2026-07-17T09:30:00.150-03:00'),
        bootSession: 1,
      ),
    ], delimiter: ',');

    expect(csv, contains('"esp32;001"'));
  });
}
