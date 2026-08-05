import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/channel_edge_mode.dart';
import '../../../providers/app_controller.dart';

/// Equivalente a maquina_estados::Tela::ConfigCanaisTodos +
/// ConfigCanaisTodosConfirmar.
class ConfigCanaisTodosPage extends ConsumerWidget {
  const ConfigCanaisTodosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(appControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Configurar todos')),
      body: ListView(
        children: [
          for (final modo in ChannelEdgeMode.values)
            ListTile(
              title: Text(modo.label),
              onTap: () async {
                final confirmar = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Aplicar a todos os canais?'),
                    content: Text(modo.label),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Nao'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Sim'),
                      ),
                    ],
                  ),
                );
                if (confirmar == true) {
                  controller.setAllChannelsMode(modo);
                  if (context.mounted) Navigator.of(context).pop();
                }
              },
            ),
        ],
      ),
    );
  }
}
