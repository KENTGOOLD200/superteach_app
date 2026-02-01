import 'package:flutter/material.dart';

// ============================================================================
// WIDGET REUTILIZABLE: INPUT DE TEXTO (VIVID NEON STYLE)
// ============================================================================
// PROPÓSITO:
// Caja de texto con estilo "Cristal Oscuro" y bordes de neón.
// Se adapta automáticamente a los colores vibrantes del tema (Cian/Magenta).
// ============================================================================

class CustomTextFormField extends StatelessWidget {
  
  final String? label;
  final String? hint;
  final String? errorMessage;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
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
    // Obtenemos los colores vibrantes del tema (Primary = Neon Cyan)
    final colors = Theme.of(context).colorScheme;

    return Container(
      // Decoración: Caja de Cristal Oscura
      decoration: BoxDecoration(
        // AJUSTE: Usamos un color de fondo más oscuro para resaltar el neón
        color: const Color(0xFF121826), 
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          // AJUSTE: Aumentamos la opacidad de la sombra para más "Glow"
          BoxShadow(
            color: colors.primary.withOpacity(0.15), // Sombra Cian Vibrante
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
        // Borde sutil brillante
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: TextFormField(
        onChanged: onChanged,
        validator: validator,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 18, color: Colors.white),
        
        decoration: InputDecoration(
          prefixIcon: prefixIcon != null 
            ? Icon(prefixIcon, color: colors.primary) // Icono en Cian Eléctrico
            : null,
          label: label != null ? Text(label!) : null,
          labelStyle: TextStyle(color: colors.primary.withOpacity(0.6)), // Etiqueta coloreada
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
          errorText: errorMessage,
          
          // Quitamos los bordes por defecto (ya decoramos el Container)
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }
}