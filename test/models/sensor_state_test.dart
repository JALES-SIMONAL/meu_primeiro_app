import 'package:flutter_test/flutter_test.dart';
import 'package:meu_primeiro_app/models/sensor_state.dart';

void main() {
  group('SensorState.tryParse', () {
    test('accepts H and L strings', () {
      expect(SensorState.tryParse('H'), SensorState.high);
      expect(SensorState.tryParse('L'), SensorState.low);
    });

    test('accepts HIGH, LOW, 1, 0, true and false', () {
      expect(SensorState.tryParse('HIGH'), SensorState.high);
      expect(SensorState.tryParse('LOW'), SensorState.low);
      expect(SensorState.tryParse('1'), SensorState.high);
      expect(SensorState.tryParse('0'), SensorState.low);
      expect(SensorState.tryParse(true), SensorState.high);
      expect(SensorState.tryParse(false), SensorState.low);
    });

    test('rejects invalid values', () {
      expect(SensorState.tryParse('x'), isNull);
      expect(SensorState.tryParse(2), isNull);
      expect(SensorState.tryParse(null), isNull);
    });
  });
}
