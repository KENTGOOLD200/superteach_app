// ============================================================================
// ERRORES DE DOMINIO: AUTENTICACIÓN
// ============================================================================
// PROPÓSITO:
// Define las excepciones personalizadas que pueden ocurrir durante el Login.
// Permite distinguir entre credenciales malas, problemas de red o
// intentos de ingreso con el rol incorrecto (Seguridad).
// ============================================================================

// Se lanza cuando el email o contraseña no coinciden con la BD
class WrongCredentials implements Exception {}

// Se lanza cuando el tiempo de espera se agota
class ConnectionTimeout implements Exception {}

// NUEVO: Se lanza cuando un Estudiante intenta entrar como Profesor (o viceversa)
class RoleMismatchError implements Exception {
  final String message;
  RoleMismatchError(this.message);
}

// Se lanza para errores generales con mensaje específico
class CustomError implements Exception {
  final String message;
  CustomError(this.message);
}