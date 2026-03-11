import 'package:dio/dio.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

// ============================================================================
// CONFIGURACIÓN: CLIENTE HTTP (DIO)
// ============================================================================
// Este archivo centraliza todas las peticiones al backend de Node.js
// ============================================================================

class ApiClient {
  static Dio get client {
    // 🚨 TRUCO DE SENIOR: 
    // Si pruebas en el emulador de Android, "localhost" no funciona.
    // Android usa "10.0.2.2" para referirse a tu computadora.
    String baseUrl = 'http://localhost:3000/api/v1';
    
    if (!kIsWeb && Platform.isAndroid) {
      baseUrl = 'http://10.0.2.2:3000/api/v1';
    }

    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: {
          // Tu llave de seguridad del Backend
          'x-api-key': 'SuperTeach_Secret_Mobile_Key_2026', 
          'Content-Type': 'application/json',
        },
        // Esto evita que Dio lance una excepción "fatal" si el usuario
        // pone mal la contraseña (código 401 o 404). Queremos manejar el error nosotros.
        validateStatus: (status) => status! < 500, 
      ),
    );
  }
}