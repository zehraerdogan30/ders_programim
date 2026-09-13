import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF131927), // Görseldeki koyu arka plan
    primaryColor: const Color(0xFF6C5CE7),
    cardColor: const Color(0xFF1E2638), // Kartların koyu tonu
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF131927),
      elevation: 0,
    ),
    colorScheme: const ColorScheme.dark(
      surface: Color(0xFF1E2638),
      primary: Color(0xFF6C5CE7),
      secondary: Color(0xFFFF7675),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E2638),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: Colors.grey),
    ),
  );
}