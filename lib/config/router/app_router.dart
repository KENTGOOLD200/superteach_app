import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superteach_app/presentation/screens/auth/login_screen.dart';

// Este provider le dice a la app cómo navegar
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login', // Arrancamos en el Login
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      // Más adelante agregaremos '/home', '/register', etc.
    ],
  );
});