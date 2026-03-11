import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:superteach_app/domain/entities/user.dart';
import 'package:superteach_app/presentation/providers/auth_provider.dart';
import 'package:superteach_app/config/theme/app_theme.dart';
import 'package:superteach_app/presentation/widgets/inputs/ai_quiz_modal.dart';

// ============================================================================
// PANTALLA: HOME (PANEL PRINCIPAL DINÁMICO CON ESTILO NEÓN)
// ============================================================================

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      return const Scaffold(
        backgroundColor: darkBackground,
        body: Center(child: CircularProgressIndicator(color: neonCyan)),
      );
    }

    return Scaffold(
      backgroundColor: darkBackground, 
      
      // --- BARRA SUPERIOR (CON MENÚ DE PERFIL) ---
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Hola, ${user.fullName.split(" ")[0]}', 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          // 1. Botón de Recursos (Lupa)
          IconButton(
            icon: const Icon(Icons.search, color: neonCyan, size: 28),
            onPressed: () => context.push('/resources'),
          ),
          
          // 2. EL NUEVO MENÚ CIRCULAR DE PERFIL
          PopupMenuButton<String>(
            color: const Color(0xFF121826), // Fondo oscuro del menú
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(color: neonCyan.withValues(alpha: 0.3), width: 1),
            ),
            offset: const Offset(0, 50),
            onSelected: (value) {
              if (value == 'profile') {
                // TODO: Navegar a la pantalla de perfil
                print("Ir a perfil"); 
              } else if (value == 'logout') {
                ref.read(authProvider.notifier).logout(); 
              }
            },
            // El ícono que dispara el menú (La foto de perfil)
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: neonCyan.withValues(alpha: 0.2),
                backgroundImage: user.profilePicture.isNotEmpty 
                    ? NetworkImage(user.profilePicture) 
                    : null,
                // Si no hay foto, mostramos un ícono de usuario neón
                child: user.profilePicture.isEmpty 
                    ? const Icon(Icons.person, color: neonCyan) 
                    : null,
              ),
            ),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.account_circle, color: neonCyan),
                  title: Text('Mi Perfil', style: TextStyle(color: Colors.white)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(height: 1),
              const PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.redAccent),
                  title: Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),

      // --- CUERPO DINÁMICO ---
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _buildDynamicContent(user),
      ),
    );
  }

  // ==========================================================================
  // ENRUTADOR DE INTERFACES (IF / ELSE PURO)
  // ==========================================================================
  Widget _buildDynamicContent(User user) {
    if (user.isTeacher) {
      return _TeacherDashboard(user: user);
    } else if (user.isStudentWithClass) {
      return _EnrolledStudentDashboard(user: user);
    } else if (user.isIndependentStudent) {
      return _IndependentStudentDashboard(user: user);
    } 
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tarjeta de Clase
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF121826),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: neonMagenta.withValues(alpha: 0.5), width: 1.5),
          ),
          child: Column(
            children: [
              const Icon(Icons.admin_panel_settings, color: neonMagenta, size: 60),
              const SizedBox(height: 10),
              const Text('CÓDIGO DE CLASE', style: TextStyle(color: Colors.white70, letterSpacing: 1.5)),
              Text(user.teacherClassCode, style: const TextStyle(color: neonMagenta, fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const Spacer(),

        // BOTÓN 1: GENERAR CUESTIONARIO IA
        ElevatedButton.icon(
          onPressed: () {
            showAiQuizModal(context, themeColor: neonMagenta);
          },
          icon: const Icon(Icons.auto_awesome, color: Colors.white),
          label: const Text('GENERAR CUESTIONARIO IA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: neonMagenta,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 10,
            shadowColor: neonMagenta.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 15),

        // BOTÓN 2: VER CUESTIONARIOS
        ElevatedButton.icon(
          onPressed: () {
            // TODO: Navegar a la lista de cuestionarios creados
          },
          icon: const Icon(Icons.list_alt, color: Colors.white),
          label: const Text('VER CUESTIONARIOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: neonMagenta.withValues(alpha: 0.4),
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 0,
          ),
        ),
        const SizedBox(height: 15),

        // BOTÓN 3: CALIFICACIONES Y ESTADÍSTICAS
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.bar_chart, color: neonMagenta),
          label: const Text('PUNTUACIONES Y ESTADÍSTICAS', style: TextStyle(color: neonMagenta, fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 20),
            side: const BorderSide(color: neonMagenta, width: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

//  2. VISTA ESTUDIANTE DE AULA
class _EnrolledStudentDashboard extends StatelessWidget {
  final User user;
  const _EnrolledStudentDashboard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Tareas Pendientes', style: TextStyle(color: neonCyan, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        // Aquí irá el ListView con las tareas en el futuro
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF121826),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: neonCyan.withValues(alpha: 0.2)),
            ),
            child: const Center(child: Text('Aún no tienes tareas asignadas', style: TextStyle(color: Colors.white54))),
          ),
        ),
        const SizedBox(height: 20),

        // BOTÓN 1: VER CUESTIONARIOS
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.assignment, color: neonCyan),
          label: const Text('VER CUESTIONARIOS Y PUNTUACIONES', style: TextStyle(color: neonCyan, fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 20),
            side: const BorderSide(color: neonCyan, width: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
        const SizedBox(height: 15),

        // BOTÓN 2: GENERAR CUESTIONARIO IA (Estudio extra)
        ElevatedButton.icon(
          onPressed: () {
            showAiQuizModal(context, themeColor: neonCyan);
          },
          icon: const Icon(Icons.auto_awesome, color: darkBackground),
          label: const Text('PRACTICAR CON IA', style: TextStyle(color: darkBackground, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: neonCyan,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 10,
            shadowColor: neonCyan.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

// 3. VISTA ESTUDIANTE INDEPENDIENTE
class _IndependentStudentDashboard extends StatelessWidget {
  final User user;
  const _IndependentStudentDashboard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.travel_explore, color: neonCyan, size: 100),
        const SizedBox(height: 20),
        const Text('Estudio Independiente', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Text('Elige un tema y genera un cuestionario instantáneo para evaluar tus conocimientos.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 16)),
        const SizedBox(height: 40),

        // BOTÓN 1: HISTORIAL Y PUNTUACIONES (NUEVO)
        OutlinedButton.icon(
          onPressed: () {
            // TODO: Navegar a los puntajes
          },
          icon: const Icon(Icons.history, color: neonCyan),
          label: const Text('VER CUESTIONARIOS Y PUNTUACIONES', style: TextStyle(color: neonCyan, fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 20),
            side: const BorderSide(color: neonCyan, width: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
        const SizedBox(height: 15),

        // BOTÓN 2: GENERAR CUESTIONARIO IA
        ElevatedButton.icon(
          onPressed: () {
            showAiQuizModal(context, themeColor: neonCyan);
          },
          icon: const Icon(Icons.auto_awesome, color: darkBackground),
          label: const Text('GENERAR CUESTIONARIO IA', style: TextStyle(color: darkBackground, fontWeight: FontWeight.bold, fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: neonCyan,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 10,
            shadowColor: neonCyan.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}