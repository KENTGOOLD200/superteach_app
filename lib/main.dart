import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superteach_app/config/router/app_router.dart';
import 'package:superteach_app/config/theme/app_theme.dart';

// ============================================================================
// PUNTO DE ENTRADA DE LA APLICACIÓN (ENTRY POINT)
// ============================================================================
// PROPÓSITO:
// 1. Inicializa el entorno de Flutter.
// 2. Inyecta el "ProviderScope" (Gestor de Estado Riverpod).
// 3. Arranca la aplicación visual (MaterialApp).
// ============================================================================

void main() {
  runApp(
    // ProviderScope es OBLIGATORIO para que Riverpod funcione.
    // Almacena todos los estados de la app (Usuario, Login, Temas, etc).
    const ProviderScope(
      child: MainApp(),
    ),
  );
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchamos el router provider que definimos en la carpeta config
    final appRouter = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'SuperTeach App',
      debugShowCheckedModeBanner: false, // Oculta la etiqueta "Debug" de la esquina
      
      // Conectamos el sistema de rutas
      routerConfig: appRouter,
      
      // Conectamos el tema visual
      theme: AppTheme().getTheme(),
    );
  }
}