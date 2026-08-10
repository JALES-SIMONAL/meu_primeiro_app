import 'package:flutter_test/flutter_test.dart';
import 'package:meu_primeiro_app/widgets/chart_ticks.dart';

void main() {
  group('niceStep', () {
    test('rounds to 1/2/5 * 10^n', () {
      expect(niceStep(0.9), 1);
      expect(niceStep(1.4), 1);
      expect(niceStep(1.6), 2);
      expect(niceStep(2.9), 2);
      expect(niceStep(3.1), 5);
      expect(niceStep(6.9), 5);
      expect(niceStep(7.1), 10);
      expect(niceStep(0.019), closeTo(0.02, 1e-12));
    });

    test('handles non-positive/invalid input defensively', () {
      expect(niceStep(0), 1);
      expect(niceStep(-5), 1);
    });
  });

  group('niceTicks', () {
    test('covers the range with round, evenly-spaced values', () {
      final ticks = niceTicks(0, 9.3, targetCount: 5);

      expect(ticks.first, greaterThanOrEqualTo(0));
      expect(ticks.last, lessThanOrEqualTo(9.3 + 1e-9));
      for (var i = 1; i < ticks.length; i++) {
        expect(ticks[i] - ticks[i - 1], closeTo(ticks[1] - ticks[0], 1e-9));
      }
      // Densidade: item 8 pede mais marcacoes de referencia (varias, nao so
      // um min/max).
      expect(ticks.length, greaterThanOrEqualTo(4));
    });

    test('returns a single tick when min == max', () {
      expect(niceTicks(3, 3), [3]);
    });

    test('negative ranges work too', () {
      final ticks = niceTicks(-2.4, 3.1, targetCount: 5);
      expect(ticks, isNotEmpty);
      expect(ticks.first, greaterThanOrEqualTo(-2.4));
      expect(ticks.last, lessThanOrEqualTo(3.1 + 1e-9));
    });
  });
}
