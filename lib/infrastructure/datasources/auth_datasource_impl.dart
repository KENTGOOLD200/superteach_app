import 'package:superteach_app/domain/entities/user.dart';
import 'package:superteach_app/domain/errors/auth_errors.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // Para usar kIsWeb 

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

 // --- REGISTRO (CONEXIÓN REAL AL BACKEND) ---
  Future<void> register({
    required String email, 
    required String password, 
    required String name, 
    required String username,
    required String role,
    required String phone,
    String? createdClassCode,
  }) async {
    
    try {
      // 1. Detección automática de IP (Chrome vs Emulador)
      final baseUrl = kIsWeb ? 'http://127.0.0.1:3000/api/v1' : 'http://10.0.2.2:3000/api/v1';
      
      final dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        headers: {
          'x-api-key': 'SuperTeach_Secret_Mobile_Key_2026', 
          'Content-Type': 'application/json'
        },
      ));

      // 2. Preparamos el paquete JSON exactamente como lo espera Node.js
      final Map<String, dynamic> userData = {
        "name": name,
        "username": username,
        "phone": phone,
        "email": email,
        "password": password,
        "role": role,
        "teacherClassCode": createdClassCode ?? "",
        "hasClassCode": false, // Por ahora lo dejamos por defecto
        "studentClassCode": ""
      };

      // 3. Enviamos la petición POST por la red
      final response = await dio.post('/users/register', data: userData);

      // 4. Si el servidor responde 201 Created, todo fue un éxito
      if (response.statusCode == 201) {
         print('✅ ÉXITO REAL: Usuario guardado en MongoDB');
         return; 
      }

    } on DioException catch (e) {
      // 🔥 CHIVATO: Imprime en consola el error exacto de la red
      print('🔥 DETALLE DEL ERROR DE RED: ${e.message}');
      print('🔥 TIPO DE ERROR: ${e.type}');
      
      // Si el backend envía un error 400 (ej. "Correo ya existe")
      if (e.response != null && e.response?.data != null) {
        final errorMessage = e.response!.data['error'] ?? 'Error desconocido del servidor';
        throw CustomError(errorMessage);
      }
      throw CustomError('Error de conexión con el servidor. ¿Está encendido Node.js?');
    } catch (e) {
      throw CustomError('Ocurrió un error inesperado');
    }
  }
}