import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_controller.dart';

/// Equivalente a maquina_estados::Tela::ConfigCanaisVisualizar.
class ConfigCanaisVisualizarPage extends ConsumerStatefulWidget {
  const ConfigCanaisVisualizarPage({super.key});

  @override
  ConsumerState<ConfigCanaisVisualizarPage> createState() =>
      _ConfigCanaisVisualizarPageState();
}

class _ConfigCanaisVisualizarPageState
    extends ConsumerState<ConfigCanaisVisualizarPage> {
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
