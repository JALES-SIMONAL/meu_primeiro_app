/// Um ponto de uma série temporal (velocidade/aceleração/RPM) do módulo de
/// análise de movimento circular — equivalente a um par (temposX[i], valores[i])
/// de analise_circular.cpp.
class CircularPoint {
  final double timeS;
  final double value;

  const CircularPoint(this.timeS, this.value);
}

/// Resultado de analise_circular::calcular() (ou ::calcularMediaGrafico())
/// para UMA repetição (ou para a curva média entre repetições, alinhada por
/// índice) — distância percorrida e as três séries por-evento, já com as
/// médias simples de cada uma.
class CircularCalcResult {
  final double distanciaMetros;
  final List<CircularPoint> velocidade;
  final List<CircularPoint> aceleracao;
  final List<CircularPoint> rpm;
  final double velocidadeMediaMs;
  final double aceleracaoMediaMs2;
  final double rpmMedia;

  const CircularCalcResult({
    required this.distanciaMetros,
    required this.velocidade,
    required this.aceleracao,
    required this.rpm,
    required this.velocidadeMediaMs,
    required this.aceleracaoMediaMs2,
    required this.rpmMedia,
  });
}

/// Resultado de analise_circular::calcularMediaRepeticoes() — média simples
/// dos quatro valores-resumo entre as repetições válidas (>=2 eventos) de um
/// arquivo, exibida na tela "Resultado" da análise circular.
class CircularAverageResult {
  final double distanciaMediaMetros;
  final double velocidadeMediaMs;
  final double aceleracaoMediaMs2;
  final double rpmMedia;
  final int repeticoesValidas;
  final int repeticoesTotais;

  const CircularAverageResult({
    required this.distanciaMediaMetros,
    required this.velocidadeMediaMs,
    required this.aceleracaoMediaMs2,
    required this.rpmMedia,
    required this.repeticoesValidas,
    required this.repeticoesTotais,
  });

  static const zero = CircularAverageResult(
    distanciaMediaMetros: 0,
    velocidadeMediaMs: 0,
    aceleracaoMediaMs2: 0,
    rpmMedia: 0,
    repeticoesValidas: 0,
    repeticoesTotais: 0,
  );
}
