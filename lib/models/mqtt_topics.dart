class MqttTopics {
  static const String root = 'monkeytech/devices';

  static String status(String deviceId) => '$root/$deviceId/status';
  static String data(String deviceId) => '$root/$deviceId/data';
  static String info(String deviceId) => '$root/$deviceId/info';
  static String command(String deviceId) => '$root/$deviceId/command';
  static String response(String deviceId) => '$root/$deviceId/response';

  static const String discoveryStatusWildcard = '$root/+/status';
  static const String discoveryInfoWildcard = '$root/+/info';

  static String? deviceIdFromTopic(String topic) {
    final parts = topic.split('/');
    if (parts.length != 4) return null;
    if (parts[0] != 'monkeytech' || parts[1] != 'devices') return null;

    const validSuffixes = {'status', 'data', 'info', 'command', 'response'};
    if (!validSuffixes.contains(parts[3])) return null;

    final deviceId = parts[2];
    return deviceId.isEmpty ? null : deviceId;
  }
}
