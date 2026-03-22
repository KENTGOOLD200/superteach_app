import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:superteach_app/domain/entities/user.dart';
import 'package:superteach_app/presentation/providers/auth_provider.dart';
import 'package:superteach_app/config/theme/app_theme.dart'; // 👈 Tu función viene de aquí
import 'package:superteach_app/presentation/widgets/inputs/ai_quiz_modal.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

// ============================================================================
// PANTALLA: HOME (PANEL PRINCIPAL DINÁMICO CON ESTILO NEÓN)
// ============================================================================

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    // 🎨 USANDO TU FUNCIÓN LIMPIA DEL TEMA
    final themeColor = user != null ? themeColorForRole(user.role.name) : neonCyan;

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
          IconButton(
            icon: Icon(Icons.search, color: themeColor, size: 28),
            onPressed: () => context.push('/resources'),
          ),
          
          PopupMenuButton<String>(
            color: const Color(0xFF121826), 
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(color: themeColor.withOpacity(0.3), width: 1),
            ),
            offset: const Offset(0, 50),
            onSelected: (value) {
              if (value == 'profile') {
                context.push('/profile', extra: {
                  'name': user.fullName,
                  'username': user.username,
                  'phone': user.phone,
                  'profilePicture': user.profilePicture,
                  'role': user.role.name,
                  'hasClassCode': user.hasClassCode,
                  'token': user.token,
                });
              }
              else if (value == 'logout') {
                ref.read(authProvider.notifier).logout(); 
              } 
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Builder(builder: (context) {
              ImageProvider? avatarImage;
              if (user.profilePicture.isNotEmpty) {
                if (user.profilePicture.startsWith('data:image')) {
                  try {
                    avatarImage = MemoryImage(base64Decode(user.profilePicture.split(',').last));
                  } catch (_) { avatarImage = null; }
                } else {
                  avatarImage = NetworkImage(user.profilePicture);
                }
              }

              return CircleAvatar(
                radius: 18,
                backgroundColor: themeColor.withOpacity(0.2),
                backgroundImage: avatarImage,
                child: avatarImage == null ? Icon(Icons.person, color: themeColor) : null,
              );
            }),
            ),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'profile',
                child: ListTile(
                  leading: Builder(builder: (context) {
                    ImageProvider? avatarImage;
                    if (user.profilePicture.isNotEmpty) {
                      if (user.profilePicture.startsWith('data:image')) {
                        try {
                          avatarImage = MemoryImage(base64Decode(user.profilePicture.split(',').last));
                        } catch (_) { avatarImage = null; }
                      } else {
                        avatarImage = NetworkImage(user.profilePicture);
                      }
                    }

                    return CircleAvatar(
                      radius: 16,
                      backgroundColor: themeColor.withOpacity(0.2),
                      backgroundImage: avatarImage,
                      child: avatarImage == null ? Icon(Icons.person, color: themeColor, size: 16) : null,
                    );
                  }),
                  title: const Text('Mi Perfil', style: TextStyle(color: Colors.white)),
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
class _TeacherDashboard extends StatefulWidget {
  final User user;
  const _TeacherDashboard({required this.user});

  @override
  State<_TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<_TeacherDashboard> {
  List<dynamic> _publishedQuizzes = [];
  bool _isLoadingQuizzes = false;
  String _errorMessage = '';

  // 🎨 USANDO TU FUNCIÓN LIMPIA DEL TEMA
  Color get themeColor => themeColorForRole(widget.user.role.name);

  @override
  void initState() {
    super.initState();
    _loadPublishedQuizzes();
  }

  Future<void> _loadPublishedQuizzes() async {
    setState(() {
      _isLoadingQuizzes = true;
      _errorMessage = '';
    });

    try {
      final baseUrl = kIsWeb ? 'http://127.0.0.1:3000/api/v1' : 'http://10.0.2.2:3000/api/v1';
      final dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        headers: {
          'Authorization': 'Bearer ${widget.user.token}',
          'Content-Type': 'application/json'
        },
      ));

      final response = await dio.get('/classes/${widget.user.teacherClassCode}/quizzes');

      if (response.statusCode == 200) {
        setState(() {
          _publishedQuizzes = response.data['data'] ?? [];
          _isLoadingQuizzes = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar cuestionarios publicados';
        _isLoadingQuizzes = false;
      });
    }
  }

  Future<void> _unpublishQuiz(String quizId, String topic) async {
    try {
      final baseUrl = kIsWeb ? 'http://127.0.0.1:3000/api/v1' : 'http://10.0.2.2:3000/api/v1';
      final dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        headers: {
          'Authorization': 'Bearer ${widget.user.token}',
          'Content-Type': 'application/json'
        },
      ));

      final response = await dio.put('/quizzes/$quizId/publish', data: {
        'isPublished': false,
      });

      if (response.statusCode == 200) {
        setState(() {
          _publishedQuizzes.removeWhere((quiz) => quiz['_id'] == quizId);
        });
        AppTheme.showSnackBar(context, 'Cuestionario "$topic" quitado de clase', type: SnackBarType.warning);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al quitar cuestionario de clase'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🛡️ MANTENEMOS EL SCROLL PARA EVITAR EL OVERFLOW
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tarjeta de Clase
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF121826),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: themeColor.withOpacity(0.5), width: 1.5),
            ),
            child: Column(
              children: [
                Icon(Icons.admin_panel_settings, color: themeColor, size: 60),
                const SizedBox(height: 10),
                const Text('CÓDIGO DE CLASE', style: TextStyle(color: Colors.white70, letterSpacing: 1.5)),
                Text(widget.user.teacherClassCode, style: TextStyle(color: themeColor, fontSize: 28, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Sección de Cuestionarios Publicados
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF121826),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: themeColor.withOpacity(0.3), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.class_, color: themeColor, size: 28),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('CUESTIONARIOS DE CLASE', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      onPressed: _loadPublishedQuizzes,
                      icon: Icon(Icons.refresh, color: themeColor),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                if (_isLoadingQuizzes)
                  Center(child: CircularProgressIndicator(color: themeColor))
                else if (_errorMessage.isNotEmpty)
                  Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent)))
                else if (_publishedQuizzes.isEmpty)
                  const Center(child: Text('No hay cuestionarios publicados en la clase', style: TextStyle(color: Colors.white54)))
                else
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemCount: _publishedQuizzes.length,
                      itemBuilder: (context, index) {
                        final quiz = _publishedQuizzes[index];
                        final questionCount = quiz['questions'].length;
                        final maxAttempts = quiz['maxAttempts'] ?? 0;

                        return Card(
                          color: const Color(0xFF0F1419),
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: themeColor.withOpacity(0.2), width: 1),
                          ),
                          child: ListTile(
                            title: Text(quiz['topic'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Text('$questionCount preguntas • Max. $maxAttempts intentos', style: const TextStyle(color: Colors.white54)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    context.push('/grades/${quiz['_id']}', extra: {'quiz': quiz, 'user': widget.user, 'themeColor': themeColor});
                                  },
                                  icon: const Icon(Icons.grade, color: Colors.green),
                                  tooltip: 'Ver calificaciones',
                                ),
                                IconButton(
                                  onPressed: () => _unpublishQuiz(quiz['_id'], quiz['topic']),
                                  icon: const Icon(Icons.unpublished, color: Colors.orange),
                                  tooltip: 'Quitar de clase',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // BOTÓN 1: GENERAR CUESTIONARIO IA
          ElevatedButton.icon(
            onPressed: () {
              showAiQuizModal(context, user: widget.user, themeColor: themeColor);
            },
            icon: const Icon(Icons.auto_awesome, color: Colors.white),
            label: const Text('GENERAR CUESTIONARIO IA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 10,
              shadowColor: themeColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 15),

          // BOTÓN 2: VER CUESTIONARIOS
          ElevatedButton.icon(
          onPressed: () {
            context.push('/quiz-list', extra: {'user': widget.user, 'themeColor': themeColor}); // 👈 AGREGAR ESTO
          },
            icon: const Icon(Icons.list_alt, color: Colors.white),
            label: const Text('VER CUESTIONARIOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor.withOpacity(0.4),
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 0,
            ),
          ),
          const SizedBox(height: 15),

          // BOTÓN 3: CALIFICACIONES Y ESTADÍSTICAS
          OutlinedButton.icon(
            onPressed: () {},
            icon: Icon(Icons.bar_chart, color: themeColor),
            label: Text('PUNTUACIONES Y ESTADÍSTICAS', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
              side: BorderSide(color: themeColor, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
          const SizedBox(height: 10),
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
    // 🎨 USANDO TU FUNCIÓN LIMPIA DEL TEMA
    final themeColor = themeColorForRole(user.role.name);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Tareas Pendientes', style: TextStyle(color: themeColor, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF121826),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: themeColor.withOpacity(0.2)),
            ),
            child: const Center(child: Text('Aún no tienes tareas asignadas', style: TextStyle(color: Colors.white54))),
          ),
        ),
        const SizedBox(height: 20),

        OutlinedButton.icon(
          onPressed: () {
            context.push('/quiz-list', extra: {'user': user, 'themeColor': neonCyan}); // 👈 AGREGAR ESTO
          },
          icon: Icon(Icons.assignment, color: themeColor),
          label: Text('VER CUESTIONARIOS Y PUNTUACIONES', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 20),
            side: BorderSide(color: themeColor, width: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
        const SizedBox(height: 15),

        ElevatedButton.icon(
          onPressed: () {
            showAiQuizModal(context, user: user, themeColor: themeColor);
          },
          icon: const Icon(Icons.auto_awesome, color: darkBackground),
          label: const Text('PRACTICAR CON IA', style: TextStyle(color: darkBackground, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: themeColor,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 10,
            shadowColor: themeColor.withOpacity(0.5),
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
    // 🎨 USANDO TU FUNCIÓN LIMPIA DEL TEMA
    final themeColor = themeColorForRole(user.role.name);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.travel_explore, color: themeColor, size: 100),
        const SizedBox(height: 20),
        const Text('Estudio Independiente', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Text('Elige un tema y genera un cuestionario instantáneo para evaluar tus conocimientos.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 16)),
        const SizedBox(height: 40),

        OutlinedButton.icon(
          onPressed: () {
            context.push('/quiz-list', extra: {'user': user, 'themeColor': neonCyan}); // 👈 AGREGAR ESTO
          },
          icon: Icon(Icons.history, color: themeColor),
          label: Text('VER CUESTIONARIOS Y PUNTUACIONES', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 20),
            side: BorderSide(color: themeColor, width: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
        const SizedBox(height: 15),

        ElevatedButton.icon(
          onPressed: () {
            showAiQuizModal(context, user: user, themeColor: themeColor);
          },
          icon: const Icon(Icons.auto_awesome, color: darkBackground),
          label: const Text('GENERAR CUESTIONARIO IA', style: TextStyle(color: darkBackground, fontWeight: FontWeight.bold, fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: themeColor,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 10,
            shadowColor: themeColor.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}