import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superteach_app/domain/entities/user.dart';
import 'package:superteach_app/domain/errors/auth_errors.dart';
import 'package:superteach_app/infrastructure/datasources/auth_datasource_impl.dart';
import 'package:superteach_app/infrastructure/services/key_value_storage_service.dart';
import 'package:superteach_app/config/api_client.dart';

// ============================================================================
// PROVIDER: AUTENTICACIÓN (LOGIN)
// ============================================================================
// PROPÓSITO:
// Gestiona el estado de la sesión del usuario (Logueado, No logueado, Cargando).
// Este es el "cerebro" que usa la pantalla de Login.
// ============================================================================

// 1. ESTADO DE AUTENTICACIÓN
class AuthState {
  final AuthStatus status;
  final User? user;
  final String errorMessage;

  AuthState({
    this.status = AuthStatus.notAuthenticated,
    this.user,
    this.errorMessage = '',
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

enum AuthStatus { checking, authenticated, notAuthenticated }

// 2. NOTIFIER (Lógica de Login con Memoria)
class AuthNotifier extends Notifier<AuthState> {
  
  final authDataSource = MockAuthDataSource();
  final keyValueStorageService = KeyValueStorageService(); // 👈 1. Instanciamos la caja fuerte

  @override
  AuthState build() {
    checkAuthStatus(); // 👈 2. Apenas arranca la app, mandamos a revisar la memoria
    return AuthState(status: AuthStatus.checking); 
  }

  // ==========================================================================
  // NUEVO: REVISAR SI YA ESTABA LOGUEADO
  // ==========================================================================
  Future<void> checkAuthStatus() async {
    final token = await keyValueStorageService.getValue('token');
    
    // Si no hay token, lo mandamos a la pantalla de login
    if (token == null) return logout();

    try {
      // 1. Leemos los datos básicos guardados en la memoria
      final id = await keyValueStorageService.getValue('id') ?? '';
      final email = await keyValueStorageService.getValue('email') ?? '';
      final fullName = await keyValueStorageService.getValue('fullName') ?? '';
      final roleString = await keyValueStorageService.getValue('role') ?? 'student';

      // 👇 ESTAS 3 LÍNEAS FALTARON 👇 Leemos los datos de las clases
      final teacherClassCode = await keyValueStorageService.getValue('teacherClassCode') ?? '';
      final hasClassCodeStr = await keyValueStorageService.getValue('hasClassCode') ?? 'false';
      final studentClassCode = await keyValueStorageService.getValue('studentClassCode') ?? '';

      // 2. Reconstruimos al usuario
      final user = User(
        id: id,
        email: email,
        fullName: fullName,
        role: roleString == 'teacher' ? UserRole.teacher : UserRole.student,
        token: token,
        teacherClassCode: teacherClassCode, // Ahora sí existen estas variables
        hasClassCode: hasClassCodeStr == 'true',
        studentClassCode: studentClassCode,
      );

      // ¡Le damos acceso directo!
      state = state.copyWith(status: AuthStatus.authenticated, user: user, errorMessage: '');
      
    } catch (e) {
      logout();
    }
  }

  // ==========================================================================
  // LOGIN (Actualizado para guardar datos)
  // ==========================================================================
  Future<void> loginUser(String email, String password, bool isTeacherLogin) async {
    // 1. Avisamos a la UI que estamos cargando
    state = state.copyWith(status: AuthStatus.checking, errorMessage: '');
    
    try {
      // 2. Disparamos la petición HTTP al servidor Node.js
      final response = await ApiClient.client.post('/users/login', data: {
        "email": email,
        "password": password
      });

      // 3. Revisamos si el backend nos dijo "todo ok" (status 200)
      if (response.statusCode == 200) {
        final data = response.data['data'];
        
        // 4. Extraemos el rol que nos manda MongoDB ('teacher' o 'student')
        final String userRoleString = data['role'];
        final isTeacher = userRoleString == 'teacher';

        // 5. 🛡️ POLICÍA DE ROLES: Evitamos que crucen puertas equivocadas
        if (isTeacherLogin && !isTeacher) {
          return logout('Esta cuenta es de Estudiante, no de Profesor.');
        }
        if (!isTeacherLogin && isTeacher) {
          return logout('Los profesores deben ingresar en Modo Profesor.');
        }
        
        // 6. Creamos el usuario adaptándolo a tu clase User de Dart
        final loggedUser = User(
          id: data['id'],
          fullName: data['name'],
          email: data['email'],
          // Convertimos el String de Node a tu Enum UserRole de Dart
          role: isTeacher ? UserRole.teacher : UserRole.student, 
          token: data['token'], // 👈 Usamos el token que viene de Node
          teacherClassCode: data['teacherClassCode'] ?? "",
          hasClassCode: data['hasClassCode'] ?? false,
          studentClassCode: data['studentClassCode'] ?? "",
        );

        // 7. Guardamos TODO en la caja fuerte local (SharedPreferences)
        await keyValueStorageService.setKeyValue('token', loggedUser.token);
        await keyValueStorageService.setKeyValue('id', loggedUser.id);
        await keyValueStorageService.setKeyValue('email', loggedUser.email);
        await keyValueStorageService.setKeyValue('fullName', loggedUser.fullName);
        await keyValueStorageService.setKeyValue('role', userRoleString);
        await keyValueStorageService.setKeyValue('teacherClassCode', loggedUser.teacherClassCode);
        await keyValueStorageService.setKeyValue('hasClassCode', loggedUser.hasClassCode.toString());
        await keyValueStorageService.setKeyValue('studentClassCode', loggedUser.studentClassCode);

        // 8. Actualizamos el estado para que el Router nos mande al Home
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: loggedUser,
          errorMessage: '',
        );
        
        print("✅ ¡Login real exitoso! Bienvenido ${loggedUser.fullName}");
        
      } else {
        // 9. Manejamos los errores que nos manda Node.js (ej. 401 Contraseña incorrecta)
        final errorMsg = response.data['error'] ?? 'Error desconocido';
        logout(errorMsg); // 👈 Pintará tus inputs de rojo
      }

    } catch (e) {
      // Error fatal: El servidor Node.js está apagado o no hay internet
      logout('Error de conexión. ¿Está encendido tu servidor local?');
    }
  }
  // ==========================================================================
  // LOGOUT (Actualizado para limpiar memoria)
  // ==========================================================================
  Future<void> logout([String? errorMessage]) async {
    // 👈 4. Limpiamos la caja fuerte para que no quede rastro
    await keyValueStorageService.clearAll();

    state = state.copyWith(
      status: AuthStatus.notAuthenticated,
      user: null,
      errorMessage: errorMessage ?? '',
    );
  }
}
// 3. PROVIDER GLOBAL (ESTE ES EL QUE FALTABA)
// Esta línea es la que crea la variable 'authProvider' que LoginScreen no encontraba.
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});