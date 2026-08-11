import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_controller.dart';
import '../../widgets/bordered_list_tile.dart';
import '../../widgets/section_header.dart';
import '../about/about_page.dart';
import '../bluetooth/bluetooth_page.dart';
import '../equipment/configuracoes/configuracoes_page.dart';
import '../equipment/experimentos/rascunhos_locais_page.dart';
import '../logs/logs_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Equipamento',
            subtitle: state.bleConnected
                ? 'Configuracoes do equipamento conectado.'
                : 'Conecte via Bluetooth para acessar as configuracoes do equipamento.',
          ),
          const SizedBox(height: 12),
          BorderedListTile(
            leading: const Icon(Icons.tune),
            title: const Text('Configuracoes do equipamento'),
            subtitle: const Text(
              'Modo de operacao, brilho, volume, canais, manual, sobre',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ConfiguracoesPage()),
            ),
          ),
          const SizedBox(height: 24),
          SectionHeader(
            title: 'Aplicativo',
            subtitle: 'Bluetooth, logs e informacoes gerais do app.',
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        state.bleConnected
                            ? Icons.bluetooth_connected
                            : Icons.bluetooth_disabled,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Bluetooth: ${state.bleConnected ? "Conectado" : "Desconectado"}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const BluetoothPage(),
                          ),
                        ),
                        icon: const Icon(Icons.bluetooth_searching),
                        label: const Text('Escanear'),
                      ),
                      FilledButton.tonal(
                        onPressed: state.bleConnected
                            ? controller.disconnectBluetooth
                            : null,
                        child: const Text('Desconectar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          BorderedListTile(
            leading: const Icon(Icons.drafts_outlined),
            title: const Text('Rascunhos locais'),
            subtitle: const Text(
              'Medicoes finalizadas sem nome salvo no equipamento',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RascunhosLocaisPage()),
            ),
          ),
          BorderedListTile(
            leading: const Icon(Icons.list_alt_rounded),
            title: const Text('Logs'),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const LogsPage())),
          ),
          BorderedListTile(
            leading: const Icon(Icons.info_rounded),
            title: const Text('Sobre'),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AboutPage())),
          ),
        ],
      ),
    );
  }
}
