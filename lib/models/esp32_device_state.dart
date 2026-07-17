import 'esp32_device.dart';
import 'sensor_state.dart';

class ChannelState {
  final int sensor;
  final SensorState? state;
  final int? timestampMs;
  final DateTime? receivedAt;
  final int changeCount;
  final int messageCount;

  const ChannelState({
    required this.sensor,
    this.state,
    this.timestampMs,
    this.receivedAt,
    this.changeCount = 0,
    this.messageCount = 0,
  });

  ChannelState copyWith({
    SensorState? state,
    int? timestampMs,
    DateTime? receivedAt,
    int? changeCount,
    int? messageCount,
  }) {
    return ChannelState(
      sensor: sensor,
      state: state ?? this.state,
      timestampMs: timestampMs ?? this.timestampMs,
      receivedAt: receivedAt ?? this.receivedAt,
      changeCount: changeCount ?? this.changeCount,
      messageCount: messageCount ?? this.messageCount,
    );
  }

  static ChannelState empty(int sensor) => ChannelState(sensor: sensor);
}

class Esp32DeviceState {
  final Esp32Device device;
  final Map<int, ChannelState> channels;
  final int rebootCount;
  final int totalMessages;
  final int totalInvalidMessages;
  final int? lastTimestampMs;
  final int? lastUptimeMs;

  const Esp32DeviceState({
    required this.device,
    required this.channels,
    this.rebootCount = 0,
    this.totalMessages = 0,
    this.totalInvalidMessages = 0,
    this.lastTimestampMs,
    this.lastUptimeMs,
  });

  factory Esp32DeviceState.initial(Esp32Device device) {
    return Esp32DeviceState(
      device: device,
      channels: {
        for (var sensor = 1; sensor <= device.channelCount; sensor++)
          sensor: ChannelState.empty(sensor),
      },
    );
  }

  int get highCount => channels.values
      .where((channel) => channel.state == SensorState.high)
      .length;
  int get lowCount => channels.values
      .where((channel) => channel.state == SensorState.low)
      .length;
  int get noDataCount =>
      channels.values.where((channel) => channel.state == null).length;

  Esp32DeviceState copyWith({
    Esp32Device? device,
    Map<int, ChannelState>? channels,
    int? rebootCount,
    int? totalMessages,
    int? totalInvalidMessages,
    int? lastTimestampMs,
    int? lastUptimeMs,
  }) {
    return Esp32DeviceState(
      device: device ?? this.device,
      channels: channels ?? this.channels,
      rebootCount: rebootCount ?? this.rebootCount,
      totalMessages: totalMessages ?? this.totalMessages,
      totalInvalidMessages: totalInvalidMessages ?? this.totalInvalidMessages,
      lastTimestampMs: lastTimestampMs ?? this.lastTimestampMs,
      lastUptimeMs: lastUptimeMs ?? this.lastUptimeMs,
    );
  }
}
