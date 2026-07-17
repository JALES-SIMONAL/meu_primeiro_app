import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';

import '../models/mqtt_settings.dart';

MqttClient createPlatformMqttClient(MqttSettings settings, String clientId) {
  final scheme = settings.useTls ? 'wss' : 'ws';
  final client = MqttBrowserClient(
    '$scheme://${settings.broker}:${settings.port}${settings.websocketPath}',
    clientId,
  );
  return client;
}
