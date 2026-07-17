import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/mqtt_settings.dart';
import '../../providers/app_controller.dart';
import '../../widgets/section_header.dart';

class MqttPage extends ConsumerStatefulWidget {
  const MqttPage({super.key});

  @override
  ConsumerState<MqttPage> createState() => _MqttPageState();
}

class _MqttPageState extends ConsumerState<MqttPage> {
  final _brokerController = TextEditingController();
  final _portController = TextEditingController();
  final _clientIdController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pathController = TextEditingController();
  final _baseTopicController = TextEditingController();
  final _timeoutController = TextEditingController();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final settings = ref.read(appControllerProvider).mqttSettings;
    _brokerController.text = settings.broker;
    _portController.text = settings.port.toString();
    _clientIdController.text = settings.clientId;
    _usernameController.text = settings.username ?? '';
    _passwordController.text = settings.password ?? '';
    _pathController.text = settings.websocketPath;
    _baseTopicController.text = settings.baseTopic;
    _timeoutController.text = settings.timeoutSeconds.toString();
    _initialized = true;
  }

  @override
  void dispose() {
    _brokerController.dispose();
    _portController.dispose();
    _clientIdController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _pathController.dispose();
    _baseTopicController.dispose();
    _timeoutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Configuracao MQTT',
            subtitle: 'Use TCP no app desktop/mobile ou WebSocket no Chrome.',
          ),
          const SizedBox(height: 12),
          _buildForm(context, state.mqttSettings),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                onPressed: () {
                  controller.updateMqttSettings(
                    _readSettings(state.mqttSettings),
                  );
                  controller.connectMqtt();
                },
                child: const Text('Conectar'),
              ),
              FilledButton.tonal(
                onPressed: state.mqttConnected
                    ? controller.disconnectMqtt
                    : null,
                child: const Text('Desconectar'),
              ),
              Chip(
                label: Text(state.mqttConnected ? 'Conectado' : 'Desconectado'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Descoberta',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text('monkeytech/devices/+/status'),
                  const Text('monkeytech/devices/+/info'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context, MqttSettings settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _brokerController,
                    decoration: const InputDecoration(labelText: 'Broker'),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _portController,
                    decoration: const InputDecoration(labelText: 'Porta'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _clientIdController,
                    decoration: const InputDecoration(labelText: 'Client ID'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Usuario'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Senha'),
                    obscureText: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pathController,
                    decoration: const InputDecoration(
                      labelText: 'Caminho WebSocket',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _baseTopicController,
                    decoration: const InputDecoration(labelText: 'Tópico base'),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _timeoutController,
                    decoration: const InputDecoration(labelText: 'Timeout (s)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilterChip(
                  label: const Text('TLS'),
                  selected: settings.useTls,
                  onSelected: (value) => _toggleSetting(useTls: value),
                ),
                FilterChip(
                  label: const Text('WebSocket'),
                  selected:
                      settings.protocol == MqttTransportProtocol.websocket,
                  onSelected: (value) => _toggleSetting(
                    protocol: value
                        ? MqttTransportProtocol.websocket
                        : MqttTransportProtocol.tcp,
                  ),
                ),
                FilterChip(
                  label: const Text('Reconnexao auto'),
                  selected: settings.autoReconnect,
                  onSelected: (value) => _toggleSetting(autoReconnect: value),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  MqttSettings _readSettings(MqttSettings current) {
    return current.copyWith(
      broker: _brokerController.text.trim(),
      port: int.tryParse(_portController.text) ?? current.port,
      clientId: _clientIdController.text.trim(),
      username: _usernameController.text.trim().isEmpty
          ? null
          : _usernameController.text.trim(),
      password: _passwordController.text.isEmpty
          ? null
          : _passwordController.text,
      websocketPath: _pathController.text.trim(),
      baseTopic: _baseTopicController.text.trim(),
      timeoutSeconds:
          int.tryParse(_timeoutController.text) ?? current.timeoutSeconds,
    );
  }

  void _toggleSetting({
    bool? useTls,
    MqttTransportProtocol? protocol,
    bool? autoReconnect,
  }) {
    final current = ref.read(appControllerProvider).mqttSettings;
    ref
        .read(appControllerProvider.notifier)
        .updateMqttSettings(
          current.copyWith(
            useTls: useTls ?? current.useTls,
            protocol: protocol ?? current.protocol,
            autoReconnect: autoReconnect ?? current.autoReconnect,
          ),
        );
    setState(() {});
  }
}
