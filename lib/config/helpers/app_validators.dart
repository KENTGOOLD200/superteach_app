// ============================================================================
// ARCHIVO: APP_VALIDATORS.DART
// DESCRIPCIÓN: REGLAS DE VALIDACIÓN (REGEX) CENTRALIZADAS
// ============================================================================

class AppValidators {
  
  // Regex para Email
  static final RegExp _emailRegex = RegExp(
    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+"
  );

  // Regex Contraseña Estricta
  static final RegExp _passwordStrictRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{8,}$'
  );

  // ⚠️ NUEVO: Regex para NOMBRE (Solo letras, espacios y tildes/ñ)
  // No permite números ni símbolos.
  static final RegExp _nameRegex = RegExp(
    r"^[a-zA-ZñÑáéíóúÁÉÍÓÚ\s]+$"
  );

  // --- MÉTODOS ---

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'El correo es obligatorio';
    if (!_emailRegex.hasMatch(value.trim())) return 'Formato de correo inválido';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.trim().isEmpty) return 'La contraseña es obligatoria';
    if (value.length < 8) return 'Mínimo 8 caracteres';
    if (!_passwordStrictRegex.hasMatch(value)) {
      return 'Debe tener: Mayúscula, Minúscula, Número y Símbolo';
    }
    return null;
  }

  // VALIDACIÓN ACTUALIZADA: NOMBRE
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'El nombre es obligatorio';
    if (value.trim().length < 3) return 'El nombre es muy corto';
    
    // Aplicamos la restricción de solo letras
    if (!_nameRegex.hasMatch(value.trim())) {
      return 'Solo se permiten letras (no números ni símbolos)';
    }
    return null;
  }

  // ⚠️ NUEVO VALIDADOR: USUARIO
  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) return 'El usuario es obligatorio';
    if (value.trim().length < 3) return 'Mínimo 3 caracteres';
    // Opcional: Podrías agregar regex para que el usuario no tenga espacios, etc.
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'El teléfono es obligatorio';
    final cleanPhone = value.trim().replaceAll(' ', '');
    if (int.tryParse(cleanPhone) == null) return 'Solo se permiten números';
    if (cleanPhone.length > 10) return 'Máximo 10 dígitos';
    if (cleanPhone.length < 7) return 'Número inválido';
    return null;
  }

  // URL Foto (Opcional)
  static final RegExp _imageRegex = RegExp(r"(https?:\/\/.*\.(?:png|jpg|jpeg|webp|gif))", caseSensitive: false);
  static String? photoUrl(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!_imageRegex.hasMatch(value.trim())) return 'Debe ser URL de imagen (.jpg, .png)';
    return null;
  }

  static String? classCode(String? value) {
    if (value == null || value.trim().isEmpty) return 'El código es obligatorio';
    if (value.trim().length < 4) return 'Mínimo 4 caracteres';
    return null;
  }
}