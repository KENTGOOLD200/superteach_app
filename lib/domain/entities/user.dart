// ============================================================================
// ENTIDAD DE DOMINIO: USUARIO
// ============================================================================
// PROPÓSITO:
// Este archivo define el "contrato" de datos del Usuario que se usará en 
// toda la aplicación. Es independiente de la base de datos o API.
// ============================================================================

enum UserRole { student, teacher, admin }

class User {
  final String id;
  final String email;
  final String fullName;
  final UserRole role; // Define si es Profesor o Estudiante
  final String token;  // Llave de seguridad para peticiones al backend

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.token,
  });

  // Getter auxiliar para preguntar fácilmente si es profesor
  // Uso: if (user.isTeacher) { ... }
  bool get isTeacher => role == UserRole.teacher;
}