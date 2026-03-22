import 'package:dio/dio.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:superteach_app/infrastructure/services/key_value_storage_service.dart';

// ============================================================================
// CONFIGURACIÓN: CLIENTE HTTP (DIO)
// ============================================================================
// Este archivo centraliza todas las peticiones al backend de Node.js
// ============================================================================

class ApiClient {
  /// Devuelve un cliente básico (sin token) para endpoints públicos (Login/Registro).
  static Dio get client {
    return _buildClient();
  }

  /// Devuelve un cliente que automáticamente incluye el token de sesión
  /// si está disponible en el almacenamiento local.
  static Future<Dio> authenticatedClient() async {
    final storage = KeyValueStorageService();
    final token = await storage.getValue('token');
    return _buildClient(authToken: token);
  }

  static Dio _buildClient({String? authToken}) {
    // 🚨 TRUCO DE SENIOR:
    // Si pruebas en el emulador de Android, "localhost" no funciona.
    // Android usa "10.0.2.2" para referirse a tu computadora.
    // ⚠️ ATENCIÓN: Si usas un celular FÍSICO conectado por USB, cambia esta IP 
    // por la IPv4 de tu computadora (Ejemplo: 'http://192.168.1.15:3000/api/v1')
    String baseUrl = 'http://localhost:3000/api/v1';
    
    if (!kIsWeb && Platform.isAndroid) {
      baseUrl = 'http://10.0.2.2:3000/api/v1';
    }

    final headers = {
      // 🔑 Tu llave de seguridad del Backend
      'x-api-key': 'SuperTeach_Secret_Mobile_Key_2026',
      'Content-Type': 'application/json',
    };

    // Si hay un token, lo inyectamos automáticamente en la cabecera
    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: headers,
        
        // ⏱️ LÍMITES DE TIEMPO (Cruciales para no congelar la pantalla)
        connectTimeout: const Duration(seconds: 10), // 10 seg máximo para encontrar el servidor
        receiveTimeout: const Duration(seconds: 10), // 10 seg máximo esperando respuesta de Node.js
        
        // Esto evita que Dio lance una excepción "fatal" (y rompa la app) si el servidor 
        // responde con un error de cliente (400, 401, 404). Manejaremos el error nosotros.
        validateStatus: (status) => status! < 500,
      ),
    );
  }
}