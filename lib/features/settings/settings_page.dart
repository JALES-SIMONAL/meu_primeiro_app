import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../providers/app_controller.dart';
import '../../widgets/bordered_list_tile.dart';
import '../../widgets/language_selector_tile.dart';
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
    final bleConnected = ref.watch(appControllerProvider.select((s) => s.bleConnected));
    final controller = ref.read(appControllerProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: context.tr('settings.equipmentSection'),
            subtitle: bleConnected
                ? context.tr('settings.equipmentSectionSubtitleConnected')
                : context.tr('settings.equipmentSectionSubtitleDisconnected'),
          ),
          const SizedBox(height: 12),
          BorderedListTile(
            leading: const Icon(Icons.tune),
            title: Text(context.tr('settings.equipmentTile')),
            subtitle: Text(context.tr('settings.equipmentTileSubtitle')),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ConfiguracoesPage()),
            ),
          ),
          const SizedBox(height: 24),
          SectionHeader(
            title: context.tr('settings.appSection'),
            subtitle: context.tr('settings.appSectionSubtitle'),
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
                        bleConnected
                            ? Icons.bluetooth_connected
                            : Icons.bluetooth_disabled,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.tr(
                          'settings.bluetoothLabel',
                          params: {
                            'status': bleConnected
                                ? context.tr('common.connected')
                                : context.tr('common.disconnected'),
                          },
                        ),
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
                        label: Text(context.tr('common.scan')),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: bleConnected
                            ? controller.disconnectBluetooth
                            : null,
                        icon: const Icon(Icons.bluetooth_disabled),
                        label: Text(context.tr('common.disconnect')),
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
            title: Text(context.tr('settings.localDrafts')),
            subtitle: Text(context.tr('settings.localDraftsSubtitle')),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RascunhosLocaisPage()),
            ),
          ),
          BorderedListTile(
            leading: const Icon(Icons.list_alt_rounded),
            title: Text(context.tr('settings.logs')),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const LogsPage())),
          ),
          const LanguageSelectorTile(),
          BorderedListTile(
            leading: const Icon(Icons.info_rounded),
            title: Text(context.tr('settings.about')),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AboutPage())),
          ),
        ],
      ),
    );
  }
}
