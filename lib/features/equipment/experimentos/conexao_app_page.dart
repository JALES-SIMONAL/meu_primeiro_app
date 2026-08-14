import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../providers/app_controller.dart';
import '../../../widgets/bordered_list_tile.dart';
import '../../../widgets/senha_dialog.dart';

/// Equivalente a maquina_estados::Tela::ConexaoApp.
class ConexaoAppPage extends ConsumerWidget {
  const ConexaoAppPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (device, bleConnected) = ref.watch(
      appControllerProvider.select((s) => (s.selectedDevice?.device, s.bleConnected)),
    );
    final controller = ref.read(appControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('appConnection.title'))),
      body: ListView(
        children: [
          ListTile(
            title: Text(context.tr('appConnection.bluetooth')),
            trailing: Text(
              bleConnected
                  ? context.tr('common.connected')
                  : context.tr('common.disconnected'),
            ),
          ),
          ListTile(
            title: Text(context.tr('appConnection.mac')),
            trailing: Text(device?.macAddress ?? context.tr('common.notAvailable')),
          ),
          ListTile(
            title: Text(context.tr('appConnection.id')),
            trailing: Text(device?.deviceId ?? context.tr('common.notAvailable')),
          ),
          ListTile(
            title: Text(context.tr('appConnection.bleName')),
            trailing: Text(device?.bleDeviceName ?? context.tr('common.notAvailable')),
          ),
          const SizedBox(height: 8),
          BorderedListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text(context.tr('appConnection.rename')),
            trailing: null,
            onTap: () async {
              final controllerTexto = TextEditingController(
                text: device?.bleDeviceName ?? '',
              );
              final novoNome = await showDialog<String>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(context.tr('appConnection.renameDialogTitle')),
                  content: TextField(
                    controller: controllerTexto,
                    maxLength: 20,
                    autofocus: true,
                    decoration: InputDecoration(labelText: context.tr('appConnection.nameLabel')),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(context.tr('common.cancel')),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).pop(controllerTexto.text.trim()),
                      child: Text(context.tr('common.save')),
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
                    SnackBar(content: Text(context.tr('appConnection.renameFailed'))),
                  );
                }
              }
            },
          ),
          BorderedListTile(
            leading: const Icon(Icons.sync),
            title: Text(context.tr('appConnection.reconnect')),
            trailing: null,
            onTap: controller.reconnectDevice,
          ),
          BorderedListTile(
            leading: const Icon(Icons.password_outlined),
            title: Text(context.tr('appConnection.changePassword')),
            subtitle: Text(context.tr('appConnection.changePasswordSubtitle')),
            onTap: () async {
              final senhaAtualController = TextEditingController();
              final novaSenhaController = TextEditingController();
              final confirmar = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(context.tr('appConnection.changePasswordDialogTitle')),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: senhaAtualController,
                        obscureText: true,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: context.tr('appConnection.currentPassword'),
                        ),
                      ),
                      TextField(
                        controller: novaSenhaController,
                        obscureText: true,
                        maxLength: 10,
                        decoration: InputDecoration(
                          labelText: context.tr('appConnection.newPasswordLabel'),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(context.tr('common.cancel')),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(context.tr('common.confirm')),
                    ),
                  ],
                ),
              );
              if (confirmar != true || !context.mounted) return;

              final novaSenha = novaSenhaController.text;
              if (novaSenha.length < 3 || novaSenha.length > 10) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.tr('appConnection.passwordLengthError'))),
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
                      ok
                          ? context.tr('appConnection.passwordChanged')
                          : context.tr('appConnection.passwordIncorrect'),
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
