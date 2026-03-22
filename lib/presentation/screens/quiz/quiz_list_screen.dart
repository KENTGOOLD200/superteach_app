import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:superteach_app/config/theme/app_theme.dart';
import 'package:superteach_app/domain/entities/user.dart';
import 'package:superteach_app/config/api_client.dart'; // 👈 Asegúrate de que esta ruta sea correcta

class QuizListScreen extends StatefulWidget {
  final User user;
  final Color themeColor;

  const QuizListScreen({super.key, required this.user, required this.themeColor});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  List<dynamic> _quizzes = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchQuizzes();
  }

  // ========================================================================
  // OBTENER CUESTIONARIOS Y MEJOR NOTA (USANDO APICLIENT)
  // ========================================================================
  Future<void> _fetchQuizzes() async {
    try {
      final dio = await ApiClient.authenticatedClient();
      final response = await dio.get('/quizzes');

      if (response.statusCode == 200) {
        final quizzes = response.data['data'];

        for (var quiz in quizzes) {
          try {
            // Buscamos los intentos de este cuestionario específicos para este usuario
            final attemptsResponse = await dio.get('/quizzes/${quiz['_id']}/attempts');
            
            if (attemptsResponse.statusCode == 200) {
              final attempts = attemptsResponse.data['data'];
              if (attempts != null && attempts.isNotEmpty) {
                // Sacamos la mejor nota
                final bestAttempt = attempts.reduce((a, b) => a['score'] > b['score'] ? a : b);
                quiz['bestScore'] = bestAttempt['score'];
              } else {
                quiz['bestScore'] = null;
              }
            }
          } catch (e) {
            quiz['bestScore'] = null;
          }
        }

        setState(() {
          _quizzes = quizzes;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'No se pudieron cargar los cuestionarios.';
        _isLoading = false;
      });
    }
  }

  // 👇 FUNCIÓN AUXILIAR PARA ALERTAS FLOTANTES
  void _showFloatingAlert(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: darkBackground, size: 24),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: darkBackground, fontWeight: FontWeight.bold))),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : widget.themeColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
    );
  }

  // ========================================================================
  // ELIMINAR CUESTIONARIO (PARA TODOS LOS USUARIOS)
  // ========================================================================
  Future<void> _deleteQuiz(String quizId, String topic) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121826),
        title: Text('Eliminar Cuestionario', style: TextStyle(color: widget.themeColor)),
        content: Text('¿Estás seguro de que quieres eliminar "$topic"?', style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final dio = await ApiClient.authenticatedClient();
      final response = await dio.delete('/quizzes/$quizId');

      if (response.statusCode == 200) {
        setState(() => _quizzes.removeWhere((quiz) => quiz['_id'] == quizId));
        _showFloatingAlert('Cuestionario eliminado correctamente');
      }
    } catch (e) {
      _showFloatingAlert('Error al eliminar el cuestionario (Puede que no seas el creador)', isError: true);
    }
  }

  // ========================================================================
  // PUBLICAR CUESTIONARIO (SOLO PARA PROFESORES)
  // ========================================================================
  Future<void> _publishQuiz(String quizId, String topic, bool publish) async {
    int? maxAttempts;
    if (publish) {
      maxAttempts = await showDialog<int>(
        context: context,
        builder: (context) => _AttemptsDialog(themeColor: widget.themeColor),
      );
      if (maxAttempts == null) return; 
    }

    try {
      final dio = await ApiClient.authenticatedClient();
      final response = await dio.put('/quizzes/$quizId/publish', data: {
        'isPublished': publish,
        if (publish) 'maxAttempts': maxAttempts,
      });

      if (response.statusCode == 200) {
        setState(() {
          final quizIndex = _quizzes.indexWhere((quiz) => quiz['_id'] == quizId);
          if (quizIndex != -1) {
            _quizzes[quizIndex]['isPublished'] = publish;
            if (publish) _quizzes[quizIndex]['maxAttempts'] = maxAttempts;
          }
        });
        _showFloatingAlert('Cuestionario ${publish ? 'subido a clase' : 'quitado de clase'}');
      }
    } catch (e) {
      _showFloatingAlert('Error al cambiar el estado', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: widget.themeColor),
        title: Text('Mis Cuestionarios', style: TextStyle(color: widget.themeColor, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: widget.themeColor))
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent)))
              : _quizzes.isEmpty
                  ? Center(
                      child: Text(
                        widget.user.isTeacher ? 'Aún no has generado cuestionarios.' : 'No hay cuestionarios disponibles.',
                        style: const TextStyle(color: Colors.white54),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _quizzes.length,
                      itemBuilder: (context, index) {
                        final quiz = _quizzes[index];
                        final questionCount = quiz['questions']?.length ?? 0;
                        final bestScore = quiz['bestScore'];

                        return Card(
                          color: const Color(0xFF121826),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: BorderSide(color: widget.themeColor.withOpacity(0.3), width: 1),
                          ),
                          margin: const EdgeInsets.only(bottom: 15),
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: widget.themeColor.withOpacity(0.2),
                                      child: Icon(Icons.quiz, color: widget.themeColor),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(quiz['topic'] ?? 'Sin tema', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                                          const SizedBox(height: 4),
                                          
                                          // 🧹 LIMPIEZA: Solo mostramos la cantidad de preguntas en la lista
                                          Text('$questionCount preguntas', style: const TextStyle(color: Colors.white54)),
                                          
                                          // 🏆 MEJOR PUNTUACIÓN (DORADO PARA TODOS)
                                          if (bestScore != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'Mejor puntuación: $bestScore/100', 
                                              style: const TextStyle(
                                                color: Colors.amberAccent, 
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                letterSpacing: 1.1,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    
                                    // ⚙️ MENÚ DE OPCIONES (DINÁMICO SEGÚN ROL)
                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        switch (value) {
                                          case 'publish':
                                            _publishQuiz(quiz['_id'], quiz['topic'], !(quiz['isPublished'] ?? false));
                                            break;
                                          case 'grades': 
                                            context.push('/grades', extra: {'quiz': quiz, 'user': widget.user, 'themeColor': widget.themeColor});
                                            break;
                                          case 'delete':
                                            _deleteQuiz(quiz['_id'], quiz['topic']);
                                            break;
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        // SOLO PARA PROFESORES: Subir a clase y Ver Calificaciones
                                        if (widget.user.isTeacher) ...[
                                          if (!(quiz['isPublished'] ?? false))
                                            const PopupMenuItem(value: 'publish', child: Row(children: [Icon(Icons.publish, color: Colors.green), SizedBox(width: 8), Text('Subir a clase', style: TextStyle(color: Colors.green))]))
                                          else
                                            const PopupMenuItem(value: 'publish', child: Row(children: [Icon(Icons.unpublished, color: Colors.orange), SizedBox(width: 8), Text('Quitar de clase', style: TextStyle(color: Colors.orange))])),
                                        ],
                                        
                                        // PARA TODOS: Eliminar
                                        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.redAccent), SizedBox(width: 8), Text('Eliminar', style: TextStyle(color: Colors.redAccent))])),
                                      ],
                                      icon: const Icon(Icons.more_vert, color: Colors.white54),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: widget.themeColor, 
                                      foregroundColor: darkBackground, 
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                                    ),
                                    // 🚀 MAGIA EN TIEMPO REAL: Convertimos esto en async
                                    onPressed: () async {
                                      // 1. Esperamos a que el usuario termine de jugar y vuelva
                                      await context.push('/quiz', extra: {
                                        'quizId': quiz['_id'], 
                                        'quizData': quiz['questions'], 
                                        'themeColor': widget.themeColor, 
                                        'user': widget.user
                                      });
                                      
                                      // 2. Al regresar a esta pantalla, recargamos la lista silenciosamente 
                                      // para que la nota dorada aparezca al instante.
                                      if (mounted) {
                                        _fetchQuizzes();
                                      }
                                    },
                                    child: const Text('JUGAR', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

// DIÁLOGO PARA CONFIGURAR INTENTOS (SOLO LO VE EL PROFESOR)
class _AttemptsDialog extends StatefulWidget {
  final Color themeColor;
  const _AttemptsDialog({required this.themeColor});
  @override
  State<_AttemptsDialog> createState() => _AttemptsDialogState();
}

class _AttemptsDialogState extends State<_AttemptsDialog> {
  int _selectedAttempts = 0;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF121826),
      title: Text('Configurar Intentos', style: TextStyle(color: widget.themeColor)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('¿Cuántos intentos máximo tendrán los estudiantes?', style: TextStyle(color: Colors.white)),
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