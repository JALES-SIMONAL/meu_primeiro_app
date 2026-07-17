import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_controller.dart';
import '../about/about_page.dart';
import '../collection/collection_page.dart';
import '../dashboard/dashboard_page.dart';
import '../devices/devices_page.dart';
import '../demo/demo_page.dart';
import '../logs/logs_page.dart';
import '../mqtt/mqtt_page.dart';
import '../settings/settings_page.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  static const _tabs = [
    _ShellTab(title: 'Dashboard', icon: Icons.dashboard_rounded),
    _ShellTab(title: 'Dispositivos', icon: Icons.devices_rounded),
    _ShellTab(title: 'MQTT', icon: Icons.wifi_rounded),
    _ShellTab(title: 'Coleta', icon: Icons.storage_rounded),
    _ShellTab(title: 'Logs', icon: Icons.list_alt_rounded),
    _ShellTab(title: 'Configuracoes', icon: Icons.settings_rounded),
    _ShellTab(title: 'Demo', icon: Icons.science_rounded),
    _ShellTab(title: 'Sobre', icon: Icons.info_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);

    final pages = <Widget>[
      const DashboardPage(),
      const DevicesPage(),
      const MqttPage(),
      const CollectionPage(),
      const LogsPage(),
      const SettingsPage(),
      const DemoPage(),
      const AboutPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_tabs[_index].title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Chip(
                label: Text(
                  state.demoMode
                      ? 'Demo'
                      : (state.mqttConnected ? 'MQTT' : 'Offline'),
                ),
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final useRail = constraints.maxWidth >= 1100;
          final content = AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: KeyedSubtree(key: ValueKey(_index), child: pages[_index]),
          );

          if (useRail) {
            return Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (value) =>
                      setState(() => _index = value),
                  labelType: NavigationRailLabelType.all,
                  leading: const SizedBox(height: 12),
                  destinations: [
                    for (final tab in _tabs)
                      NavigationRailDestination(
                        icon: Icon(tab.icon),
                        label: Text(tab.title),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            );
          }

          return Column(
            children: [
              Expanded(child: content),
              NavigationBar(
                selectedIndex: _index,
                onDestinationSelected: (value) =>
                    setState(() => _index = value),
                destinations: [
                  for (final tab in _tabs)
                    NavigationDestination(
                      icon: Icon(tab.icon),
                      label: tab.title,
                    ),
                ],
              ),
            ],
          );
        },
      ),
      floatingActionButton: _index == 2
          ? FloatingActionButton.extended(
              onPressed: () => controller.connectMqtt(),
              icon: const Icon(Icons.link),
              label: const Text('Conectar MQTT'),
            )
          : null,
    );
  }
}

class _ShellTab {
  final String title;
  final IconData icon;

  const _ShellTab({required this.title, required this.icon});
}
