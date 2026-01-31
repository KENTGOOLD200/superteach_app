import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superteach_app/config/router/app_router.dart';
import 'package:superteach_app/config/theme/app_theme.dart';

void main() async {
  // Aquí cargaremos las variables de entorno más adelante
  runApp(
    const ProviderScope(child: MainApp()),
  );
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observamos el router (aún por crear, dará error un momento)
    final appRouter = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'SuperTeach App',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: AppTheme().getTheme(),
    );
  }
}