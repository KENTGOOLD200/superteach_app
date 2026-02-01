import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superteach_app/domain/entities/user.dart';
import 'package:superteach_app/domain/errors/auth_errors.dart';
import 'package:superteach_app/infrastructure/datasources/auth_datasource_impl.dart';

// ============================================================================
// 1. ESTADO (LA "CAJA" DE DATOS) - Se mantiene igual
// ============================================================================
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

// ============================================================================
// 2. NOTIFIER (LA LÓGICA MODERNA)
// ============================================================================
// CAMBIO: Ahora extendemos de 'Notifier' (Nativo de Riverpod)
// Ya no necesitamos importar 'state_notifier'
class AuthNotifier extends Notifier<AuthState> {
  
  // Instanciamos el datasource aquí directamente
  final authDataSource = MockAuthDataSource();

  // CAMBIO: En lugar de constructor, usamos el método build() para iniciar
  @override
  AuthState build() {
    return AuthState(); // Estado inicial
  }

  Future<void> loginUser(String email, String password) async {
    // CAMBIO: 'state' sigue funcionando igual
    state = state.copyWith(status: AuthStatus.checking);

    try {
      final user = await authDataSource.login(email, password);
      
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        errorMessage: '',
      );
      
    } on WrongCredentials {
      _logout('Credenciales incorrectas');
    } on CustomError catch (e) {
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

// ============================================================================
// 3. PROVIDER (EL ENLACE CON LA UI)
// ============================================================================
// CAMBIO: Usamos 'NotifierProvider' en lugar de 'StateNotifierProvider'
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});