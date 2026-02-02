// ============================================================================
// HELPER: VALIDADORES CENTRALIZADOS (APP VALIDATORS)
// ============================================================================
// PROPÓSITO:
// Contiene la lógica pura de validación (Regex) para mantener la UI limpia.
// Incluye reglas estrictas para contraseñas, emails, teléfonos y URLs.
// ============================================================================

class AppValidators {
  
  // Regex para Email (Estándar W3C)
  static final RegExp _emailRegex = RegExp(
    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+"
  );

  // Regex para Contraseña Estricta:
  // - Al menos 1 minúscula, 1 mayúscula, 1 número, 1 carácter especial
  // - Mínimo 8 caracteres
  static final RegExp _passwordStrictRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{8,}$'
  );

  // Regex para detectar si es una URL de imagen válida (termina en extensión gráfica)
  static final RegExp _imageRegex = RegExp(
    r"(https?:\/\/.*\.(?:png|jpg|jpeg|webp|gif))", 
    caseSensitive: false
  );

  // --- MÉTODOS DE VALIDACIÓN ---

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'El correo es obligatorio';
    if (!_emailRegex.hasMatch(value.trim())) return 'Formato de correo inválido';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.trim().isEmpty) return 'La contraseña es obligatoria';
    if (value.length < 8) return 'Mínimo 8 caracteres';
    if (!_passwordStrictRegex.hasMatch(value)) {
      return 'Debe tener: Mayúscula, Minúscula, Número y Símbolo (@#%)';
    }
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'El nombre es obligatorio';
    if (value.trim().length < 3) return 'El nombre es muy corto';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'El teléfono es obligatorio';
    final cleanPhone = value.trim().replaceAll(' ', '');
    
    // Validar que sean solo números
    if (int.tryParse(cleanPhone) == null) return 'Solo se permiten números';
    
    // Validación de longitud (Entre 7 y 10 dígitos)
    if (cleanPhone.length > 10) return 'Máximo 10 dígitos';
    if (cleanPhone.length < 7) return 'Número inválido';
    return null;
  }

  static String? photoUrl(String? value) {
    if (value == null || value.trim().isEmpty) return null; // Es opcional
    if (!_imageRegex.hasMatch(value.trim())) {
      return 'El enlace debe terminar en .jpg, .png o .webp';
    }
    return null;
  }

  // Validación para el código de clase (tanto para crear como para unirse)
  static String? classCode(String? value) {
    if (value == null || value.trim().isEmpty) return 'El código de clase es obligatorio';
    if (value.trim().length < 4) return 'Mínimo 4 caracteres';
    return null;
  }
}