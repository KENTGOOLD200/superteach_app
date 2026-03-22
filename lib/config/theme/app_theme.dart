import 'package:flutter/material.dart';


// ============================================================================
// CONFIGURACIÓN: TEMA VISUAL (CYBERPUNK VIVID NEON)
// ============================================================================

const Color neonCyan = Color(0xFF00FFFF);    
const Color neonMagenta = Color(0xFFFF00FF); 
const Color darkBackground = Color(0xFF0A0E17); 

Color themeColorForRole(String role) {
  return role.toLowerCase() == 'teacher' ? neonMagenta : neonCyan;
}

// 🚦 NUEVO: TIPOS DE NOTIFICACIONES
enum SnackBarType { success, error, warning }

class AppTheme {
  
  ThemeData getTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark, 
      colorScheme: const ColorScheme.dark(
        primary: neonCyan,           
        secondary: neonMagenta,  
        surface: Color(0xFF121826), 
      ),
      scaffoldBackgroundColor: darkBackground,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        bodyMedium: TextStyle(color: Colors.white70),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF121826), 
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: neonCyan.withOpacity(0.3), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: neonCyan, width: 2),
        ),
        labelStyle: TextStyle(color: neonCyan.withOpacity(0.7)),
        prefixIconColor: neonCyan, 
      ),
    );
  }

  // ============================================================================
  // 📢 SISTEMA CENTRALIZADO DE NOTIFICACIONES (SNACKBARS)
  // ============================================================================
  static void showSnackBar(
    BuildContext context, 
    String message, 
    {
      SnackBarType type = SnackBarType.success, 
      Color? themeColor // 👈 NUEVO: Recibimos el color del tema opcionalmente
    }
  ) {
    Color bgColor;
    IconData icon;
    Color textColor = Colors.white; // Texto blanco por defecto

    // Asignamos colores e iconos según el tipo de alerta
    switch (type) {
      case SnackBarType.success:
        final userType = themeColor == neonMagenta ? 'Profesor' : 'Estudiante';
        bgColor = themeColor ?? (userType == 'Profesor' ? neonMagenta : neonCyan);
        icon = Icons.check_circle_outline;
        if (themeColor != null) textColor = darkBackground; 
        break;
      case SnackBarType.error:
        bgColor = Colors.redAccent.shade700;
        icon = Icons.error_outline;
        break;
      case SnackBarType.warning:
        bgColor = Colors.orange.shade800;
        icon = Icons.warning_amber_rounded;
        break;
    }

    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(icon, color: textColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ),
      backgroundColor: bgColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), 
      elevation: 6,
      duration: const Duration(seconds: 3),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}
