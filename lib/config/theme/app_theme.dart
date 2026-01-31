import 'package:flutter/material.dart';

class AppTheme {

  ThemeData getTheme() {
    return ThemeData(
      useMaterial3: true, // Usamos el diseño moderno de Android
      colorSchemeSeed: const Color(0xFF2862F5), // Color azul "institucional"
      brightness: Brightness.light,
    );
  }
}