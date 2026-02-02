import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// IMPORTACIÓN DE PANTALLAS (Views)
import 'package:superteach_app/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:superteach_app/presentation/screens/auth/login_screen.dart';
import 'package:superteach_app/presentation/screens/auth/register_screen.dart';

// ============================================================================
// CONFIGURACIÓN: ROUTER (SISTEMA DE NAVEGACIÓN)
// ============================================================================
// PROPÓSITO:
// Define el "mapa" de la aplicación usando GoRouter.
// Gestiona la navegación entre Onboarding, Login y Registro.
// ============================================================================

final appRouterProvider = Provider<GoRouter>((ref) {
  
  return GoRouter(
    // PANTALLA INICIAL:
    // Arrancamos en el Onboarding (Semana 8)
    initialLocation: '/onboarding', 

    routes: [
      
      // 1. RUTA: ONBOARDING (Bienvenida)
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // 2. RUTA: LOGIN (Inicio de Sesión)
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // 3. RUTA: REGISTRO (Crear Cuenta - Semana 8)
      // Esta es la ruta que da error si no existe la clase 'RegisterScreen'
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

    ],
  );
});