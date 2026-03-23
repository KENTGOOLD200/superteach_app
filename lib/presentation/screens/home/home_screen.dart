import 'dart:convert';
import 'package:superteach_app/config/api_client.dart';
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

// ========================================================================
  // 🚀 NUEVA FUNCIÓN: MODIFICAR LÍMITE DE INTENTOS
  // ========================================================================
  Future<void> _updateMaxAttempts(String quizId, String topic, int currentMax) async {
    // 1. Mostramos el diálogo para que elija el nuevo límite
    final newMax = await showDialog<int>(
      context: context,
      builder: (context) => _AttemptsDialog(
        themeColor: themeColor,
        initialAttempts: currentMax, // Le pasamos el límite actual para que lo vea
      ),
    );

    // 2. Si cerró el modal o dejó el mismo número, no hacemos nada
    if (newMax == null || newMax == currentMax) return;

    try {
      // Usamos tu ApiClient blindado
      final dio = await ApiClient.authenticatedClient();

      // 3. Reutilizamos el endpoint de publicar, pero actualizando el número
      final response = await dio.put('/quizzes/$quizId/publish', data: {
        'isPublished': true, // Sigue publicado en la clase
        'maxAttempts': newMax,
      });

      if (response.statusCode == 200) {
        // 4. Actualizamos la lista local en tiempo real
        setState(() {
          final quizIndex = _publishedQuizzes.indexWhere((q) => q['_id'] == quizId);
          if (quizIndex != -1) {
            _publishedQuizzes[quizIndex]['maxAttempts'] = newMax;
          }
        });
        AppTheme.showSnackBar(context, 'Límite actualizado a ${newMax == 0 ? "Ilimitados" : newMax} para "$topic"', type: SnackBarType.success);
      }

    } catch (e) {
      AppTheme.showSnackBar(context, 'Error al actualizar los intentos', type: SnackBarType.error);
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
                                // 🚀 BOTÓN EDITAR (AHORA EN MAGENTA/THEMECOLOR)
                                IconButton(
                                  onPressed: () => _updateMaxAttempts(quiz['_id'], quiz['topic'], maxAttempts),
                                  icon: Icon(Icons.edit_attributes, color: themeColor),
                                  tooltip: 'Modificar Intentos',
                                ),
                                
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
            label: Text('CALIFICACIONES DE LA CLASE', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)),
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
// 2. VISTA ESTUDIANTE DE AULA (AHORA DINÁMICO Y CON LÍMITE DE INTENTOS)
class _EnrolledStudentDashboard extends StatefulWidget {
  final User user;
  const _EnrolledStudentDashboard({required this.user});

  @override
  State<_EnrolledStudentDashboard> createState() => _EnrolledStudentDashboardState();
}

class _EnrolledStudentDashboardState extends State<_EnrolledStudentDashboard> {
  List<dynamic> _assignedQuizzes = [];
  bool _isLoading = true;
  String _errorMessage = '';

  Color get themeColor => themeColorForRole(widget.user.role.name);

  @override
  void initState() {
    super.initState();
    _loadAssignedQuizzes();
  }

  Future<void> _loadAssignedQuizzes() async {
    try {
      final dio = await ApiClient.authenticatedClient();
      
      // Como configuramos en Node.js, esto ya trae SOLO los cuestionarios publicados de SU clase
      final response = await dio.get('/quizzes');

      if (response.statusCode == 200) {
        final quizzes = response.data['data'];

        for (var quiz in quizzes) {
          try {
            // Buscamos cuántas veces ha jugado ESTE estudiante
            final attemptsResponse = await dio.get('/quizzes/${quiz['_id']}/attempts');
            
            if (attemptsResponse.statusCode == 200) {
              final attempts = attemptsResponse.data['data'] as List;
              quiz['attemptsCount'] = attempts.length; // Guardamos cuántos intentos lleva

              if (attempts.isNotEmpty) {
                // Si ha jugado, le mostramos su mejor nota
                final bestAttempt = attempts.reduce((a, b) => a['score'] > b['score'] ? a : b);
                quiz['bestScore'] = bestAttempt['score'];
              } else {
                quiz['bestScore'] = null;
              }
            }
          } catch (e) {
            quiz['attemptsCount'] = 0;
            quiz['bestScore'] = null;
          }
        }

        setState(() {
          _assignedQuizzes = quizzes;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'No se pudieron cargar tus tareas asignadas.';
        _isLoading = false;
      });
    }
  }

  // 🛑 FUNCIÓN PARA MOSTRAR ERROR DE LÍMITE ALCANZADO
  void _showLimitReachedDialog(int maxAttempts) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121826),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        title: Row(
          children: [
            const Icon(Icons.do_not_disturb_alt, color: Colors.redAccent, size: 30),
            const SizedBox(width: 10),
            Text('Límite Alcanzado', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'El profesor ha configurado un máximo de $maxAttempts intento(s) para esta tarea y ya los has agotado.\n\nYa no puedes volver a jugarlo.',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('VOLVER', style: TextStyle(color: darkBackground, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Tareas Pendientes (${widget.user.studentClassCode})', 
          style: TextStyle(color: themeColor, fontSize: 18, fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 10),
        
        // --- LISTA DE TAREAS (DINÁMICA) ---
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF121826),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: themeColor.withOpacity(0.3), width: 1.5),
            ),
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: themeColor))
                : _errorMessage.isNotEmpty
                    ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent)))
                    : _assignedQuizzes.isEmpty
                        ? const Center(child: Text('¡Todo al día! No tienes tareas asignadas.', style: TextStyle(color: Colors.white54)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(15),
                            itemCount: _assignedQuizzes.length,
                            itemBuilder: (context, index) {
                              final quiz = _assignedQuizzes[index];
                              final maxAttempts = quiz['maxAttempts'] ?? 0;
                              final attemptsCount = quiz['attemptsCount'] ?? 0;
                              final bestScore = quiz['bestScore'];

                              return Card(
                                color: const Color(0xFF0F1419),
                                margin: const EdgeInsets.only(bottom: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  side: BorderSide(color: themeColor.withOpacity(0.4), width: 1),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(quiz['topic'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                                      const SizedBox(height: 5),
                                      
                                      // Mostramos el límite y cuántos lleva
                                      Text(
                                        maxAttempts == 0 
                                          ? 'Intentos ilimitados (Llevas $attemptsCount)' 
                                          : 'Intentos: $attemptsCount / $maxAttempts',
                                        style: TextStyle(
                                          color: (maxAttempts > 0 && attemptsCount >= maxAttempts) 
                                              ? Colors.redAccent 
                                              : Colors.white54,
                                          fontWeight: FontWeight.w500
                                        )
                                      ),
                                      // Si alcanzó el límite, en el recuadro de intentos ponemos un mensaje de "Límite Alcanzado"
                                      if (maxAttempts > 0 && attemptsCount >= maxAttempts) ...[
                                        const SizedBox(height: 5),
                                        Text('Límite de intentos alcanzado', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                      ],
                                      // Mostramos la nota en Cian (El dorado es solo para el listado del profe)
                                      if (bestScore != null) ...[
                                        const SizedBox(height: 5),
                                        Text('Tu nota más alta: $bestScore/100', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)),
                                      ],

                                      const SizedBox(height: 15),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: themeColor,
                                            foregroundColor: darkBackground,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          onPressed: () async {
                                            // 🛡️ BARRERA DE SEGURIDAD (Si el profe puso límite y ya lo pasó)
                                            if (maxAttempts > 0 && attemptsCount >= maxAttempts) {
                                              _showLimitReachedDialog(maxAttempts);
                                              // mensaje de intentos máximos alcanzados
                                              return;
                                            }

                                            // Si pasa la barrera, juega y recarga la nota al volver
                                            await context.push('/quiz', extra: {
                                              'quizId': quiz['_id'], 
                                              'quizData': quiz['questions'], 
                                              'themeColor': themeColor, 
                                              'user': widget.user
                                            });
                                            if (mounted) _loadAssignedQuizzes();
                                          },
                                          icon: const Icon(Icons.play_arrow),
                                          label: const Text('JUGAR', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ),
        const SizedBox(height: 20),

        // Botones extra de estudiante
        OutlinedButton.icon(
          onPressed: () {
            context.push('/quiz-list', extra: {'user': widget.user, 'themeColor': neonCyan}); 
          },
          icon: Icon(Icons.assignment, color: themeColor),
          label: Text('VER MIS CUESTIONARIOS CREADOS', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 20),
            side: BorderSide(color: themeColor, width: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
        const SizedBox(height: 15),

        ElevatedButton.icon(
          onPressed: () {
            showAiQuizModal(context, user: widget.user, themeColor: themeColor);
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
// ============================================================================
// DIÁLOGO PARA CONFIGURAR INTENTOS (CON MEMORIA DEL VALOR ACTUAL)
// ============================================================================
class _AttemptsDialog extends StatefulWidget {
  final Color themeColor;
  final int initialAttempts;
  const _AttemptsDialog({required this.themeColor, this.initialAttempts = 0});
  
  @override
  State<_AttemptsDialog> createState() => _AttemptsDialogState();
}

class _AttemptsDialogState extends State<_AttemptsDialog> {
  late int _selectedAttempts;
  
  @override
  void initState() {
    super.initState();
    _selectedAttempts = widget.initialAttempts; 
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF121826),
      title: Text('Modificar Intentos', style: TextStyle(color: widget.themeColor)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('¿Cuántos intentos máximo tendrán los estudiantes a partir de ahora?', style: TextStyle(color: Colors.white)),
          const SizedBox(height: 20),
          DropdownButtonFormField<int>(
            value: _selectedAttempts,
            dropdownColor: const Color(0xFF121826),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderSide: BorderSide(color: widget.themeColor.withOpacity(0.3))),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: widget.themeColor.withOpacity(0.3))),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: widget.themeColor)),
            ),
            items: const [
              DropdownMenuItem(value: 0, child: Text('Ilimitados')),
              DropdownMenuItem(value: 1, child: Text('1 intento')),
              DropdownMenuItem(value: 2, child: Text('2 intentos')),
              DropdownMenuItem(value: 3, child: Text('3 intentos')),
              DropdownMenuItem(value: 4, child: Text('4 intentos')), 
              DropdownMenuItem(value: 5, child: Text('5 intentos')),
            ],
            onChanged: (value) => setState(() => _selectedAttempts = value!),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
        TextButton(onPressed: () => Navigator.of(context).pop(_selectedAttempts), child: Text('Confirmar', style: TextStyle(color: widget.themeColor, fontWeight: FontWeight.bold))),
      ],
    );
  }
}