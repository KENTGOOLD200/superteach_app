import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:superteach_app/domain/entities/user.dart';
import 'package:superteach_app/presentation/providers/auth_provider.dart';

// ============================================================================
// PANTALLA: HOME (PANEL PRINCIPAL DINÁMICO)
// ============================================================================

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Leemos el usuario actual desde el Provider
    final authState = ref.watch(authProvider);
    final user = authState.user;

    // Pantalla de carga por seguridad
    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D1117),
        body: Center(child: CircularProgressIndicator(color: Colors.cyan)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117), // Fondo oscuro de SuperTeach
      
      // --- BARRA SUPERIOR (Común para todos) ---
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Hola, ${user.fullName.split(" ")[0]}', // Muestra solo el primer nombre
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Botón de Recursos (Lupa)
          IconButton(
            icon: const Icon(Icons.search, color: Colors.cyan, size: 28),
            onPressed: () => context.push('/resources'),
          ),
          // Botón de Cerrar Sesión
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent, size: 28),
            onPressed: () {
              ref.read(authProvider.notifier).logout(); // 👈 Llama al logout público
            },
          ),
          const SizedBox(width: 10),
        ],
      ),

      // --- CUERPO DINÁMICO (Aquí ocurre la magia) ---
      body: _buildDynamicContent(user),
    );
  }

  // ==========================================================================
  // ENRUTADOR DE INTERFACES (IF / ELSE PURO)
  // ==========================================================================
  Widget _buildDynamicContent(User user) {
    
    // 🚪 INTERFAZ 1: PROFESOR
    if (user.isTeacher) {
      return _TeacherDashboard(user: user);
    } 
    
    // 🚪 INTERFAZ 2: ESTUDIANTE DE AULA
    else if (user.isStudentWithClass) {
      return _EnrolledStudentDashboard(user: user);
    } 
    
    // 🚪 INTERFAZ 3: ESTUDIANTE INDEPENDIENTE
    else if (user.isIndependentStudent) {
      return _IndependentStudentDashboard(user: user);
    } 
    
    // Error por defecto
    return const Center(child: Text('Error de Rol', style: TextStyle(color: Colors.white)));
  }
}

// ============================================================================
// BLOQUES DE DISEÑO PARA CADA ROL
// ============================================================================

// 1. VISTA PROFESOR
class _TeacherDashboard extends StatelessWidget {
  final User user;
  const _TeacherDashboard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.admin_panel_settings, color: Colors.purpleAccent, size: 80),
          const SizedBox(height: 20),
          const Text('PANEL DE CONTROL', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text('Tu Código de Clase es:\n${user.teacherClassCode}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.purpleAccent, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Text('Aquí podrás crear tareas y ver\nlas notas de tus alumnos.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}

//  2. VISTA ESTUDIANTE DE AULA
class _EnrolledStudentDashboard extends StatelessWidget {
  final User user;
  const _EnrolledStudentDashboard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.school, color: Colors.cyan, size: 80),
          const SizedBox(height: 20),
          const Text('AULA VIRTUAL', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text('Estás inscrito en:\n${user.studentClassCode}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.cyan, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Text('Aquí verás las tareas que\ntu profesor ha publicado.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}

// 3. VISTA ESTUDIANTE INDEPENDIENTE
class _IndependentStudentDashboard extends StatelessWidget {
  final User user;
  const _IndependentStudentDashboard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.travel_explore, color: Colors.greenAccent, size: 80),
          const SizedBox(height: 20),
          const Text('ZONA DE EXPLORACIÓN', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text('Estudio Independiente', style: TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Text('Usa el botón de buscar arriba para\nencontrar recursos de Open Library.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}