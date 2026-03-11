import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

// IMPORTACIÓN DE PANTALLAS (Views)
import 'package:superteach_app/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:superteach_app/presentation/screens/auth/login_screen.dart';
import 'package:superteach_app/presentation/screens/auth/register_screen.dart';
import 'package:superteach_app/presentation/screens/resources/resources_screen.dart';
import 'package:superteach_app/presentation/screens/home/home_screen.dart';
import 'package:superteach_app/presentation/providers/auth_provider.dart';
import 'package:superteach_app/presentation/screens/quiz/quiz_screen.dart'; // Ajusta tu ruta
// ============================================================================
// CONFIGURACIÓN: ROUTER (SISTEMA DE NAVEGACIÓN)
// ============================================================================
// PROPÓSITO:
// Define el "mapa" de la aplicación usando GoRouter.
// Gestiona la navegación entre Onboarding, Login y Registro.
// ============================================================================

// ============================================================================
// CONFIGURACIÓN: ROUTER (SISTEMA DE NAVEGACIÓN)
// ============================================================================

final appRouterProvider = Provider<GoRouter>((ref) {
  
  // 1. 👁️ TRUCO MAESTRO: Un notificador que SOLO avisa cuando cambia el estatus real
  final authNotifier = ValueNotifier<AuthStatus>(AuthStatus.checking);
  
  ref.listen(authProvider, (previous, next) {
    if (previous?.status != next.status) {
      authNotifier.value = next.status; // Solo avisa al router si el estatus cambia
    }
  });

  return GoRouter(
    initialLocation: '/onboarding', 
    refreshListenable: authNotifier, // 👈 El Router escucha a este notificador, no se destruye

    // 2. 🛡️ EL POLICÍA DE TRÁNSITO (REDIRECCIÓN)
    redirect: (context, state) {
      final isGoingTo = state.matchedLocation;
      
      // Leemos el estado actual usando ref.read en lugar de watch
      final authStatus = ref.read(authProvider).status; 

      // Si apenas arranca y está revisando la caja fuerte, lo dejamos quieto
      if (authStatus == AuthStatus.checking) return null;

      // Si NO está logueado...
      if (authStatus == AuthStatus.notAuthenticated) {
        if (isGoingTo == '/login' || isGoingTo == '/register' || isGoingTo == '/onboarding') {
          return null; // Lo dejamos pasar
        }
        return '/login'; // Si intenta entrar a home, lo pateamos al login
      }

      // Si SÍ está logueado...
      if (authStatus == AuthStatus.authenticated) {
        if (isGoingTo == '/login' || isGoingTo == '/register' || isGoingTo == '/onboarding') {
          return '/home'; // Lo mandamos a su panel
        }
      }

      return null; 
    },

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

      // 3. RUTA: REGISTRO (Crear Cuenta)
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // 4. RUTA: HOME (Panel Principal)
      GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
      ),

      // 5. RUTA: RECURSOS
      GoRoute(
      path: '/resources',
      builder: (context, state) => const ResourcesScreen(),
      ),

      // 6. RUTA: CUESTIONARIO
      GoRoute(
        path: '/quiz',
        builder: (context, state) {
          // Extraemos los datos que le enviamos al navegar
          final extraData = state.extra as Map<String, dynamic>;
          return QuizScreen(
            quizData: extraData['quizData'],
            themeColor: extraData['themeColor'],
          );
        },
      ),

    ],
  );
});