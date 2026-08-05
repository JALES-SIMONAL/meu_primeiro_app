import 'package:flutter/material.dart';

/// Logo oficial da Monkey Tech (assets/images/monkey_tech_logo.png,
/// gerado a partir de doc/monkey_tech_160x128.bmp).
class MonkeyTechLogo extends StatelessWidget {
  const MonkeyTechLogo({super.key, this.size = 96, this.showText = true});

  final double size;

  /// Mantido pela API existente; a logo já traz o texto "MONKEY TECH"
  /// desenhado na própria imagem, então aqui só controla o padding interno.
  final bool showText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(size * 0.25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(size * (showText ? 0.08 : 0.04)),
        child: Image.asset(
          'assets/images/monkey_tech_logo.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
