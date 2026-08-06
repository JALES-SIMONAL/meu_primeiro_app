import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_controller.dart';
import '../../../widgets/bordered_list_tile.dart';
import 'config_canais_page.dart';
import 'manual_page.dart';
import 'modo_operacao_page.dart';
import 'level_edit_page.dart';
import 'sobre_page.dart';

/// Equivalente a maquina_estados::Tela::Configuracoes.
class ConfiguracoesPage extends ConsumerWidget {
  const ConfiguracoesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(appControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Configuracoes')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          BorderedListTile(
            leading: const Icon(Icons.settings_input_component),
            title: const Text('Modo de operacao'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ModoOperacaoPage()),
            ),
          ),
          BorderedListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Brilho da tela'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LevelEditPage(
                  title: 'Brilho',
                  initialValue: ref.read(appControllerProvider).selectedDevice?.device.brightness ?? 0,
                  onChanged: controller.setBrightness,
                ),
              ),
            ),
          ),
          BorderedListTile(
            leading: const Icon(Icons.volume_up),
            title: const Text('Volume'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LevelEditPage(
                  title: 'Volume',
                  initialValue: ref.read(appControllerProvider).selectedDevice?.device.volume ?? 0,
                  onChanged: controller.setVolume,
                ),
              ),
            ),
          ),
          BorderedListTile(
            leading: const Icon(Icons.sensors),
            title: const Text('Config. canais/sensores'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ConfigCanaisPage()),
            ),
          ),
          BorderedListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: const Text('Manual'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ManualPage()),
            ),
          ),
          BorderedListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Sobre'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SobrePage()),
            ),
          ),
        ],
      ),
    );
  }
}
