import 'package:flutter_test/flutter_test.dart';
import 'package:meu_primeiro_app/models/sensor_state.dart';
import 'package:meu_primeiro_app/services/sensor_message_parser.dart';

void main() {
  final parser = SensorMessageParser();

  test('parses single sensor message', () {
    final result = parser.parse({
      'deviceId': 'esp32_001',
      'sensor': 1,
      'state': 'H',
      'timestampMs': 15480,
    }, topicDeviceId: 'esp32_001');

    expect(result.isAccepted, isTrue);
    expect(result.readings, hasLength(1));
    expect(result.readings.single.state, SensorState.high);
  });

  test('parses six sensors in one message', () {
    final result = parser.parse({
      'deviceId': 'esp32_001',
      'timestampMs': 18500,
      'sensors': [
        {'sensor': 1, 'state': 'H'},
        {'sensor': 2, 'state': 'L'},
        {'sensor': 3, 'state': 'H'},
        {'sensor': 4, 'state': 'H'},
        {'sensor': 5, 'state': 'L'},
        {'sensor': 6, 'state': 'L'},
      ],
    }, topicDeviceId: 'esp32_001');

    expect(result.isAccepted, isTrue);
    expect(result.readings, hasLength(6));
  });

  test('rejects missing fields and invalid sensors', () {
    expect(
      parser.parse({
        'sensor': 1,
        'state': 'H',
        'timestampMs': 1,
      }, topicDeviceId: 'esp32_001').rejectReason,
      RejectReason.missingDeviceId,
    );

    expect(
      parser.parse({
        'deviceId': 'esp32_001',
        'sensor': 1,
        'state': 'H',
      }, topicDeviceId: 'esp32_001').rejectReason,
      RejectReason.missingTimestamp,
    );

    expect(
      parser.parse({
        'deviceId': 'esp32_001',
        'sensor': 7,
        'state': 'H',
        'timestampMs': 1,
      }, topicDeviceId: 'esp32_001').rejectReason,
      RejectReason.sensorOutOfRange,
    );
  });
}
