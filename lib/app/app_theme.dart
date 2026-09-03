import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const _ink = Color(0xFF14213D);
  static const _green = Color(0xFF168B68);
  static const _paper = Color(0xFFF5F7F6);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _green,
      brightness: Brightness.light,
      primary: _green,
      surface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _paper,
      fontFamily: 'Arial',
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontWeight: FontWeight.w800, color: _ink),
        titleLarge: TextStyle(fontWeight: FontWeight.w800, color: _ink),
        titleMedium: TextStyle(fontWeight: FontWeight.w700, color: _ink),
        bodyMedium: TextStyle(color: Color(0xFF52606D)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: _ink,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
