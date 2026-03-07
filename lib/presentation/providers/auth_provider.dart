import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superteach_app/domain/entities/user.dart';
import 'package:superteach_app/domain/errors/auth_errors.dart';
import 'package:superteach_app/infrastructure/datasources/auth_datasource_impl.dart';
import 'package:superteach_app/infrastructure/services/key_value_storage_service.dart';

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
    state = state.copyWith(status: AuthStatus.checking, errorMessage: '');

    try {
      final user = await authDataSource.login(email, password);

      if (isTeacherLogin && !user.isTeacher) {
        throw RoleMismatchError('Esta cuenta es de Estudiante, no de Profesor.');
      }
      if (!isTeacherLogin && user.isTeacher) {
        throw RoleMismatchError('Los profesores deben ingresar en Modo Profesor.');
      }
      
      // 👈 3. ¡EL LOGIN FUE UN ÉXITO! Guardamos en la caja fuerte
      await keyValueStorageService.setKeyValue('token', user.token);
      await keyValueStorageService.setKeyValue('id', user.id);
      await keyValueStorageService.setKeyValue('email', user.email);
      await keyValueStorageService.setKeyValue('fullName', user.fullName);
      await keyValueStorageService.setKeyValue('role', user.isTeacher ? 'teacher' : 'student');
      await keyValueStorageService.setKeyValue('teacherClassCode', user.teacherClassCode);
      await keyValueStorageService.setKeyValue('hasClassCode', user.hasClassCode.toString());
      await keyValueStorageService.setKeyValue('studentClassCode', user.studentClassCode);

      state = state.copyWith(status: AuthStatus.authenticated, user: user, errorMessage: '');

    } on WrongCredentials {
      logout('Credenciales incorrectas');
    } on RoleMismatchError catch (e) {
      logout(e.message);
    } on CustomError catch (e) {
      logout(e.message); 
    } catch (e) {
      logout('Error no controlado');
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