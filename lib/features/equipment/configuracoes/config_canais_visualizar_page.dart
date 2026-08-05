import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_controller.dart';

/// Equivalente a maquina_estados::Tela::ConfigCanaisVisualizar.
class ConfigCanaisVisualizarPage extends ConsumerWidget {
  const ConfigCanaisVisualizarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final channelCount = state.selectedDevice?.device.channelCount ?? 6;
    final configs = {for (final c in state.channelConfigs) c.channel: c.mode};

    return Scaffold(
      appBar: AppBar(title: const Text('Visualizar config.')),
      body: ListView(
        children: [
          for (var canal = 1; canal <= channelCount; canal++)
            ListTile(
              title: Text('Canal $canal'),
              trailing: Text(configs[canal]?.label ?? '?'),
            ),
        ],
      ),
    );
  }
}
