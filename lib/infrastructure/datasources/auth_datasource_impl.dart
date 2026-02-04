import 'package:superteach_app/domain/entities/user.dart';
import 'package:superteach_app/domain/errors/auth_errors.dart';

// ============================================================================
// INFRAESTRUCTURA: DATASOURCE SIMULADO (PERSISTENTE EN MEMORIA)
// ============================================================================

class MockAuthDataSource {
  
  // Base de datos persistente (Static)
  static final List<Map<String, dynamic>> _mockDatabase = [
    {
      'email': 'profe@test.com',
      'password': '123',
      'name': 'Profesor Xavier',
      'username': 'ProfeX', // ⚠️ Nuevo campo usuario
      'role': 'teacher',
      'phone': '0999999999',
    },
  ];

  static final List<String> _activeClassCodes = ['MAT-101', 'HIST-202'];

  // --- LOGIN ---
  Future<User> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1)); 
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
        // Podrías mapear el username a la entidad User si lo necesitas
        role: user['role'] == 'teacher' ? UserRole.teacher : UserRole.student,
        token: 'token-simulado-${user['email']}',
      );
    } catch (e) {
      if (e is WrongCredentials) throw WrongCredentials();
      throw CustomError('Error en el servidor o credenciales inválidas');
    }
  }

  // --- VALIDACIONES ---

  Future<bool> checkEmailExists(String email) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _mockDatabase.any((u) => u['email'] == email);
  }

  // ⚠️ NUEVA VALIDACIÓN: USUARIO DUPLICADO
  Future<bool> checkUsernameExists(String username) async {
    await Future.delayed(const Duration(milliseconds: 600));
    // Compara ignorando mayúsculas/minúsculas
    return _mockDatabase.any((u) => u['username'].toString().toLowerCase() == username.toLowerCase());
  }

  Future<bool> checkClassCodeExists(String code) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _activeClassCodes.contains(code.toUpperCase()); 
  }

  // --- REGISTRO (CON USUARIO) ---
  Future<void> register({
    required String email, 
    required String password, 
    required String name, 
    required String username, // ⚠️ Requerido
    required String role,
    required String phone,
    String? createdClassCode,
  }) async {
    await Future.delayed(const Duration(seconds: 2));

    // 1. Validación Email
    if (_mockDatabase.any((u) => u['email'] == email)) {
      throw CustomError('Ese correo electrónico ya está ligado a otra cuenta');
    }

    // 2. ⚠️ Validación Usuario
    if (_mockDatabase.any((u) => u['username'].toString().toLowerCase() == username.toLowerCase())) {
      throw CustomError('Ese nombre de usuario ya está en uso');
    }

    // 3. Validación Código de Clase
    if (role == 'teacher' && createdClassCode != null) {
      if (_activeClassCodes.contains(createdClassCode.toUpperCase())) {
        throw CustomError('El código de clase ya está en uso');
      }
      _activeClassCodes.add(createdClassCode.toUpperCase());
    }

    // 4. Guardado
    _mockDatabase.add({
      'email': email,
      'password': password,
      'name': name,
      'username': username, // Guardamos
      'role': role,
      'phone': phone,
    });
    
    print('✅ Usuario guardado: $username ($email)');
  }
}