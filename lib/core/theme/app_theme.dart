import 'package:flutter/material.dart';

class AppTheme {
  static const Color black = Color(0xFF000000);
  static const Color cyan = Color(0xFF04BBD3);
  static const Color white = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF2E7D32);
  static const Color danger = Color(0xFFC62828);
  static const Color neutral = Color(0xFF7A7A7A);
  static const Color warning = Color(0xFFF9A825);
  static const Color background = Color(0xFFF5F7F8);

  static ThemeData light() {
    final colorScheme = const ColorScheme(
      brightness: Brightness.light,
      primary: black,
      onPrimary: white,
      secondary: cyan,
      onSecondary: black,
      error: danger,
      onError: white,
      surface: white,
      onSurface: black,
      primaryContainer: Color(0xFFE6F9FB),
      onPrimaryContainer: black,
      secondaryContainer: Color(0xFFD8FBFF),
      onSecondaryContainer: black,
      tertiary: success,
      onTertiary: white,
      tertiaryContainer: Color(0xFFE2F2E3),
      onTertiaryContainer: black,
      outline: Color(0xFFCAD1D5),
      surfaceContainerHighest: Color(0xFFECEFF1),
      surfaceTint: cyan,
      scrim: Color(0x66000000),
      inverseSurface: black,
      onInverseSurface: white,
      inversePrimary: cyan,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: black,
        foregroundColor: white,
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        color: white,
        surfaceTintColor: white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: white,
        selectedIconTheme: IconThemeData(color: cyan),
        selectedLabelTextStyle: TextStyle(
          color: black,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFCAD1D5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: cyan, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: black,
          foregroundColor: white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF0F3F5),
        labelStyle: const TextStyle(color: black),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: black,
        ),
        headlineMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: black,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: black,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: black,
        ),
        bodyLarge: TextStyle(fontSize: 15, color: black),
        bodyMedium: TextStyle(fontSize: 14, color: black),
      ),
    );
  }
}
