import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:meu_primeiro_app/models/analysis_event.dart';
import 'package:meu_primeiro_app/services/circular_analysis_calculator.dart';

AnalysisEvent _ev(int tempoUs) =>
    AnalysisEvent(channel: 1, state: 'H', timestampUs: tempoUs);

void main() {
  final calc = CircularAnalysisCalculator();

  group('calcular (porte de analise_circular::calcular)', () {
    test('returns null with fewer than 2 events', () {
      expect(calc.calcular([_ev(0)], raioMetros: 0.1, vaos: 4), isNull);
      expect(calc.calcular([], raioMetros: 0.1, vaos: 4), isNull);
    });

    test('returns null when vaos <= 0', () {
      expect(
        calc.calcular([_ev(0), _ev(100000)], raioMetros: 0.1, vaos: 0),
        isNull,
      );
    });

    test('constant-speed events replicate analise_circular.cpp arithmetic', () {
      // 5 eventos a 100ms de intervalo -> velocidade/rpm constantes, mesma
      // fórmula de analise_circular.cpp::calcular(): passoLinear =
      // 2*pi*raio/vaos; velocidade = passoLinear/deltaTs; rpm = 60/(vaos*deltaTs).
      const raioMetros = 0.1;
      const vaos = 4;
      final eventos = [
        _ev(0),
        _ev(100000),
        _ev(200000),
        _ev(300000),
        _ev(400000),
      ];

      final resultado = calc.calcular(
        eventos,
        raioMetros: raioMetros,
        vaos: vaos,
      );

      expect(resultado, isNotNull);
      final passoLinear = (2 * math.pi * raioMetros) / vaos;
      final velocidadeEsperada = passoLinear / 0.1;
      final rpmEsperado = 60.0 / (vaos * 0.1);

      expect(resultado!.velocidade, hasLength(4));
      expect(resultado.rpm, hasLength(4));
      for (final p in resultado.velocidade) {
        expect(p.value, closeTo(velocidadeEsperada, 1e-9));
      }
      for (final p in resultado.rpm) {
        expect(p.value, closeTo(rpmEsperado, 1e-9));
      }
      // Tempos médios de cada intervalo, relativos ao primeiro evento.
      expect(
        resultado.velocidade.map((p) => p.timeS).toList(),
        [0.05, 0.15, 0.25, 0.35].map((v) => closeTo(v, 1e-9)).toList(),
      );

      // Velocidade constante -> aceleração ~0 em todos os pontos.
      expect(resultado.aceleracao, hasLength(3));
      for (final p in resultado.aceleracao) {
        expect(p.value, closeTo(0.0, 1e-9));
      }

      expect(resultado.distanciaMetros, closeTo(passoLinear * 4, 1e-9));
      expect(resultado.velocidadeMediaMs, closeTo(velocidadeEsperada, 1e-9));
      expect(resultado.rpmMedia, closeTo(rpmEsperado, 1e-9));
      expect(resultado.aceleracaoMediaMs2, closeTo(0.0, 1e-9));
    });

    test('skips out-of-order/duplicate timestamps (deltaTUs <= 0)', () {
      // Terceiro evento "volta no tempo": o intervalo [1]->[2] deve ser
      // descartado, igual ao firmware ("amostra fora de ordem/duplicada").
      final eventos = [_ev(0), _ev(100000), _ev(50000), _ev(250000)];

      final resultado = calc.calcular(eventos, raioMetros: 0.1, vaos: 4);

      expect(resultado, isNotNull);
      // 3 intervalos possíveis, 1 descartado -> 2 pontos de velocidade.
      expect(resultado!.velocidade, hasLength(2));
    });
  });

  group('calcularMediaRepeticoes', () {
    test('averages only valid repetitions, ignoring null ones', () {
      final rep = calc.calcular(
        [_ev(0), _ev(100000), _ev(200000)],
        raioMetros: 0.1,
        vaos: 4,
      )!;

      final media = calc.calcularMediaRepeticoes([rep, rep, null]);

      expect(media.repeticoesValidas, 2);
      expect(media.repeticoesTotais, 3);
      expect(media.distanciaMediaMetros, closeTo(rep.distanciaMetros, 1e-9));
      expect(media.velocidadeMediaMs, closeTo(rep.velocidadeMediaMs, 1e-9));
      expect(media.rpmMedia, closeTo(rep.rpmMedia, 1e-9));
    });

    test('returns zeroed result when there are no valid repetitions', () {
      final media = calc.calcularMediaRepeticoes([null, null]);

      expect(media.repeticoesValidas, 0);
      expect(media.repeticoesTotais, 2);
      expect(media.distanciaMediaMetros, 0);
      expect(media.velocidadeMediaMs, 0);
    });
  });

  group('calcularMediaGrafico', () {
    test('averages point-by-point, truncated to the shortest repetition', () {
      // Rep A: 3 pontos de velocidade (4 eventos); Rep B: 1 ponto (2 eventos).
      final repA = calc.calcular(
        [_ev(0), _ev(100000), _ev(200000), _ev(300000)],
        raioMetros: 0.1,
        vaos: 4,
      )!;
      final repB = calc.calcular(
        [_ev(0), _ev(100000)],
        raioMetros: 0.1,
        vaos: 4,
      )!;
      expect(repA.velocidade, hasLength(3));
      expect(repB.velocidade, hasLength(1));

      final media = calc.calcularMediaGrafico(
        [repA, repB],
        raioMetros: 0.1,
        vaos: 4,
      );

      expect(media, isNotNull);
      expect(media!.velocidade, hasLength(1));
      expect(
        media.velocidade.first.value,
        closeTo(
          (repA.velocidade[0].value + repB.velocidade[0].value) / 2,
          1e-9,
        ),
      );
    });

    test('returns null when there are no valid repetitions', () {
      expect(
        calc.calcularMediaGrafico([null, null], raioMetros: 0.1, vaos: 4),
        isNull,
      );
    });
  });
}
