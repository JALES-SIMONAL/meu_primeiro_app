import 'package:flutter_test/flutter_test.dart';
import 'package:meu_primeiro_app/models/collection_session.dart';
import 'package:meu_primeiro_app/models/sensor_state.dart';
import 'package:meu_primeiro_app/providers/app_controller.dart';

void main() {
  late AppController controller;

  setUp(() {
    controller = AppController();
  });

  tearDown(() {
    controller.shutdown();
  });

  test('locks device selection during active collection', () {
    final firstDevice = controller.state.devices.keys.first;
    controller.selectDevice(firstDevice);
    controller.startCollection(fileName: 'ensaio 01');

    final otherDevice = controller.state.devices.keys.firstWhere(
      (deviceId) => deviceId != firstDevice,
    );
    controller.selectDevice(otherDevice);

    expect(controller.state.selectedDeviceId, firstDevice);
    expect(controller.state.collectionSession?.stage, CollectionStage.running);
  });

  test('records data and demo mode can be enabled', () {
    final selectedDevice = controller.state.devices.keys.first;
    controller.selectDevice(selectedDevice);
    controller.toggleDemoMode(true);
    controller.processIncomingPayload(
      'monkeytech/devices/$selectedDevice/data',
      {
        'deviceId': selectedDevice,
        'timestampMs': 1000,
        'sensors': [
          {'sensor': 1, 'state': 'H'},
          {'sensor': 2, 'state': 'L'},
        ],
      },
    );

    expect(controller.state.demoMode, isTrue);
    expect(controller.state.recordsFor(selectedDevice), isNotEmpty);
    expect(
      controller.state.devices[selectedDevice]!.channels[1]!.state,
      SensorState.high,
    );
  });
}
