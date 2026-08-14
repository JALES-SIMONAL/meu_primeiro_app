import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Selo do nível lógico ao vivo de um canal: quadrado com cantos
/// arredondados, com a letra "H" (alto) ou "L" (baixo) centralizada —
/// High = verde (AppColors.levelHigh), Low = vermelho (colorScheme.error).
/// A letra nunca é opcional: a cor sozinha nunca é o portador de
/// significado (protanopia/deuteranopia não distinguem só pela matiz).
class SignalLevelIcon extends StatelessWidget {
  const SignalLevelIcon({super.key, required this.high, this.size = 28});

  /// true = nível alto ("H", verde). false = nível baixo ("L", vermelho).
  final bool high;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = high ? AppColors.levelHigh : Theme.of(context).colorScheme.error;

    return Semantics(
      label: high ? 'Nível alto (H)' : 'Nível baixo (L)',
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(size * 0.28),
        ),
        child: Text(
          high ? 'H' : 'L',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.52,
            height: 1,
          ),
        ),
      ),
    );
  }
}
