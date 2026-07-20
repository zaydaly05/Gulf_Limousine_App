import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF000000); // Black
  static const Color accent = Color(0xFFFF8C00); // Orange
  static const Color background = Color(0xFFF7F7F7); // Soft white

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: background,

    colorScheme: ColorScheme.fromSeed(
      seedColor: accent,
      primary: primary,
      secondary: accent,
      background: background,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),

    cardTheme: CardThemeData(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    ),


    textTheme: const TextTheme(
      headlineSmall: TextStyle(fontWeight: FontWeight.bold),
      bodyMedium: TextStyle(fontSize: 15),
    ),
  );
}
