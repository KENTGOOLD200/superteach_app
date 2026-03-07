import 'package:shared_preferences/shared_preferences.dart';

// ============================================================================
// SERVICIO DE ALMACENAMIENTO LOCAL (CAJA FUERTE DEL DISPOSITIVO)
// ============================================================================

class KeyValueStorageService {
  
  // Guardar un dato (String)
  Future<void> setKeyValue(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  // Leer un dato (String)
  Future<String?> getValue(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  // Borrar un dato (Para cerrar sesión)
  Future<bool> removeKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.remove(key);
  }

  // Borrar TODA la sesión
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
