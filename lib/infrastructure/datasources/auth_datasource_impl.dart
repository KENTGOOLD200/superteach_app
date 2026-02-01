import 'package:superteach_app/domain/entities/user.dart';
import 'package:superteach_app/domain/errors/auth_errors.dart';

// ============================================================================
// INFRAESTRUCTURA: FUENTE DE DATOS SIMULADA (MOCK)
// ============================================================================
// PROPÓSITO:
// Simula el comportamiento de una API real (Backend).
// Incluye retardos de red artificiales y validación de credenciales
// contra una base de datos en memoria local.
// ============================================================================

class MockAuthDataSource {
  
  // Base de datos "Fake" en memoria para pruebas
  final List<Map<String, dynamic>> _mockDatabase = [
    {
      'email': 'profe@test.com',
      'password': '123',
      'name': 'Profesor Xavier',
      'role': 'teacher'
    },
    {
      'email': 'alumno@test.com',
      'password': '123',
      'name': 'Peter Parker',
      'role': 'student'
    }
  ];

  // Método para iniciar sesión
  Future<User> login(String email, String password) async {
    // 1. SIMULACIÓN DE RED: Esperamos 1 segundo para parecer real
    await Future.delayed(const Duration(seconds: 1));

    try {
      // 2. BÚSQUEDA: Intentamos encontrar el email en la lista
      // Si no lo encuentra, lanza 'orElse' -> WrongCredentials
      final user = _mockDatabase.firstWhere(
        (u) => u['email'] == email,
        orElse: () => throw WrongCredentials(),
      );

      // 3. VALIDACIÓN DE PASSWORD: Comparamos texto plano (solo para demos)
      if (user['password'] != password) {
        throw WrongCredentials();
      }

      // 4. MAPEO: Si todo es correcto, convertimos el JSON en nuestra Entidad User
      return User(
        id: '1',
        email: user['email'],
        fullName: user['name'],
        // Convertimos el string 'teacher'/'student' al Enum UserRole
        role: user['role'] == 'teacher' ? UserRole.teacher : UserRole.student,
        token: 'token-seguro-simulado-xyz',
      );

    } catch (e) {
      // Relanzamos nuestros errores conocidos para que la UI sepa qué decir
      if (e is WrongCredentials) throw WrongCredentials();
      
      // Cualquier otro error imprevisto
      throw CustomError('Error no controlado en el servidor simulado');
    }
  }
}