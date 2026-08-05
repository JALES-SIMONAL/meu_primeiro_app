import 'package:flutter/material.dart';

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
      appBar: AppBar(title: const Text('Resultado')),
      body: Center(
        child: Text(
          'dt=${deltaTS.toStringAsFixed(3)}s v=${velocidadeMs.toStringAsFixed(3)}m/s',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
