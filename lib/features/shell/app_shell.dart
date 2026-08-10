import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_controller.dart';
import '../bluetooth/bluetooth_page.dart';
import '../equipment/analise/analise_dados_page.dart';
import '../equipment/experimentos/experimentos_page.dart';
import '../settings/settings_page.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  static const _tabs = [
    _ShellTab(title: 'Experimentos', icon: Icons.science_outlined),
    _ShellTab(title: 'Analise de Dados', icon: Icons.query_stats),
    _ShellTab(title: 'Configuracoes', icon: Icons.settings_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);

    final pages = <Widget>[
      const ExperimentosPage(),
      const AnaliseDadosPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_tabs[_index].title),
        actions: [
          IconButton(
            tooltip: state.bleConnected
                ? 'Bluetooth conectado'
                : 'Conectar via Bluetooth',
            icon: Icon(
              state.bleConnected ? Icons.bluetooth_connected : Icons.bluetooth,
              color: state.bleConnected ? Colors.lightGreenAccent : null,
            ),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const BluetoothPage())),
          ),
          const SizedBox(width: 4),
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
    );
  }
}

class _ShellTab {
  final String title;
  final IconData icon;

  const _ShellTab({required this.title, required this.icon});
}
