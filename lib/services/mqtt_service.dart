import 'dart:async';

import 'package:mqtt_client/mqtt_client.dart';

import '../models/mqtt_settings.dart';
import 'mqtt_client_factory.dart';

class MqttIncomingMessage {
  final String topic;
  final String payload;

  const MqttIncomingMessage({required this.topic, required this.payload});
}

enum MqttConnectionStateUi {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

abstract class MqttService {
  Stream<MqttConnectionStateUi> get connectionStateChanges;
  Stream<MqttIncomingMessage> get messages;
  bool get isConnected;

  Future<void> connect(MqttSettings settings);
  Future<void> disconnect();
  void subscribeTopic(String topic);
  void publishJson(String topic, String payload);
}

class MqttClientService implements MqttService {
  final _connectionController =
      StreamController<MqttConnectionStateUi>.broadcast();
  final _messageController = StreamController<MqttIncomingMessage>.broadcast();

  MqttClient? _client;

  @override
  Stream<MqttConnectionStateUi> get connectionStateChanges =>
      _connectionController.stream;

  @override
  Stream<MqttIncomingMessage> get messages => _messageController.stream;

  @override
  bool get isConnected =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  @override
  Future<void> connect(MqttSettings settings) async {
    await disconnect();
    _connectionController.add(MqttConnectionStateUi.connecting);

    final clientId = settings.clientId.isNotEmpty
        ? settings.clientId
        : 'monkeytech_logger';
    final client = createMqttClient(settings, clientId);

    client.keepAlivePeriod = 20;
    client.logging(on: false);
    client.setProtocolV311();
    client.onConnected = () =>
        _connectionController.add(MqttConnectionStateUi.connected);
    client.onDisconnected = () =>
        _connectionController.add(MqttConnectionStateUi.disconnected);
    client.onSubscribed = (topic) {};
    client.onSubscribeFail = (topic) {};

    if (settings.username != null && settings.username!.isNotEmpty) {
      client.connectionMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .startClean()
          .authenticateAs(settings.username!, settings.password ?? '');
    }

    _client = client;

    try {
      final status = await client.connect(settings.username, settings.password);
      if (status?.state != MqttConnectionState.connected) {
        _connectionController.add(MqttConnectionStateUi.error);
        client.disconnect();
        return;
      }

      _listenForMessages(client);
    } catch (_) {
      _connectionController.add(MqttConnectionStateUi.error);
      client.disconnect();
      rethrow;
    }
  }

  void _listenForMessages(MqttClient client) {
    final updates = client.updates;
    if (updates == null) return;
    updates.listen((messages) {
      for (final message in messages) {
        final topic = message.topic;
        final payloadMessage = message.payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(
          payloadMessage.payload.message,
        );
        _messageController.add(
          MqttIncomingMessage(topic: topic, payload: payload),
        );
      }
    });
  }

  @override
  Future<void> disconnect() async {
    _client?.disconnect();
    _client = null;
    _connectionController.add(MqttConnectionStateUi.disconnected);
  }

  @override
  void publishJson(String topic, String payload) {
    final client = _client;
    if (client == null || !isConnected) return;
    final builder = MqttClientPayloadBuilder()..addString(payload);
    client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  @override
  void subscribeTopic(String topic) {
    final client = _client;
    if (client == null || !isConnected) return;
    client.subscribe(topic, MqttQos.atLeastOnce);
  }
}
