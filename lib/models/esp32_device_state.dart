import 'esp32_device.dart';

class Esp32DeviceState {
  final Esp32Device device;
  final int rebootCount;

  const Esp32DeviceState({required this.device, this.rebootCount = 0});

  factory Esp32DeviceState.initial(Esp32Device device) {
    return Esp32DeviceState(device: device);
  }

  Esp32DeviceState copyWith({Esp32Device? device, int? rebootCount}) {
    return Esp32DeviceState(
      device: device ?? this.device,
      rebootCount: rebootCount ?? this.rebootCount,
    );
  }
}
