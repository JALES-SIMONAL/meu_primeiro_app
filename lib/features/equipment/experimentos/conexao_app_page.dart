import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_controller.dart';
import '../../../widgets/bordered_list_tile.dart';
import '../../../widgets/senha_dialog.dart';

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
          ListTile(
            title: const Text('MAC'),
            trailing: Text(device?.macAddress ?? '-'),
          ),
          ListTile(
            title: const Text('ID'),
            trailing: Text(device?.deviceId ?? '-'),
          ),
          ListTile(
            title: const Text('Nome BLE'),
            trailing: Text(device?.bleDeviceName ?? '-'),
          ),
          const SizedBox(height: 8),
          BorderedListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Renomear'),
            trailing: null,
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
                      onPressed: () => Navigator.of(
                        context,
                      ).pop(controllerTexto.text.trim()),
                      child: const Text('Salvar'),
                    ),
                  ],
                ),
              );
              if (novoNome != null && novoNome.isNotEmpty && context.mounted) {
                final ok = await executarComSenha(
                  context,
                  ref,
                  ({senha}) => controller.setDeviceName(novoNome, senha: senha),
                );
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nao foi possivel renomear.')),
                  );
                }
              }
            },
          ),
          BorderedListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Reconectar'),
            trailing: null,
            onTap: controller.reconnectDevice,
          ),
          BorderedListTile(
            leading: const Icon(Icons.password_outlined),
            title: const Text('Trocar senha'),
            subtitle: const Text(
              'Usada para renomear o BLE e ativar/desativar Analise de dados',
            ),
            onTap: () async {
              final senhaAtualController = TextEditingController();
              final novaSenhaController = TextEditingController();
              final confirmar = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Trocar senha'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: senhaAtualController,
                        obscureText: true,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Senha atual',
                        ),
                      ),
                      TextField(
                        controller: novaSenhaController,
                        obscureText: true,
                        maxLength: 10,
                        decoration: const InputDecoration(
                          labelText: 'Nova senha (3 a 10 caracteres)',
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Confirmar'),
                    ),
                  ],
                ),
              );
              if (confirmar != true || !context.mounted) return;

              final novaSenha = novaSenhaController.text;
              if (novaSenha.length < 3 || novaSenha.length > 10) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('A nova senha deve ter de 3 a 10 caracteres.'),
                  ),
                );
                return;
              }

              final ok = await controller.changePassword(
                senhaAtualController.text,
                novaSenha,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok ? 'Senha alterada.' : 'Senha atual incorreta.',
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
