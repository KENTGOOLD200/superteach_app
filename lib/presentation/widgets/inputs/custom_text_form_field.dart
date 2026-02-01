import 'package:flutter/material.dart';

// ============================================================================
// WIDGET REUTILIZABLE: INPUT DE TEXTO (VIVID NEON & VALIDATION)
// ============================================================================
// PROPÓSITO:
// Caja de texto con estilo "Cristal Oscuro".
// - Soporta validaciones visuales: Se pone ROJO si hay error.
// - Se adapta a los colores vibrantes del tema (Cian/Magenta).
// ============================================================================

class CustomTextFormField extends StatelessWidget {
  
  // Parámetros de configuración
  final String? label;
  final String? hint;
  final String? errorMessage;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Function(String)? onChanged;
  final String? Function(String?)? validator; // Función que decide si el texto es válido
  final IconData? prefixIcon;

  const CustomTextFormField({
    super.key,
    this.label,
    this.hint,
    this.errorMessage,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.validator,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    // Obtenemos los colores del tema actual
    final colors = Theme.of(context).colorScheme;

    return Container(
      // Decoración del contenedor (Fondo oscuro y sombra)
      decoration: BoxDecoration(
        color: const Color(0xFF121826), // Fondo oscuro para resaltar el neón
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withOpacity(0.15), // Glow suave
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: TextFormField(
        // Conectamos las propiedades lógicas
        onChanged: onChanged,
        validator: validator, // Clave para que funcione la validación del Form
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 18, color: Colors.white),
        
        // Configuración visual interna
        decoration: InputDecoration(
          prefixIcon: prefixIcon != null 
            ? Icon(prefixIcon, color: colors.primary)
            : null,
          label: label != null ? Text(label!) : null,
          labelStyle: TextStyle(color: colors.primary.withOpacity(0.6)),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
          
          // ESTADO NORMAL: Sin bordes visibles (el Container da el color)
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          
          // ESTADO DE ERROR: Borde ROJO cuando la validación falla
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
          ),
          // ESTADO DE ERROR + FOCO: Borde ROJO brillante mientras corriges
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
          ),
          
          // Estilo del texto de error pequeño debajo del input
          errorStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
          
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }
}