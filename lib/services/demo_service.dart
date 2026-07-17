import 'dart:math';

import '../models/esp32_device.dart';
import '../models/sensor_state.dart';

class DemoService {
  final Random _random;

  DemoService({int seed = 42}) : _random = Random(seed);

  List<Esp32Device> createDemoDevices() {
    return const [
      Esp32Device(
        deviceId: 'esp32_demo_01',
        name: 'Demo 01',
        macAddress: 'AA:BB:CC:DD:EE:01',
        firmwareVersion: '1.0.0-demo',
        isOnline: true,
      ),
      Esp32Device(
        deviceId: 'esp32_demo_02',
        name: 'Demo 02',
        macAddress: 'AA:BB:CC:DD:EE:02',
        firmwareVersion: '1.0.0-demo',
        isOnline: true,
      ),
      Esp32Device(
        deviceId: 'esp32_demo_03',
        name: 'Demo 03',
        macAddress: 'AA:BB:CC:DD:EE:03',
        firmwareVersion: '1.0.0-demo',
        isOnline: true,
      ),
    ];
  }

  SensorState nextState(SensorState current) {
    if (_random.nextBool()) {
      return current == SensorState.high ? SensorState.low : SensorState.high;
    }
    return current;
  }

  int nextTimestamp(int currentTimestampMs) {
    return currentTimestampMs + 600 + _random.nextInt(800);
  }
}
