import 'package:flutter/material.dart';

/// Cores-semente extraídas do logo (assets/images/monkey_tech_logo.png):
/// ciano/teal do corpo do macaco, azul-marinho dos contornos/orelhas e
/// amarelo-banana de destaque. Alimentam ColorScheme.fromSeed em
/// app_theme.dart — MD3 gera toda a escala tonal (containers, outlines,
/// superfícies) e o par light/dark a partir dessas três cores, garantindo
/// contraste consistente em vez de tons escolhidos um a um à mão.
class AppColors {
  AppColors._();

  static const Color primarySeed = Color(0xFF04BBD3);
  static const Color secondarySeed = Color(0xFF1B3A6B);
  static const Color tertiarySeed = Color(0xFFF2A61C);

  /// Verde do selo de nível lógico "H" (SignalLevelIcon, Teste de canais).
  /// Não existe um papel "verde" nativo no ColorScheme MD3 — por isso é uma
  /// constante fixa, em vez de um token do tema — enquanto o nível "L"
  /// reaproveita colorScheme.error (vermelho), que já é o próprio
  /// AppColors.errorSeed usado para gerar o tema.
  static const Color levelHigh = Color(0xFF2E7D32);

  static const Color errorSeed = Color(0xFFB3261E);
}
