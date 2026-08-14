import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../models/circular_analysis_result.dart';
import '../../../providers/app_controller.dart';
import '../../../widgets/bordered_list_tile.dart';
import 'analise_circular_escolher_repeticao_page.dart';

/// Equivalente a maquina_estados::Tela::AnaliseCircularResultado
/// (redesenharAnaliseCircularResultado): valores-resumo são a média entre
/// TODAS as repetições válidas do arquivo (analise_circular::calcularMediaRepeticoes(),
/// já rodada em AnaliseCircularRaioVaosPage.Calcular).
class AnaliseCircularResultadoPage extends ConsumerWidget {
  const AnaliseCircularResultadoPage({super.key, required this.arquivo});

  final String arquivo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultado = ref.watch(
      appControllerProvider.select((s) => s.circularAverageResult),
    );
    final r = resultado ?? CircularAverageResult.zero;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('circularResult.title'))),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _InfoTile(
            context.tr('circularResult.distance'),
            '${r.distanciaMediaMetros.toStringAsFixed(3)}m',
          ),
          _InfoTile(
            context.tr('circularResult.repetitions'),
            '${r.repeticoesValidas}/${r.repeticoesTotais}',
          ),
          _InfoTile(
            context.tr('circularResult.avgSpeed'),
            '${r.velocidadeMediaMs.toStringAsFixed(2)}m/s',
          ),
          _InfoTile(
            context.tr('circularResult.avgAccel'),
            '${r.aceleracaoMediaMs2.toStringAsFixed(2)}m/s2',
          ),
          _InfoTile(context.tr('circularResult.avgRpm'), r.rpmMedia.toStringAsFixed(1)),
          const Divider(height: 24),
          BorderedListTile(
            leading: const Icon(Icons.show_chart),
            title: Text(context.tr('circularResult.viewSpeedChart')),
            onTap: () => _abrirGrafico(context, 'velocidade'),
          ),
          BorderedListTile(
            leading: const Icon(Icons.show_chart),
            title: Text(context.tr('circularResult.viewAccelChart')),
            onTap: () => _abrirGrafico(context, 'aceleracao'),
          ),
          BorderedListTile(
            leading: const Icon(Icons.show_chart),
            title: Text(context.tr('circularResult.viewRpmChart')),
            onTap: () => _abrirGrafico(context, 'rpm'),
          ),
        ],
      ),
    );
  }

  void _abrirGrafico(BuildContext context, String kind) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            AnaliseCircularEscolherRepeticaoPage(arquivo: arquivo, kind: kind),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(label),
        trailing: Text(value, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}
