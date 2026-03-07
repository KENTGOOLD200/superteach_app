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
  // --- LOGIN (CONEXIÓN REAL AL BACKEND) ---
  Future<User> login(String email, String password) async {
    try {
      final baseUrl = kIsWeb ? 'http://127.0.0.1:3000/api/v1' : 'http://10.0.2.2:3000/api/v1';
      
      final dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        headers: {
          'x-api-key': 'SuperTeach_Secret_Mobile_Key_2026', 
          'Content-Type': 'application/json'
        },
      ));

      // 1. Enviamos el correo y la contraseña al servidor
      final response = await dio.post('/users/login', data: {
        'email': email,
        'password': password
      });

      // 2. Si el servidor responde 200 OK, sacamos los datos del usuario
      if (response.statusCode == 200) {
        final userData = response.data['data'];

        // 3. Transformamos el JSON de Node.js a nuestra clase 'User' de Dart
        return User(
          id: userData['id'],
          email: userData['email'],
          fullName: userData['name'],
          role: userData['role'] == 'teacher' ? UserRole.teacher : UserRole.student,
          token: userData['token'],
          teacherClassCode: userData['teacherClassCode'] ?? '',
          hasClassCode: userData['hasClassCode'] ?? false,
          studentClassCode: userData['studentClassCode'] ?? '',
        );
      }
      
      throw CustomError('Error desconocido');

    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final errorMessage = e.response!.data['error'] ?? 'Credenciales inválidas';
        throw CustomError(errorMessage);
      }
      throw CustomError('Error de conexión con el servidor.');
    } catch (e) {
      if (e is CustomError) throw e;
      throw CustomError('Ocurrió un error inesperado');
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
 // --- REGISTRO (CONEXIÓN REAL AL BACKEND) ---
  Future<void> register({
    required String email, 
    required String password, 
    required String name, 
    required String username,
    required String role,
    required String phone,
    String? createdClassCode, // <-- Código si es profesor
    bool hasClassCode = false, // <-- Si es estudiante y tiene código
    String? studentClassCode, // <-- Código si es estudiante
  }) async {
    
    try {
      final baseUrl = kIsWeb ? 'http://127.0.0.1:3000/api/v1' : 'http://10.0.2.2:3000/api/v1';
      
      final dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        headers: {
          'x-api-key': 'SuperTeach_Secret_Mobile_Key_2026', 
          'Content-Type': 'application/json'
        },
      ));

      // 📦 PAQUETE JSON PERFECTAMENTE ALINEADO CON NODE.JS
      final Map<String, dynamic> userData = {
        "name": name,
        "username": username,
        "phone": phone,
        "email": email,
        "password": password,
        "role": role,
        "teacherClassCode": createdClassCode ?? "", 
        "hasClassCode": hasClassCode, 
        "studentClassCode": studentClassCode ?? "" 
      };

      final response = await dio.post('/users/register', data: userData);

      if (response.statusCode == 201) {
         print('✅ ÉXITO REAL: Usuario guardado en MongoDB');
         return; 
      }

    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final errorMessage = e.response!.data['error'] ?? 'Error desconocido del servidor';
        throw CustomError(errorMessage);
      }
      throw CustomError('Error de conexión con el servidor.');
    } catch (e) {
      throw CustomError('Ocurrió un error inesperado');
    }
  }
}