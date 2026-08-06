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
          ListTile(
            title: const Text('Nome BLE'),
            trailing: Text(device?.bleDeviceName ?? '-'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Renomear'),
            onTap: () async {
              final controllerTexto = TextEditingController(
                text: device?.bleDeviceName ?? '',
              );
              final novoNome = await showDialog<String>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Renomear dispositivo BLE'),
                  content: TextField(
                    controller: controllerTexto,
                    maxLength: 20,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Nome'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      onPressed: () =>
                          Navigator.of(context).pop(controllerTexto.text.trim()),
                      child: const Text('Salvar'),
                    ),
                  ],
                ),
              );
              if (novoNome != null && novoNome.isNotEmpty) {
                controller.setDeviceName(novoNome);
              }
            },
          ),
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
