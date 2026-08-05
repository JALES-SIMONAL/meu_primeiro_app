import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_controller.dart';
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
        children: [
          ListTile(
            leading: const Icon(Icons.settings_input_component),
            title: const Text('Modo de operacao'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ModoOperacaoPage()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Brilho da tela'),
            trailing: const Icon(Icons.chevron_right),
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
          ListTile(
            leading: const Icon(Icons.volume_up),
            title: const Text('Volume'),
            trailing: const Icon(Icons.chevron_right),
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
          ListTile(
            leading: const Icon(Icons.sensors),
            title: const Text('Config. canais/sensores'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ConfigCanaisPage()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: const Text('Manual'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ManualPage()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Sobre'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SobrePage()),
            ),
          ),
        ],
      ),
    );
  }
}
