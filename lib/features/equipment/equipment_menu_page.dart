import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_controller.dart';
import '../../widgets/section_header.dart';
import 'analise/analise_dados_page.dart';
import 'configuracoes/configuracoes_page.dart';
import 'experimentos/experimentos_page.dart';

/// Equivalente a maquina_estados::Tela::MenuPrincipal: hub de onde se chega
/// em qualquer operação do equipamento sem precisar olhar o display físico.
class EquipmentMenuPage extends ConsumerWidget {
  const EquipmentMenuPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final enabled = state.bleConnected && !state.demoMode;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Equipamento',
            subtitle: enabled
                ? 'Conectado a ${state.selectedDevice?.device.displayName ?? "-"}.'
                : (state.demoMode
                      ? 'Indisponivel em modo demonstracao.'
                      : 'Conecte via Bluetooth para operar o equipamento.'),
          ),
          const SizedBox(height: 16),
          _MenuTile(
            icon: Icons.tune,
            title: 'Configuracoes',
            subtitle: 'Modo de operacao, brilho, volume, canais, sobre',
            enabled: enabled,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ConfiguracoesPage()),
            ),
          ),
          const SizedBox(height: 12),
          _MenuTile(
            icon: Icons.science_outlined,
            title: 'Experimentos',
            subtitle:
                'Rodar experimento livre, teste de canais, arquivos, conexao',
            enabled: enabled,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ExperimentosPage()),
            ),
          ),
          const SizedBox(height: 12),
          _MenuTile(
            icon: Icons.query_stats,
            title: 'Analise de dados',
            subtitle: 'Selecionar arquivo, repeticao, eventos e distancia',
            enabled: enabled,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AnaliseDadosPage()),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        enabled: enabled,
        onTap: onTap,
        leading: Icon(icon, size: 32),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
