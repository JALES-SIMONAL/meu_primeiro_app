enum MqttTransportProtocol { tcp, websocket }

class MqttSettings {
  final String broker;
  final int port;
  final String clientId;
  final String? username;
  final String? password;
  final bool useTls;
  final MqttTransportProtocol protocol;
  final String websocketPath;
  final String baseTopic;
  final int timeoutSeconds;
  final bool autoReconnect;

  const MqttSettings({
    required this.broker,
    required this.port,
    required this.clientId,
    required this.username,
    required this.password,
    required this.useTls,
    required this.protocol,
    required this.websocketPath,
    required this.baseTopic,
    required this.timeoutSeconds,
    required this.autoReconnect,
  });

  factory MqttSettings.defaults() {
    return const MqttSettings(
      broker: '',
      port: 1883,
      clientId: 'monkeytech_logger',
      username: null,
      password: null,
      useTls: false,
      protocol: MqttTransportProtocol.websocket,
      websocketPath: '/mqtt',
      baseTopic: 'monkeytech/devices',
      timeoutSeconds: 10,
      autoReconnect: true,
    );
  }

  MqttSettings copyWith({
    String? broker,
    int? port,
    String? clientId,
    String? username,
    String? password,
    bool? useTls,
    MqttTransportProtocol? protocol,
    String? websocketPath,
    String? baseTopic,
    int? timeoutSeconds,
    bool? autoReconnect,
  }) {
    return MqttSettings(
      broker: broker ?? this.broker,
      port: port ?? this.port,
      clientId: clientId ?? this.clientId,
      username: username ?? this.username,
      password: password ?? this.password,
      useTls: useTls ?? this.useTls,
      protocol: protocol ?? this.protocol,
      websocketPath: websocketPath ?? this.websocketPath,
      baseTopic: baseTopic ?? this.baseTopic,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      autoReconnect: autoReconnect ?? this.autoReconnect,
    );
  }

  bool get usesWebSocket => protocol == MqttTransportProtocol.websocket;
}
