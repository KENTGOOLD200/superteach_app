import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:superteach_app/config/theme/app_theme.dart';
import 'package:superteach_app/domain/entities/user.dart';
import 'package:go_router/go_router.dart';

// ============================================================================
// WIDGET: MODAL PARA GENERAR CUESTIONARIOS CON IA (CONECTADO AL BACKEND)
// ============================================================================

void showAiQuizModal(BuildContext context, {required User user, required Color themeColor}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, 
    backgroundColor: Colors.transparent,
    builder: (context) => _AiQuizModalContent(user: user, themeColor: themeColor),
  );
}

class _AiQuizModalContent extends StatefulWidget {
  final User user;
  final Color themeColor;
  const _AiQuizModalContent({required this.user, required this.themeColor});

  @override
  State<_AiQuizModalContent> createState() => _AiQuizModalContentState();
}

class _AiQuizModalContentState extends State<_AiQuizModalContent> {
  final TextEditingController _topicController = TextEditingController();
  int _questionCount = 5; 
  final int _selectedAttempts = 0; // 👈 NUEVO: Intentos permitidos (0 = Ilimitados)
  bool _isLoading = false; // 👈 NUEVO: Estado para saber si la IA está pensando
  String? _topicError; // 👈 NUEVO: Para mostrar error en el input

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  String get _currentEmoji {
    if (_questionCount <= 3) return '🤔';
    if (_questionCount <= 7) return '🤓';
    return '🤯';
  }

  String get _reactionText {
    if (_questionCount <= 3) return 'Calentamiento rápido...';
    if (_questionCount <= 7) return 'Reto intermedio...';
    return '¡Desafío definitivo!';
  }

  // ==========================================================================
  // FUNCIÓN MAESTRA: Genera con IA y luego Guarda en MongoDB
  // ==========================================================================
  Future<void> _generateAndSaveQuiz() async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // Configuración de Dio
      final baseUrl = kIsWeb ? 'http://127.0.0.1:3000/api/v1' : 'http://10.0.2.2:3000/api/v1';
      final dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        headers: {
          'Authorization': 'Bearer ${widget.user.token}', 
          'Content-Type': 'application/json'
        },
      ));

      // --- A. PEDIMOS A LA IA QUE GENERE LAS PREGUNTAS ---
      final aiResponse = await dio.post('/ai/generate-quiz', data: {
        "topic": topic,
        "questionCount": _questionCount
      });

      if (aiResponse.statusCode == 200) {
        final List<dynamic> generatedQuestions = aiResponse.data['data'];

        // --- B. LO GUARDAMOS AUTOMÁTICAMENTE EN LA BASE DE DATOS ---
        // 🚨 CAMBIO AQUÍ: Guardamos la respuesta en la variable 'createResponse'
        final createResponse = await dio.post('/quizzes', data: {
          "topic": topic,
          "roleMode": widget.user.role.name,
          "classCode": widget.user.isTeacher ? widget.user.teacherClassCode : widget.user.studentClassCode,
          "maxAttempts": widget.user.isTeacher ? _selectedAttempts : 0, 
          "questions": generatedQuestions
        });

        // 🕵️‍♂️ ¡EL ESLABÓN PERDIDO! Extraemos el ID que MongoDB le acaba de asignar
        final String newQuizId = createResponse.data['data']['_id'];

        // --- C. CERRAMOS MODAL Y AVISAMOS ---
        if (mounted) {
          Navigator.pop(context); // Cierra el modal
          
          // 🚀 VIAJAMOS A LA ARENA PASÁNDOLE TODOS LOS DATOS PARA QUE GUARDE LA NOTA
          context.push('/quiz', extra: {
            'quizId': newQuizId, // 👈 ¡FALTABA ESTO!
            'quizData': generatedQuestions,
            'themeColor': widget.themeColor,
            'user': widget.user, // 👈 ¡FALTABA ESTO TAMBIÉN PARA EL TOKEN!
          });
          
          // Opcional: Usando tu nueva función bonita de SnackBar
          AppTheme.showSnackBar(
            context, 
            '¡Cuestionario de $topic generado y guardado!', 
            themeColor: widget.themeColor
          );
        }
      }
    } catch (e) {
      print("Error generando/guardando: $e");
      if (mounted) {
        AppTheme.showSnackBar(
          context, 
          'Error: No se pudo guardar el cuestionario.', 
          type: SnackBarType.error
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottomInset),
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(
        color: Color(0xFF121826),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, 
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 20),
          
          Row(
            children: [
              Icon(Icons.auto_awesome, color: widget.themeColor, size: 28),
              const SizedBox(width: 10),
              Text('Generador IA', style: TextStyle(color: widget.themeColor, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          const Text('Escribe un tema y la Inteligencia Artificial creará un cuestionario al instante.', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 25),

          TextField(
            controller: _topicController,
            style: const TextStyle(color: Colors.white),
            enabled: !_isLoading, // 👈 Desactivamos el input si está cargando
            onChanged: (value) {
              if (_topicError != null) {
                setState(() => _topicError = null);
              }
            },
            decoration: InputDecoration(
              hintText: 'Ej. La Revolución Francesa, Álgebra lineal...',
              hintStyle: const TextStyle(color: Colors.white24),
              errorText: _topicError,
              filled: true,
              fillColor: darkBackground,
              prefixIcon: Icon(Icons.search, color: widget.themeColor),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: widget.themeColor.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: widget.themeColor, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Colors.redAccent, width: 2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Colors.redAccent, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 30),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Cantidad de preguntas:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
              Text('$_questionCount', style: TextStyle(color: widget.themeColor, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
          
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: widget.themeColor, 
              inactiveTrackColor: widget.themeColor.withValues(alpha: 0.2), 
              overlayColor: widget.themeColor.withValues(alpha: 0.2), 
              trackHeight: 8.0,
              thumbShape: EmojiSliderThumb(emoji: _currentEmoji, thumbRadius: 18.0),
            ),
            child: Slider(
              value: _questionCount.toDouble(),
              min: 1,
              max: 10,
              divisions: 9, 
              onChanged: _isLoading ? null : (value) { // 👈 Desactivamos el slider si está cargando
                setState(() => _questionCount = value.toInt());
              },
            ),
          ),
          
          Center(
            child: Text(_reactionText, style: TextStyle(color: widget.themeColor.withValues(alpha: 0.8), fontStyle: FontStyle.italic, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 30),

          // ==================================================================
          // BOTÓN DE ACCIÓN DINÁMICO (Muestra Spinner si está cargando)
          // ====================================================================
          ElevatedButton(
            // Si está cargando, pasamos null para desactivar el botón
            onPressed: _isLoading ? null : _generateAndSaveQuiz,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.themeColor,
              disabledBackgroundColor: widget.themeColor.withValues(alpha: 0.3), // Color apagado
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: _isLoading ? 0 : 10,
              shadowColor: widget.themeColor.withValues(alpha: 0.5),
            ),
            child: _isLoading 
              ? const SizedBox(
                  height: 24, 
                  width: 24, 
                  child: CircularProgressIndicator(color: darkBackground, strokeWidth: 3)
                )
              : Text(
                  '¡GENERAR AHORA!', 
                  style: TextStyle(
                    color: widget.themeColor == neonCyan ? darkBackground : Colors.white, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 16
                  )
                ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// ============================================================================
// CLASE MAESTRA: EL PINTOR DE EMOJIS EN EL CANVAS DE FLUTTER 🎨
// ============================================================================
class EmojiSliderThumb extends SliderComponentShape {
  final String emoji;
  final double thumbRadius;

  const EmojiSliderThumb({required this.emoji, this.thumbRadius = 16.0});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size.fromRadius(thumbRadius);

  @override
  void paint(
    PaintingContext context, Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final fillPaint = Paint()..color = darkBackground..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = sliderTheme.activeTrackColor ?? Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, thumbRadius, fillPaint);
    canvas.drawCircle(center, thumbRadius, borderPaint);

    final textPainter = TextPainter(
      text: TextSpan(text: emoji, style: TextStyle(fontSize: thumbRadius * 1.3)),
      textDirection: textDirection,
    );
    textPainter.layout();
    
    final offset = Offset(center.dx - (textPainter.width / 2), center.dy - (textPainter.height / 2));
    textPainter.paint(canvas, offset);
  }
}