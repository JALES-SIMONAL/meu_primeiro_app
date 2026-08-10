import 'dart:math' as math;

import '../models/analysis_event.dart';
import '../models/circular_analysis_result.dart';

/// Porte para Dart de analise_circular.cpp (firmware): o equipamento não
/// expõe esse cálculo por BLE (só os eventos brutos de cada repetição, via
/// "load_repetition"/"analise_eventos"), então o app reproduz aqui a mesma
/// aritmética para obter o mesmo resultado que apareceria na tela física.
/// Qualquer mudança de fórmula lá precisa ser espelhada aqui.
class CircularAnalysisCalculator {
  const CircularAnalysisCalculator();

  /// Equivalente a analise_circular::calcular(). raioMetros é o raio do
  /// encoder; vaos é a quantidade de vãos (fendas) por volta — cada evento
  /// corresponde à passagem de um vão (arco percorrido = 2*pi*raio/vaos).
  /// Retorna null (equivalente ao "false" do firmware, que zera os
  /// resultados) se houver menos de 2 eventos ou vaos<=0.
  CircularCalcResult? calcular(
    List<AnalysisEvent> eventos, {
    required double raioMetros,
    required int vaos,
  }) {
    if (eventos.length < 2 || vaos <= 0) return null;

    final passoLinear = (2.0 * math.pi * raioMetros) / vaos;
    final tempoReferenciaUs = eventos.first.timestampUs.toDouble();

    final velocidade = <CircularPoint>[];
    final rpm = <CircularPoint>[];
    var distanciaTotal = 0.0;

    for (var i = 0; i + 1 < eventos.length; i++) {
      final tInicialUs = eventos[i].timestampUs;
      final tFinalUs = eventos[i + 1].timestampUs;
      final deltaTUs = tFinalUs - tInicialUs;
      if (deltaTUs <= 0) continue; // amostra fora de ordem/duplicada

      final deltaTS = deltaTUs / 1000000.0;
      final velocidadeMs = passoLinear / deltaTS;
      // (1/vaos) volta neste intervalo, convertida para voltas por minuto.
      final rpmValor = 60.0 / (vaos * deltaTS);
      final tempoMedioUs = (tInicialUs + tFinalUs) / 2.0;
      final tempoS = (tempoMedioUs - tempoReferenciaUs) / 1000000.0;

      velocidade.add(CircularPoint(tempoS, velocidadeMs));
      rpm.add(CircularPoint(tempoS, rpmValor));
      distanciaTotal += passoLinear;
    }

    final aceleracao = _derivarAceleracao(velocidade);

    return CircularCalcResult(
      distanciaMetros: distanciaTotal,
      velocidade: velocidade,
      aceleracao: aceleracao,
      rpm: rpm,
      velocidadeMediaMs: _media(velocidade.map((p) => p.value)),
      aceleracaoMediaMs2: _media(aceleracao.map((p) => p.value)),
      rpmMedia: _media(rpm.map((p) => p.value)),
    );
  }

  /// Equivalente a analise_circular::calcularMediaRepeticoes(): média
  /// aritmética simples dos quatro valores-resumo entre as repetições
  /// válidas (cada uma pesa igual, independente de quantos eventos teve).
  /// "porRepeticao" deve ter um item por repetição do arquivo (na ordem),
  /// com null para as que tiverem menos de 2 eventos (mesmo critério de
  /// calcular() acima).
  CircularAverageResult calcularMediaRepeticoes(
    List<CircularCalcResult?> porRepeticao,
  ) {
    final validas = porRepeticao.whereType<CircularCalcResult>().toList();
    if (validas.isEmpty) {
      return CircularAverageResult(
        distanciaMediaMetros: 0,
        velocidadeMediaMs: 0,
        aceleracaoMediaMs2: 0,
        rpmMedia: 0,
        repeticoesValidas: 0,
        repeticoesTotais: porRepeticao.length,
      );
    }

    var somaDist = 0.0;
    var somaVel = 0.0;
    var somaAcel = 0.0;
    var somaRpm = 0.0;
    for (final r in validas) {
      somaDist += r.distanciaMetros;
      somaVel += r.velocidadeMediaMs;
      somaAcel += r.aceleracaoMediaMs2;
      somaRpm += r.rpmMedia;
    }

    final n = validas.length;
    return CircularAverageResult(
      distanciaMediaMetros: somaDist / n,
      velocidadeMediaMs: somaVel / n,
      aceleracaoMediaMs2: somaAcel / n,
      rpmMedia: somaRpm / n,
      repeticoesValidas: n,
      repeticoesTotais: porRepeticao.length,
    );
  }

  /// Equivalente a analise_circular::calcularMediaGrafico(): curva média
  /// (velocidade/aceleração/RPM ponto a ponto) entre as repetições válidas,
  /// alinhada por ÍNDICE (não por tempo) e truncada no menor número de
  /// pontos entre elas — assume que todas partem do mesmo ponto físico do
  /// encoder, então o ponto i de cada repetição corresponde ao mesmo vão.
  /// Retorna null se nenhuma repetição tiver ao menos 2 eventos.
  CircularCalcResult? calcularMediaGrafico(
    List<CircularCalcResult?> porRepeticao, {
    required double raioMetros,
    required int vaos,
  }) {
    final validas = porRepeticao.whereType<CircularCalcResult>().toList();
    if (validas.isEmpty) return null;

    final minPontos = validas
        .map((r) => r.velocidade.length)
        .reduce(math.min);
    if (minPontos == 0) return null;

    final somaTempo = List<double>.filled(minPontos, 0);
    final somaVel = List<double>.filled(minPontos, 0);
    final somaRpm = List<double>.filled(minPontos, 0);
    for (final r in validas) {
      for (var i = 0; i < minPontos; i++) {
        somaTempo[i] += r.velocidade[i].timeS;
        somaVel[i] += r.velocidade[i].value;
        somaRpm[i] += r.rpm[i].value;
      }
    }

    final n = validas.length;
    final velocidade = [
      for (var i = 0; i < minPontos; i++)
        CircularPoint(somaTempo[i] / n, somaVel[i] / n),
    ];
    final rpm = [
      for (var i = 0; i < minPontos; i++)
        CircularPoint(somaTempo[i] / n, somaRpm[i] / n),
    ];
    final aceleracao = _derivarAceleracao(velocidade);

    // Distância de UM ponto (arco de um vão) não depende da repetição, só de
    // raio/vaos — multiplica pela quantidade de pontos médios, igual
    // calcular() faria para uma única repetição com o mesmo tamanho.
    final passoLinear = (2.0 * math.pi * raioMetros) / vaos;
    final distanciaTotal = passoLinear * minPontos;

    return CircularCalcResult(
      distanciaMetros: distanciaTotal,
      velocidade: velocidade,
      aceleracao: aceleracao,
      rpm: rpm,
      velocidadeMediaMs: _media(velocidade.map((p) => p.value)),
      aceleracaoMediaMs2: _media(aceleracao.map((p) => p.value)),
      rpmMedia: _media(rpm.map((p) => p.value)),
    );
  }

  /// Deriva aceleração a partir de pontos de velocidade consecutivos
  /// (derivada discreta) — mesma lógica de analise_circular.cpp::derivarAceleracao().
  List<CircularPoint> _derivarAceleracao(List<CircularPoint> velocidade) {
    final aceleracao = <CircularPoint>[];
    for (var i = 0; i + 1 < velocidade.length; i++) {
      final deltaT = velocidade[i + 1].timeS - velocidade[i].timeS;
      if (deltaT <= 0.0) continue;
      aceleracao.add(
        CircularPoint(
          (velocidade[i].timeS + velocidade[i + 1].timeS) / 2.0,
          (velocidade[i + 1].value - velocidade[i].value) / deltaT,
        ),
      );
    }
    return aceleracao;
  }

  double _media(Iterable<double> valores) {
    if (valores.isEmpty) return 0.0;
    return valores.reduce((a, b) => a + b) / valores.length;
  }
}
