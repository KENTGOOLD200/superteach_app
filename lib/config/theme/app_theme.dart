import 'package:flutter/material.dart';

// ============================================================================
// CONFIGURACIÓN: TEMA VISUAL (CYBERPUNK VIVID NEON)
// ============================================================================
// Paleta de colores inspirada en luces de neón saturadas.
// ============================================================================

// --- COLORES NEÓN PUROS ---
// Usaremos estos directamente en los widgets para asegurar la máxima vibración.
const Color neonCyan = Color(0xFF00FFFF);    // Cian Eléctrico (Modo Estudiante)
const Color neonMagenta = Color(0xFFFF00FF); // Fucsia/Magenta Puro (Modo Profesor)
// Otros colores de la paleta para futuro uso (inspirados en tu imagen):
// const Color neonOrange = Color(0xFFFFAB00);
// const Color neonGreen = Color(0xFF39FF14);

// Color de fondo profundo
const Color darkBackground = Color(0xFF0A0E17); // Negro azulado muy oscuro

class AppTheme {
  
  ThemeData getTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark, // Modo Oscuro obligatorio
      
      // Definimos el esquema de colores base usando el Cian como principal
      colorScheme: ColorScheme.dark(
        primary: neonCyan,           // Color principal de la app
        secondary: neonMagenta,  // Color de fondo
        surface: const Color(0xFF121826), // Color de las "tarjetas" o inputs
      ),
      
      // Fondo de las pantallas
      scaffoldBackgroundColor: darkBackground,

      // Estilos de Texto Globales
      textTheme: const TextTheme(
        headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        bodyMedium: TextStyle(color: Colors.white70),
      ),

      // Tema de los Inputs (Cajas de texto)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF121826), // Fondo oscuro para el input
        // Borde inactivo (sutil)
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: neonCyan.withOpacity(0.3), width: 1),
        ),
        // Borde activo (BRILLANTE)
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: neonCyan, width: 2),
          // Nota: Flutter web/desktop a veces no renderiza bien las sombras en inputs,
          // pero en móvil esto se ve bien.
        ),
        labelStyle: TextStyle(color: neonCyan.withOpacity(0.7)),
        prefixIconColor: neonCyan, // Iconos internos color neón
      ),
    );
  }
}