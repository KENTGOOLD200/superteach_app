import 'package:flutter/material.dart';

// ============================================================================
// WIDGET: INPUT DE TEXTO PERSONALIZADO (CON ESTADO DE ERROR VISUAL)
// ============================================================================
// PROPÓSITO:
// Un campo de texto reutilizable que maneja estilos oscuros/neón.
// CORRECCIÓN APLICADA: Ahora conecta 'errorMessage' directamente con la UI
// para pintar los bordes de rojo cuando la validación falla.
// ============================================================================

class CustomTextFormField extends StatelessWidget {
  
  final String? label;
  final String? hint;
  final String? errorMessage; // 👈 Mensaje de error que viene del Provider
  final bool obscureText;
  final TextInputType? keyboardType;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final TextEditingController? controller;

  const CustomTextFormField({
    super.key,
    this.label,
    this.hint,
    this.errorMessage, // Si esto no es null, el campo se pone rojo
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.validator,
    this.prefixIcon,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Borde normal (cuando no hay error)
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: Colors.transparent), 
    );

    // Borde de ERROR (Rojo y más grueso)
    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: Colors.redAccent, width: 2),
    );

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121826),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
        validator: validator,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 18, color: Colors.white),
        
        decoration: InputDecoration(
          // Icono: Si hay error es rojo, si no es del color primario
          prefixIcon: prefixIcon != null 
            ? Icon(prefixIcon, color: errorMessage != null ? Colors.redAccent : colors.primary)
            : null,
          
          label: label != null ? Text(label!) : null,
          // Texto del Label: Rojo si hay error
          labelStyle: TextStyle(
            color: errorMessage != null ? Colors.redAccent : colors.primary.withOpacity(0.6)
          ),
          
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
          
          // ⚠️ AQUÍ ESTÁ LA CORRECCIÓN VISUAL:
          // Le decimos explícitamente al input que muestre el texto de error.
          // Al asignar esto, Flutter automáticamente usa los 'errorBorder' definidos abajo.
          errorText: errorMessage, 
          errorStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
          
          // Estados de los bordes
          border: border,
          enabledBorder: border,
          focusedBorder: border,
          
          // Bordes cuando hay error (Rojo)
          errorBorder: errorBorder,
          focusedErrorBorder: errorBorder,
          
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }
}