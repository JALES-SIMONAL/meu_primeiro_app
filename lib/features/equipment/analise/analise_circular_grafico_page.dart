import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/circular_analysis_result.dart';
import '../../../providers/app_controller.dart';
import '../../../widgets/chart_ticks.dart';

/// Equivalente a maquina_estados::Tela::AnaliseCircularGrafico
/// (redesenharAnaliseCircularGrafico/ihm::desenharGrafico) — traça a série
/// escolhida em AnaliseCircularEscolherRepeticaoPage (valor x tempo), com
/// marcações densas nos dois eixos e zoom/pan/toque para valor exato (sem
/// equivalente na tela física, só encoder/botões).
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
              child: _InteractiveLineChart(pontos: pontos),
            ),
    );
  }
}

/// Margem reservada para os rotulos dos eixos ao redor da area de plotagem —
/// compartilhada entre o estado (hit-testing dos gestos) e o painter (desenho),
/// pra nunca ficarem dessincronizados.
const double _kLeftAxisWidth = 56;
const double _kBottomAxisHeight = 24;

/// Mapeamento linear tempo/valor <-> pixel para uma janela visivel
/// (viewport) DENTRO da area de plotagem (ja descontada a margem dos eixos).
class _ChartTransform {
  _ChartTransform({
    required this.minT,
    required this.maxT,
    required this.minV,
    required this.maxV,
    required this.plotSize,
  });

  final double minT;
  final double maxT;
  final double minV;
  final double maxV;
  final Size plotSize;

  double get _rangeT => (maxT - minT) == 0 ? 1 : (maxT - minT);
  double get _rangeV => (maxV - minV) == 0 ? 1 : (maxV - minV);

  double xOf(double t) => (t - minT) / _rangeT * plotSize.width;
  double yOf(double v) =>
      plotSize.height - (v - minV) / _rangeV * plotSize.height;
  double timeOfPlotX(double plotX) => minT + (plotX / plotSize.width) * _rangeT;
}

class _InteractiveLineChart extends StatefulWidget {
  const _InteractiveLineChart({required this.pontos});

  final List<CircularPoint> pontos;

  @override
  State<_InteractiveLineChart> createState() => _InteractiveLineChartState();
}

class _InteractiveLineChartState extends State<_InteractiveLineChart> {
  static const _maxZoom = 12.0;

  late double _fullMinT;
  late double _fullMaxT;
  late double _viewMinT;
  late double _viewMaxT;

  double? _baseRange;
  CircularPoint? _selected;

  @override
  void initState() {
    super.initState();
    _resetView();
  }

  @override
  void didUpdateWidget(covariant _InteractiveLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pontos != widget.pontos) _resetView();
  }

  void _resetView() {
    final tempos = widget.pontos.map((p) => p.timeS);
    _fullMinT = tempos.reduce((a, b) => a < b ? a : b);
    _fullMaxT = tempos.reduce((a, b) => a > b ? a : b);
    if (_fullMaxT <= _fullMinT) _fullMaxT = _fullMinT + 1;
    _viewMinT = _fullMinT;
    _viewMaxT = _fullMaxT;
    _selected = null;
  }

  double get _fullRange => _fullMaxT - _fullMinT;
  double get _minRange => _fullRange / _maxZoom;

  void _clampView() {
    var range = _viewMaxT - _viewMinT;
    if (range > _fullRange) range = _fullRange;
    if (range < _minRange) range = _minRange;

    if (_viewMinT < _fullMinT) {
      _viewMinT = _fullMinT;
      _viewMaxT = _viewMinT + range;
    }
    if (_viewMaxT > _fullMaxT) {
      _viewMaxT = _fullMaxT;
      _viewMinT = _viewMaxT - range;
    }
  }

  void _zoom(double factor) {
    setState(() {
      final center = (_viewMinT + _viewMaxT) / 2;
      var range = (_viewMaxT - _viewMinT) / factor;
      range = range.clamp(_minRange, _fullRange);
      _viewMinT = center - range / 2;
      _viewMaxT = center + range / 2;
      _clampView();
    });
  }

  void _onScaleStart(ScaleStartDetails details) {
    _baseRange = _viewMaxT - _viewMinT;
  }

  void _onScaleUpdate(ScaleUpdateDetails details, double plotWidth) {
    setState(() {
      final currentRange = _viewMaxT - _viewMinT;
      final dtPan = -details.focalPointDelta.dx / plotWidth * currentRange;
      _viewMinT += dtPan;
      _viewMaxT += dtPan;

      if (details.scale != 1.0 && _baseRange != null) {
        final center = (_viewMinT + _viewMaxT) / 2;
        var range = _baseRange! / details.scale;
        range = range.clamp(_minRange, _fullRange);
        _viewMinT = center - range / 2;
        _viewMaxT = center + range / 2;
      }

      _clampView();
    });
  }

  List<CircularPoint> _visiblePoints() {
    final visible = widget.pontos
        .where((p) => p.timeS >= _viewMinT && p.timeS <= _viewMaxT)
        .toList();
    return visible.isEmpty ? widget.pontos : visible;
  }

  void _onTapUp(TapUpDetails details, _ChartTransform transform) {
    final plotX = details.localPosition.dx - _kLeftAxisWidth;
    final t = transform.timeOfPlotX(plotX);

    CircularPoint? nearest;
    var bestDelta = double.infinity;
    for (final p in widget.pontos) {
      final delta = (p.timeS - t).abs();
      if (delta < bestDelta) {
        bestDelta = delta;
        nearest = p;
      }
    }
    setState(() => _selected = nearest);
  }

  @override
  Widget build(BuildContext context) {
    final visiveis = _visiblePoints();
    final valores = visiveis.map((p) => p.value);
    final minV = valores.reduce((a, b) => a < b ? a : b);
    final maxV = valores.reduce((a, b) => a > b ? a : b);
    final zoomedIn = (_viewMaxT - _viewMinT) < _fullRange - 1e-9;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _selected == null
                    ? 'Toque no grafico para ver um valor exato. Arraste/belisque para navegar e dar zoom.'
                    : 't=${_selected!.timeS.toStringAsFixed(3)}s  valor=${_selected!.value.toStringAsFixed(4)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            IconButton(
              tooltip: 'Diminuir zoom',
              icon: const Icon(Icons.zoom_out),
              onPressed: () => _zoom(0.5),
            ),
            IconButton(
              tooltip: 'Aumentar zoom',
              icon: const Icon(Icons.zoom_in),
              onPressed: () => _zoom(2),
            ),
            IconButton(
              tooltip: 'Resetar zoom',
              icon: const Icon(Icons.restart_alt),
              onPressed: zoomedIn ? () => setState(_resetView) : null,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final plotSize = Size(
                (constraints.maxWidth - _kLeftAxisWidth).clamp(
                  1,
                  double.infinity,
                ),
                (constraints.maxHeight - _kBottomAxisHeight).clamp(
                  1,
                  double.infinity,
                ),
              );
              final transform = _ChartTransform(
                minT: _viewMinT,
                maxT: _viewMaxT,
                minV: minV,
                maxV: maxV,
                plotSize: plotSize,
              );
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: _onScaleStart,
                onScaleUpdate: (d) => _onScaleUpdate(d, plotSize.width),
                onTapUp: (d) => _onTapUp(d, transform),
                child: CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _LineChartPainter(
                    pontos: widget.pontos,
                    transform: transform,
                    selected: _selected,
                    lineColor: Theme.of(context).colorScheme.primary,
                    gridColor: Theme.of(context).colorScheme.outlineVariant,
                    textStyle: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.pontos,
    required this.transform,
    required this.selected,
    required this.lineColor,
    required this.gridColor,
    required this.textStyle,
  });

  final List<CircularPoint> pontos;
  final _ChartTransform transform;
  final CircularPoint? selected;
  final Color lineColor;
  final Color gridColor;
  final TextStyle? textStyle;

  @override
  void paint(Canvas canvas, Size fullSize) {
    canvas.save();
    canvas.translate(_kLeftAxisWidth, 0);
    _paintGridAndAxes(canvas, transform);
    _paintLine(canvas, transform);
    if (selected != null) _paintSelection(canvas, transform);
    canvas.restore();
  }

  void _paintGridAndAxes(Canvas canvas, _ChartTransform t) {
    final size = t.plotSize;
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    final borderPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Offset.zero & size, borderPaint);

    for (final v in niceTicks(t.minV, t.maxV, targetCount: 6)) {
      final y = t.yOf(v).clamp(0, size.height).toDouble();
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      _drawText(
        canvas,
        v.toStringAsFixed(_decimalsFor(t.maxV - t.minV)),
        Offset(-_kLeftAxisWidth + 4, y - 7),
        width: _kLeftAxisWidth - 8,
      );
    }

    for (final tempo in niceTicks(t.minT, t.maxT, targetCount: 6)) {
      final x = t.xOf(tempo).clamp(0, size.width).toDouble();
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      _drawText(
        canvas,
        '${tempo.toStringAsFixed(_decimalsFor(t.maxT - t.minT))}s',
        Offset(x - 20, size.height + 4),
        width: 40,
        align: TextAlign.center,
      );
    }
  }

  int _decimalsFor(double range) {
    if (range <= 0) return 2;
    if (range < 1) return 3;
    if (range < 10) return 2;
    if (range < 100) return 1;
    return 0;
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    required double width,
    TextAlign align = TextAlign.right,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width);
    painter.paint(canvas, offset);
  }

  void _paintLine(Canvas canvas, _ChartTransform t) {
    if (pontos.length < 2) return;

    final path = Path()
      ..moveTo(t.xOf(pontos.first.timeS), t.yOf(pontos.first.value));
    for (final ponto in pontos.skip(1)) {
      path.lineTo(t.xOf(ponto.timeS), t.yOf(ponto.value));
    }

    canvas.save();
    canvas.clipRect(Offset.zero & t.plotSize);
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
    canvas.restore();
  }

  void _paintSelection(Canvas canvas, _ChartTransform t) {
    final p = selected!;
    final x = t.xOf(p.timeS);
    final y = t.yOf(p.value);
    final size = t.plotSize;

    final guidePaint = Paint()
      ..color = lineColor.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), guidePaint);

    canvas.drawCircle(Offset(x, y), 5, Paint()..color = lineColor);
    canvas.drawCircle(
      Offset(x, y),
      5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.pontos != pontos ||
      oldDelegate.transform.minT != transform.minT ||
      oldDelegate.transform.maxT != transform.maxT ||
      oldDelegate.transform.minV != transform.minV ||
      oldDelegate.transform.maxV != transform.maxV ||
      oldDelegate.transform.plotSize != transform.plotSize ||
      oldDelegate.selected != selected;
}
