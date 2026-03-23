import 'package:superteach_app/domain/entities/user.dart';
import 'package:superteach_app/domain/errors/auth_errors.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // Para usar kIsWeb 

// ============================================================================
// INFRAESTRUCTURA: DATASOURCE SIMULADO (PERSISTENTE EN MEMORIA)
// ============================================================================

class MockAuthDataSource {

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
          username: userData['username'] ?? '',
          phone: userData['phone'] ?? '',
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
      if (e is CustomError) rethrow;
      throw CustomError('Ocurrió un error inesperado');
    }
  }

  // --- VALIDACIONES ---

  // --- VALIDACIONES ---
  // 🚀 Ahora devolvemos "false" directamente porque Node.js (MongoDB) 
  // se encargará de rechazar el registro si el correo o usuario ya existen,
  // devolviendo un error 400 que tu App atrapará y mostrará en rojo.

  Future<bool> checkEmailExists(String email) async {
    return false; // Dejamos que Node.js haga el trabajo duro
  }

  Future<bool> checkUsernameExists(String username) async {
    return false; // Dejamos que Node.js haga el trabajo duro
  }

  Future<bool> checkClassCodeExists(String code) async {
    return false; // Dejamos que Node.js haga el trabajo duro
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