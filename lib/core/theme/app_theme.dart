import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tema MD3 (Material Design 3) gerado a partir das cores-semente do logo
/// (ver app_colors.dart). `ColorScheme.fromSeed` já entrega uma escala
/// tonal completa e acessível (containers, outlines, superfícies, par
/// light/dark) a partir do ciano do logo; os papéis secondary/tertiary são
/// ajustados por cima para refletir o azul-marinho e o amarelo-banana do
/// logo, mantendo a relação de contraste gerada pelo MD3.
class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;

    final ColorScheme base = ColorScheme.fromSeed(
      seedColor: AppColors.primarySeed,
      brightness: brightness,
    );

    final ColorScheme colorScheme = base.copyWith(
      secondary: AppColors.secondarySeed,
      onSecondary: Colors.white,
      secondaryContainer: Color.lerp(
        AppColors.secondarySeed,
        isDark ? Colors.black : Colors.white,
        isDark ? 0.6 : 0.85,
      ),
      onSecondaryContainer: isDark ? Colors.white : AppColors.secondarySeed,
      tertiary: AppColors.tertiarySeed,
      onTertiary: Colors.black,
      tertiaryContainer: Color.lerp(
        AppColors.tertiarySeed,
        isDark ? Colors.black : Colors.white,
        isDark ? 0.6 : 0.85,
      ),
      onTertiaryContainer: isDark ? Colors.white : const Color(0xFF5C3D00),
      // O nível "L" (SignalLevelIcon) e a "Borda de Subida" (EdgeModeIcon)
      // reaproveitam este vermelho; a "Borda de Descida" reaproveita
      // tertiary (amarelo-banana) acima.
      error: AppColors.errorSeed,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerHighest,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        selectedLabelTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.secondaryContainer,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          side: BorderSide(color: colorScheme.outline),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        labelStyle: TextStyle(color: colorScheme.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      textTheme: Typography.material2021(platform: TargetPlatform.android)
          .englishLike
          .merge(Typography.material2021(platform: TargetPlatform.android).black)
          .apply(bodyColor: colorScheme.onSurface, displayColor: colorScheme.onSurface),
    );
  }
}
