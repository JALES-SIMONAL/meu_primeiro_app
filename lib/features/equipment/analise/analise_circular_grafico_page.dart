import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/circular_analysis_result.dart';
import '../../../providers/app_controller.dart';

/// Equivalente a maquina_estados::Tela::AnaliseCircularGrafico
/// (redesenharAnaliseCircularGrafico/ihm::desenharGrafico) — traça a série
/// escolhida em AnaliseCircularEscolherRepeticaoPage (valor x tempo).
class AnaliseCircularGraficoPage extends ConsumerWidget {
  const AnaliseCircularGraficoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pontos = ref.watch(
      appControllerProvider.select((s) => s.circularGraphPoints),
    );
    final titulo = ref.watch(
      appControllerProvider.select((s) => s.circularGraphTitle),
    );

    return Scaffold(
      appBar: AppBar(title: Text(titulo ?? 'Grafico')),
      body: pontos.isEmpty
          ? const Center(child: Text('Sem pontos suficientes para o grafico.'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: _LineChart(pontos: pontos),
            ),
    );
  }
}

class _LineChart extends StatelessWidget {
  const _LineChart({required this.pontos});

  final List<CircularPoint> pontos;

  @override
  Widget build(BuildContext context) {
    final valores = pontos.map((p) => p.value);
    final minValor = valores.reduce((a, b) => a < b ? a : b);
    final maxValor = valores.reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: CustomPaint(
            painter: _LineChartPainter(
              pontos: pontos,
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Container(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('min: ${minValor.toStringAsFixed(3)}'),
            Text('max: ${maxValor.toStringAsFixed(3)}'),
          ],
        ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({required this.pontos, required this.color});

  final List<CircularPoint> pontos;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final borda = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Offset.zero & size, borda);

    if (pontos.length < 2) return;

    final tempos = pontos.map((p) => p.timeS);
    final valores = pontos.map((p) => p.value);
    final minT = tempos.reduce((a, b) => a < b ? a : b);
    final maxT = tempos.reduce((a, b) => a > b ? a : b);
    final minV = valores.reduce((a, b) => a < b ? a : b);
    final maxV = valores.reduce((a, b) => a > b ? a : b);
    final rangeT = (maxT - minT) == 0 ? 1 : (maxT - minT);
    final rangeV = (maxV - minV) == 0 ? 1 : (maxV - minV);

    double dx(double t) => (t - minT) / rangeT * size.width;
    double dy(double v) => size.height - (v - minV) / rangeV * size.height;

    final path = Path()..moveTo(dx(pontos.first.timeS), dy(pontos.first.value));
    for (final ponto in pontos.skip(1)) {
      path.lineTo(dx(ponto.timeS), dy(ponto.value));
    }

    final linha = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, linha);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.pontos != pontos || oldDelegate.color != color;
}
