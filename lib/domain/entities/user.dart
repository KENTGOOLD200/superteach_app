// ============================================================================
// ENTIDAD DE DOMINIO: USUARIO
// ============================================================================
// PROPÓSITO:
// Este archivo define el "contrato" de datos del Usuario que se usará en 
// toda la aplicación. Es independiente de la base de datos o API.
// ============================================================================

enum UserRole { student, teacher }

class User {
  final String id;
  final String email;
  final String fullName;
  final UserRole role; 
  final String token;  
  final String profilePicture;

  // ⚠️ NUEVOS CAMPOS AÑADIDOS PARA EL PERFIL
  final String username;
  final String phone;

  // --- CAMPOS DINÁMICOS DE CLASES ---
  final String teacherClassCode; 
  final bool hasClassCode;       
  final String studentClassCode; 

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.token,
    this.profilePicture = '',
    
    // ⚠️ Inicializamos vacíos para no romper inicios de sesión antiguos
    this.username = '',
    this.phone = '',
    
    // Inicializamos con valores por defecto para evitar errores con cuentas viejas
    this.teacherClassCode = '',
    this.hasClassCode = false,
    this.studentClassCode = '',
  });

  // ==========================================================================
  // GETTERS INTELIGENTES (Para tu interfaz de Home)
  // ==========================================================================
  
  bool get isTeacher => role == UserRole.teacher;
  
  bool get isStudent => role == UserRole.student; 

  bool get isStudentWithClass => role == UserRole.student && hasClassCode == true;

  bool get isIndependentStudent => role == UserRole.student && hasClassCode == false;
}