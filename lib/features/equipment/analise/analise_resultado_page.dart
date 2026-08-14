import 'package:flutter/material.dart';

import '../../../core/l10n/app_localizations.dart';

/// Equivalente a maquina_estados::Tela::AnaliseResultado — delta_t e
/// velocidade calculados localmente (ver AppController.computeAnalysisResult).
class AnaliseResultadoPage extends StatelessWidget {
  const AnaliseResultadoPage({
    super.key,
    required this.deltaTUs,
    required this.velocidadeMs,
  });

  final int deltaTUs;
  final double velocidadeMs;

  @override
  Widget build(BuildContext context) {
    final deltaTS = deltaTUs / 1000000.0;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('analysisResult.title'))),
      body: Center(
        child: Text(
          context.tr(
            'analysisResult.summary',
            params: {
              'dt': deltaTS.toStringAsFixed(3),
              'v': velocidadeMs.toStringAsFixed(3),
            },
          ),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
