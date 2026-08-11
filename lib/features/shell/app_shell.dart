import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_controller.dart';
import '../bluetooth/bluetooth_page.dart';
import '../equipment/analise/analise_dados_page.dart';
import '../equipment/experimentos/experimentos_page.dart';
import '../settings/settings_page.dart';

/// Indice da aba "Analise de Dados" em _tabs/pages — usado para gatear a
/// troca de aba por senha quando a analise estiver desativada (ver
/// Esp32Device.dataAnalysisEnabled/AppController.setDataAnalysisEnabled).
const int _indiceAbaAnaliseDados = 1;

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

  /// "Analise de Dados" só fica acessível de verdade quando habilitada em
  /// Configuracoes (senha) — tocar na aba desativada NÃO deve ativá-la por
  /// conta própria, só avisa onde ativar. Isso é intencional (feedback do
  /// usuário): a única forma de ligar a análise é a troca explícita em
  /// Configuracoes.
  void _selecionarAba(int indice) {
    final analiseHabilitada =
        ref.read(appControllerProvider).selectedDevice?.device.dataAnalysisEnabled ??
        true;

    if (indice == _indiceAbaAnaliseDados && !analiseHabilitada) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Analise de dados esta desativada. Ative em Configuracoes.',
          ),
        ),
      );
      return;
    }

    setState(() => _index = indice);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final analiseHabilitada =
        state.selectedDevice?.device.dataAnalysisEnabled ?? true;

    final pages = <Widget>[
      const ExperimentosPage(),
      const AnaliseDadosPage(),
      const SettingsPage(),
    ];

    Color? corIcone(int indice) =>
        (indice == _indiceAbaAnaliseDados && !analiseHabilitada) ? Colors.grey : null;

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
                  onDestinationSelected: _selecionarAba,
                  labelType: NavigationRailLabelType.all,
                  leading: const SizedBox(height: 12),
                  destinations: [
                    for (final (indice, tab) in _tabs.indexed)
                      NavigationRailDestination(
                        icon: Icon(tab.icon, color: corIcone(indice)),
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
                onDestinationSelected: _selecionarAba,
                destinations: [
                  for (final (indice, tab) in _tabs.indexed)
                    NavigationDestination(
                      icon: Icon(tab.icon, color: corIcone(indice)),
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
