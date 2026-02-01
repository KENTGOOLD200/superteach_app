// ============================================================================
// ERRORES DE DOMINIO: AUTENTICACIÓN
// ============================================================================
// PROPÓSITO:
// Define excepciones personalizadas para el proceso de Login. 
// Nos permite diferenciar entre "clave mal escrita" vs "error de internet".
// ============================================================================

// Se lanza cuando el usuario o contraseña no coinciden
class WrongCredentials implements Exception {}

// Se lanza cuando se acaba el tiempo de espera (Internet lento)
class ConnectionTimeout implements Exception {}

// Se lanza para errores generales con un mensaje específico
class CustomError implements Exception {
  final String message;
  CustomError(this.message);
}