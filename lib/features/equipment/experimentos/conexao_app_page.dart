import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_controller.dart';

/// Equivalente a maquina_estados::Tela::ConexaoApp.
class ConexaoAppPage extends ConsumerWidget {
  const ConexaoAppPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);
    final device = state.selectedDevice?.device;

    return Scaffold(
      appBar: AppBar(title: const Text('Conexao com app')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Bluetooth'),
            trailing: Text(state.bleConnected ? 'Conectado' : 'Desconectado'),
          ),
          ListTile(title: const Text('MAC'), trailing: Text(device?.macAddress ?? '-')),
          ListTile(title: const Text('ID'), trailing: Text(device?.deviceId ?? '-')),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Reconectar'),
            onTap: controller.reconnectDevice,
          ),
        ],
      ),
    );
  }
}
