import 'package:flutter/material.dart';

import '../models/channel_edge_mode.dart';

/// Ícone do modo de disparo (borda) configurado para um canal.
///
/// "Borda de Subida" (L→H) e "Borda de Descida" (H→L) ganham um selo
/// geométrico próprio — quadrado colorido de cantos arredondados com um
/// degrau indicando a direção da transição — na mesma linguagem visual do
/// SignalLevelIcon (nível ao vivo), só que reaproveitado para expressar uma
/// transição em vez de um estado: Subida = vermelho (colorScheme.error),
/// Descida = amarelo-banana (colorScheme.tertiary, cor de destaque do
/// tema). "Ambos"/"Desabilitado" não são uma direção única, então usam um
/// ícone Material simples, sem selo colorido.
class EdgeModeIcon extends StatelessWidget {
  const EdgeModeIcon({super.key, required this.mode, this.size = 28});

  final ChannelEdgeMode mode;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return switch (mode) {
      ChannelEdgeMode.rising => _EdgeBadge(size: size, color: colorScheme.error, subindo: true),
      ChannelEdgeMode.falling => _EdgeBadge(size: size, color: colorScheme.tertiary, subindo: false),
      ChannelEdgeMode.both => Icon(Icons.swap_vert, size: size, color: colorScheme.onSurfaceVariant),
      ChannelEdgeMode.disabled => Icon(Icons.block, size: size, color: colorScheme.onSurfaceVariant),
    };
  }
}

class _EdgeBadge extends StatelessWidget {
  const _EdgeBadge({required this.size, required this.color, required this.subindo});

  final double size;
  final Color color;
  final bool subindo;

  @override
  Widget build(BuildContext context) {
    final onColor = ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(size * 0.28)),
      padding: EdgeInsets.all(size * 0.2),
      child: CustomPaint(painter: _StepPainter(subindo: subindo, color: onColor)),
    );
  }
}

/// Degrau de duas pernas (horizontal-vertical-horizontal) subindo ou
/// descendo — mesma leitura de um gráfico de transição digital.
class _StepPainter extends CustomPainter {
  const _StepPainter({required this.subindo, required this.color});

  final bool subindo;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.22
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final double top = 0;
    final double bottom = size.height;
    final double yInicio = subindo ? bottom : top;
    final double yFim = subindo ? top : bottom;

    final double x0 = 0;
    final double xMeio = size.width * 0.5;
    final double x1 = size.width;

    final path = Path()
      ..moveTo(x0, yInicio)
      ..lineTo(xMeio, yInicio)
      ..lineTo(xMeio, yFim)
      ..lineTo(x1, yFim);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _StepPainter oldDelegate) =>
      oldDelegate.subindo != subindo || oldDelegate.color != color;
}
