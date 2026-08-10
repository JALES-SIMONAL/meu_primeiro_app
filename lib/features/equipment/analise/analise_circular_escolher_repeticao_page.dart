import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_controller.dart';
import '../../../widgets/bordered_list_tile.dart';
import 'analise_circular_grafico_page.dart';

/// Equivalente a maquina_estados::Tela::AnaliseCircularEscolherRepeticao:
/// escolhe de qual repetição vem a curva do gráfico "kind" já escolhido na
/// tela de resultado — uma repetição específica, ou "Media" (curva média
/// entre repetições, alinhada por índice — ver
/// CircularAnalysisCalculator.calcularMediaGrafico).
class AnaliseCircularEscolherRepeticaoPage extends ConsumerWidget {
  const AnaliseCircularEscolherRepeticaoPage({
    super.key,
    required this.arquivo,
    required this.kind,
  });

  final String arquivo;
  final String kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(
      appControllerProvider.select((s) => s.circularPerRepetitionResults.length),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Qual repeticao?')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (var i = 0; i < total; i++)
            BorderedListTile(
              title: Text('Rep ${i + 1}'),
              onTap: () => _abrir(context, ref, i),
            ),
          BorderedListTile(
            leading: const Icon(Icons.functions),
            title: const Text('Media'),
            onTap: () => _abrir(context, ref, null),
          ),
        ],
      ),
    );
  }

  void _abrir(BuildContext context, WidgetRef ref, int? repeticaoIndice) {
    ref
        .read(appControllerProvider.notifier)
        .loadCircularGraph(kind: kind, repeticaoIndice: repeticaoIndice);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AnaliseCircularGraficoPage()),
    );
  }
}
