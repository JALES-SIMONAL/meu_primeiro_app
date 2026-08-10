import 'dart:math' as math;

/// Escolhe um passo "redondo" (1/2/5 * 10^n) para marcações de eixo,
/// aproximando o passo bruto pedido — mesma heuristica classica de bibliotecas
/// de grafico ("nice numbers"), pra nao gerar rotulos tipo "0.137, 0.274".
double niceStep(double roughStep) {
  if (roughStep <= 0 || !roughStep.isFinite) return 1;

  final exponent = (math.log(roughStep) / math.ln10).floor();
  final magnitude = math.pow(10, exponent).toDouble();
  final residual = roughStep / magnitude;

  final double niceResidual;
  if (residual < 1.5) {
    niceResidual = 1;
  } else if (residual < 3) {
    niceResidual = 2;
  } else if (residual < 7) {
    niceResidual = 5;
  } else {
    niceResidual = 10;
  }
  return niceResidual * magnitude;
}

/// Gera marcações de eixo cobrindo [min, max] com espacamento "redondo",
/// mirando aproximadamente `targetCount` marcações (pode gerar uma a mais ou
/// a menos dependendo de onde min/max caem). min==max devolve so [min].
List<double> niceTicks(double min, double max, {int targetCount = 5}) {
  if (max <= min) return [min];

  final step = niceStep((max - min) / targetCount);
  final start = (min / step).ceil() * step;

  final ticks = <double>[];
  for (var v = start; v <= max + step * 1e-9; v += step) {
    ticks.add(double.parse(v.toStringAsFixed(10)));
  }
  return ticks;
}
