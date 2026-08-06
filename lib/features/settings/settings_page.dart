import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/collection_session.dart';
import '../../providers/app_controller.dart';
import '../../widgets/bordered_list_tile.dart';
import '../../widgets/section_header.dart';
import '../about/about_page.dart';
import '../equipment/configuracoes/configuracoes_page.dart';
import '../logs/logs_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final equipamentoConectado = state.bleConnected;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Configuracoes gerais',
            subtitle: 'Resumo do ambiente e atalhos de operacao.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _SettingCard(
                title: 'Aplicativo',
                value: 'Monkey Tech Data Logger',
              ),
              _SettingCard(
                title: 'Bluetooth',
                value: state.bleConnected ? 'Conectado' : 'Desconectado',
              ),
              _SettingCard(
                title: 'Dispositivo selecionado',
                value: state.selectedDevice?.device.displayName ?? '---',
              ),
              _SettingCard(
                title: 'Selecao bloqueada',
                value: state.collectionSession?.stage == CollectionStage.running
                    ? 'Sim'
                    : 'Nao',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Observacoes'),
                  SizedBox(height: 8),
                  Text(
                    'Os dados de cada dispositivo ficam separados por deviceId.',
                  ),
                  Text(
                    'A conexao com o equipamento e via Bluetooth Low Energy (BLE).',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SectionHeader(
            title: 'Equipamento',
            subtitle: equipamentoConectado
                ? 'Configuracoes do equipamento conectado.'
                : 'Conecte via Bluetooth para acessar as configuracoes do equipamento.',
          ),
          const SizedBox(height: 12),
          BorderedListTile(
            enabled: equipamentoConectado,
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
            subtitle: 'Logs e informacoes gerais do app.',
          ),
          const SizedBox(height: 12),
          BorderedListTile(
            leading: const Icon(Icons.list_alt_rounded),
            title: const Text('Logs'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LogsPage()),
            ),
          ),
          BorderedListTile(
            leading: const Icon(Icons.info_rounded),
            title: const Text('Sobre'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AboutPage()),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  const _SettingCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 6),
              Text(value, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
