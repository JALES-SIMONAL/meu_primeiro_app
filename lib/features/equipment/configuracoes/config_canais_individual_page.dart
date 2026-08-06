import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/channel_edge_mode.dart';
import '../../../providers/app_controller.dart';
import '../../../widgets/bordered_list_tile.dart';

/// Equivalente a maquina_estados::Tela::ConfigCanaisIndividualLista.
class ConfigCanaisIndividualPage extends ConsumerStatefulWidget {
  const ConfigCanaisIndividualPage({super.key});

  @override
  ConsumerState<ConfigCanaisIndividualPage> createState() =>
      _ConfigCanaisIndividualPageState();
}

class _ConfigCanaisIndividualPageState
    extends ConsumerState<ConfigCanaisIndividualPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appControllerProvider.notifier).getChannels();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final channelCount = state.selectedDevice?.device.channelCount ?? 6;
    final configs = {for (final c in state.channelConfigs) c.channel: c.mode};

    return Scaffold(
      appBar: AppBar(title: const Text('Config. individual')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (var canal = 1; canal <= channelCount; canal++)
            BorderedListTile(
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
        padding: const EdgeInsets.all(12),
        children: [
          for (final modo in ChannelEdgeMode.values)
            BorderedListTile(
              title: Text(modo.label),
              trailing: null,
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
