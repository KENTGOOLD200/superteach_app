import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superteach_app/presentation/screens/auth/login_screen.dart';

// ============================================================================
// CONFIGURACIÓN: ROUTER (SISTEMA DE NAVEGACIÓN)
// ============================================================================
// PROPÓSITO:
// Define el "mapa" de la aplicación.
// Configura qué pantalla se debe mostrar según la dirección (URL) actual.
// Utiliza 'GoRouter' para manejo profesional de historial y navegación web/móvil.
// ============================================================================

// Creamos un Provider de lectura para que el router pueda ser accedido globalmente
final appRouterProvider = Provider<GoRouter>((ref) {
  
  return GoRouter(
    // URL inicial al abrir la app.
    // En el futuro, aquí validaremos si hay token para ir directo al Home.
    initialLocation: '/login', 

    // Lista de todas las rutas posibles en la app
    routes: [
      
      // RUTA: LOGIN
      GoRoute(
        path: '/login', // La dirección interna
        builder: (context, state) => const LoginScreen(), // La pantalla visual
      ),

      // TODO: Aquí agregaremos más adelante:
      // - '/register': Pantalla de registro
      // - '/home': Pantalla principal (Dashboard)
    ],
  );
});