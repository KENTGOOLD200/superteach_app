import 'package:superteach_app/domain/entities/user.dart';
import 'package:superteach_app/domain/errors/auth_errors.dart';

// ============================================================================
// INFRAESTRUCTURA: DATASOURCE SIMULADO (MOCK DB)
// ============================================================================
// PROPÓSITO:
// Simula el comportamiento de un Backend real.
// Almacena usuarios en memoria y gestiona la validación de unicidad de datos.
// ============================================================================

class MockAuthDataSource {
  
  // Base de datos de usuarios (Simulación en memoria RAM)
  // Nota: 'profe@test.com' ya existe, úsalo para probar el error de duplicado.
  final List<Map<String, dynamic>> _mockDatabase = [
    {
      'email': 'profe@test.com',
      'password': '123',
      'name': 'Profesor Xavier',
      'role': 'teacher'
    },
  ];

  // Base de datos de Códigos de Clase Activos
  // Estos códigos YA EXISTEN.
  // - Un Profesor NO puede crear uno igual (Error: Ya existe).
  // - Un Alumno DEBE usar uno de estos (Error: No existe).
  final List<String> _activeClassCodes = ['MAT-101', 'HIST-202', 'CIEN-303'];

  // --- LOGIN (INICIO DE SESIÓN) ---
  Future<User> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // Simula latencia de red
    try {
      final user = _mockDatabase.firstWhere(
        (u) => u['email'] == email,
        orElse: () => throw WrongCredentials(),
      );
      if (user['password'] != password) throw WrongCredentials();

      return User(
        id: '1',
        email: user['email'],
        fullName: user['name'],
        role: user['role'] == 'teacher' ? UserRole.teacher : UserRole.student,
        token: 'token-simulado',
      );
    } catch (e) {
      if (e is WrongCredentials) throw WrongCredentials();
      throw CustomError('Error en el servidor');
    }
  }

  // --- VALIDACIONES ASÍNCRONAS (CONSULTAS AL BACKEND) ---

  // 1. Validar si el Email ya existe en la BD
  Future<bool> checkEmailExists(String email) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _mockDatabase.any((u) => u['email'] == email);
  }

  // 2. Validar si el Código de Clase existe
  Future<bool> checkClassCodeExists(String code) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _activeClassCodes.contains(code.toUpperCase()); 
  }

  // --- REGISTRO (GUARDAR NUEVO USUARIO) ---
  Future<void> register({
    required String email, 
    required String password, 
    required String name, 
    required String role,
    required String phone,
    String? photoUrl,
    String? createdClassCode,
  }) async {
    await Future.delayed(const Duration(seconds: 2)); // Simula tiempo de guardado

    // 1. VERIFICACIÓN DE SEGURIDAD: CORREO DUPLICADO
    if (_mockDatabase.any((u) => u['email'] == email)) {
      // ⚠️ CAMBIO SOLICITADO: Mensaje específico
      throw CustomError('Ese correo electrónico ya está ligado a otra cuenta');
    }

    // 2. Verificación de Código de Clase (Solo Profesores)
    if (role == 'teacher' && createdClassCode != null) {
      if (_activeClassCodes.contains(createdClassCode.toUpperCase())) {
        throw CustomError('El código de clase ya está en uso');
      }
      _activeClassCodes.add(createdClassCode.toUpperCase());
    }

    // 3. Guardado Exitoso
    _mockDatabase.add({
      'email': email,
      'password': password,
      'name': name,
      'role': role,
      'phone': phone,
      'photo': photoUrl,
    });
  }
}