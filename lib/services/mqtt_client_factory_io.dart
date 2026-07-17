import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../models/mqtt_settings.dart';

MqttClient createPlatformMqttClient(MqttSettings settings, String clientId) {
  final client = MqttServerClient(settings.broker, clientId)
    ..port = settings.port
    ..secure = settings.useTls
    ..useWebSocket = settings.usesWebSocket;
  return client;
}
