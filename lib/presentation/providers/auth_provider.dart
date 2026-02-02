import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superteach_app/domain/entities/user.dart';
import 'package:superteach_app/domain/errors/auth_errors.dart';
import 'package:superteach_app/infrastructure/datasources/auth_datasource_impl.dart';

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

// 2. NOTIFIER (Lógica de Login)
class AuthNotifier extends Notifier<AuthState> {
  
  final authDataSource = MockAuthDataSource();

  @override
  AuthState build() {
    return AuthState();
  }

  Future<void> loginUser(String email, String password, bool isTeacherLogin) async {
    // Limpiamos errores previos y ponemos estado de carga
    state = state.copyWith(status: AuthStatus.checking, errorMessage: '');

    try {
      final user = await authDataSource.login(email, password);

      // Validación de Roles (Seguridad)
      if (isTeacherLogin && !user.isTeacher) {
        throw RoleMismatchError('Esta cuenta es de Estudiante, no de Profesor.');
      }
      if (!isTeacherLogin && user.isTeacher) {
        throw RoleMismatchError('Los profesores deben ingresar en Modo Profesor.');
      }
      
      // Éxito
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        errorMessage: '',
      );
      
    } on WrongCredentials {
      _logout('Credenciales incorrectas');
    } on RoleMismatchError catch (e) {
      _logout(e.message);
    } catch (e) {
      _logout('Error no controlado');
    }
  }

  void _logout([String? errorMessage]) {
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