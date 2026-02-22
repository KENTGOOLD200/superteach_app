import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // ⚠️ IMPORTANTE: Necesario para usar kIsWeb

// ============================================================================
// DATASOURCE PARA LIBROS (CON CONEXIÓN A BACKEND)
// ============================================================================
class BooksDataSource {
  final Dio dio = Dio(BaseOptions(
    // Si es Web usa localhost, si es Android/iOS usa 10.0.2.2
    baseUrl: kIsWeb ? 'http://localhost:3000/api/v1' : 'http://192.168.110.183:3000/api/v1',
    headers: {
      'x-api-key': 'SuperTeach_Secret_Mobile_Key_2026'
    },
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  Future<List<dynamic>> searchBooks(String query) async {
    try {
      final response = await dio.get('/books', queryParameters: {'q': query});
      return response.data['data'];
    } catch (e) {
      throw Exception('Error de conexión con el Backend: $e');
    }
  }
}