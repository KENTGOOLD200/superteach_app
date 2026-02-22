import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:superteach_app/config/theme/app_theme.dart'; // Asegúrate de tener esta ruta correcta para tus colores

// ============================================================================
// PANTALLA: HOME (PANEL PRINCIPAL)
// ============================================================================
// PROPÓSITO:
// Esta es la pantalla principal a la que acceden los usuarios después de iniciar sesión.
// Desde aquí, los usuarios pueden navegar a otras secciones de la app (recursos, perfil, etc.).
// ============================================================================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117), // Fondo oscuro de SuperTeach
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('SuperTeach', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          // ⚠️ ESTE ES EL BOTÓN DE BÚSQUEDA QUE TE LLEVA A LA OTRA PANTALLA
          IconButton(
            icon: const Icon(Icons.search, color: neonCyan, size: 28),
            onPressed: () {
              // Navegamos a la ruta de recursos
              context.push('/resources');
            },
          ),
          const SizedBox(width: 10), // Un pequeño margen
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dashboard_outlined, color: Colors.white24, size: 80),
            SizedBox(height: 20),
            Text(
              'Bienvenido al Panel Principal\n(Pantalla en blanco)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}