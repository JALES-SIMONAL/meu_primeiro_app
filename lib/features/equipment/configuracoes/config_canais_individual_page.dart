import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/channel_edge_mode.dart';
import '../../../providers/app_controller.dart';

/// Equivalente a maquina_estados::Tela::ConfigCanaisIndividualLista.
class ConfigCanaisIndividualPage extends ConsumerWidget {
  const ConfigCanaisIndividualPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final channelCount = state.selectedDevice?.device.channelCount ?? 6;
    final configs = {for (final c in state.channelConfigs) c.channel: c.mode};

    return Scaffold(
      appBar: AppBar(title: const Text('Config. individual')),
      body: ListView(
        children: [
          for (var canal = 1; canal <= channelCount; canal++)
            ListTile(
              title: Text('Canal $canal'),
              trailing: Text(configs[canal]?.label ?? '?'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _EditarCanalPage(canal: canal),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Equivalente a maquina_estados::Tela::ConfigCanaisIndividualEditar +
/// ConfigCanaisIndividualConfirmar.
class _EditarCanalPage extends ConsumerWidget {
  const _EditarCanalPage({required this.canal});

  final int canal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(appControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text('Config. canal $canal')),
      body: ListView(
        children: [
          for (final modo in ChannelEdgeMode.values)
            ListTile(
              title: Text(modo.label),
              onTap: () async {
                final confirmar = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Salvar config. do canal $canal?'),
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
                  controller.setChannelMode(canal, modo);
                  if (context.mounted) Navigator.of(context).pop();
                }
              },
            ),
        ],
      ),
    );
  }
}
