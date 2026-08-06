import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_controller.dart';
import '../../../widgets/bordered_list_tile.dart';
import 'config_canais_individual_page.dart';
import 'config_canais_todos_page.dart';
import 'config_canais_visualizar_page.dart';

/// Equivalente a maquina_estados::Tela::ConfigCanais.
class ConfigCanaisPage extends ConsumerWidget {
  const ConfigCanaisPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(appControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Config. canais/sensores')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          BorderedListTile(
            title: const Text('Configurar todos os canais'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ConfigCanaisTodosPage()),
            ),
          ),
          BorderedListTile(
            title: const Text('Configurar individualmente'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ConfigCanaisIndividualPage(),
              ),
            ),
          ),
          BorderedListTile(
            title: const Text('Visualizar configuracao'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ConfigCanaisVisualizarPage(),
              ),
            ),
          ),
          BorderedListTile(
            title: const Text('Restaurar config. padrao'),
            trailing: const Icon(Icons.restore),
            onTap: () async {
              final confirmar = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Restaurar todos p/ Ambos?'),
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
              if (confirmar == true) controller.restoreChannelDefaults();
            },
          ),
        ],
      ),
    );
  }
}
