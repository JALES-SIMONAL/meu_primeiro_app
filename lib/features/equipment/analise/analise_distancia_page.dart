import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/analysis_event.dart';
import '../../../providers/app_controller.dart';
import 'analise_resultado_page.dart';

/// Equivalente a maquina_estados::Tela::AnaliseDistancia.
class AnaliseDistanciaPage extends ConsumerStatefulWidget {
  const AnaliseDistanciaPage({
    super.key,
    required this.inicio,
    required this.fim,
  });

  final AnalysisEvent inicio;
  final AnalysisEvent fim;

  @override
  ConsumerState<AnaliseDistanciaPage> createState() =>
      _AnaliseDistanciaPageState();
}

class _AnaliseDistanciaPageState extends ConsumerState<AnaliseDistanciaPage> {
  int _distanciaCm = 100;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Distancia')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _distanciaCm > 1
                      ? () => setState(() => _distanciaCm--)
                      : null,
                ),
                Text(
                  '$_distanciaCm cm',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _distanciaCm < 2000
                      ? () => setState(() => _distanciaCm++)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final resultado = ref
                    .read(appControllerProvider.notifier)
                    .computeAnalysisResult(
                      widget.inicio,
                      widget.fim,
                      _distanciaCm.toDouble(),
                    );
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AnaliseResultadoPage(
                      deltaTUs: resultado.deltaTUs,
                      velocidadeMs: resultado.velocidadeMs,
                    ),
                  ),
                );
              },
              child: const Text('Calcular'),
            ),
          ],
        ),
      ),
    );
  }
}
