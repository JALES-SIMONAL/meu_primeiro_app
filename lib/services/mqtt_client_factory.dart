import '../models/mqtt_settings.dart';

import 'mqtt_client_factory_io.dart'
    if (dart.library.html) 'mqtt_client_factory_web.dart';

import 'package:mqtt_client/mqtt_client.dart';

MqttClient createMqttClient(MqttSettings settings, String clientId) {
  return createPlatformMqttClient(settings, clientId);
}
