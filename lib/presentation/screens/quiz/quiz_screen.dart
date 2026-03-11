import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:superteach_app/config/theme/app_theme.dart';

// ============================================================================
// PANTALLA: CUESTIONARIO GAMIFICADO (AVANCE POR TOQUE EN PANTALLA)
// ============================================================================

class QuizScreen extends StatefulWidget {
  final List<dynamic> quizData;
  final Color themeColor;

  const QuizScreen({
    super.key,
    required this.quizData,
    required this.themeColor,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _score = 0;
  bool _isAnswered = false;
  bool _isCorrectMatch = false;
  bool _canAdvance = false;
  String? _selectedAnswer;
  List<String> _shuffledAnswers = [];

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  /// Inicializa el controlador de animación y carga la primera pregunta.
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadQuestion();
  }

  @override
  /// Libera los recursos del controlador de animación.
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Carga y prepara la pregunta actual, barajando las respuestas.
  void _loadQuestion() {
    _pulseController.reset();
    setState(() {
      _isAnswered = false;
      _selectedAnswer = null;
      _isCorrectMatch = false;
      _canAdvance = false;

      final question = widget.quizData[_currentIndex];
      _shuffledAnswers = List<String>.from(question['incorrectAnswers']);
      _shuffledAnswers.add(question['correctAnswer']);
      _shuffledAnswers.shuffle();
    });
  }

  /// Verifica si la respuesta seleccionada es correcta y actualiza el estado del quiz.
  void _checkAnswer(String answer) {
    if (_isAnswered) return;

    final correctAnswer = widget.quizData[_currentIndex]['correctAnswer'];
    final isCorrect = answer == correctAnswer;

    setState(() {
      _isAnswered = true;
      _selectedAnswer = answer;
      _isCorrectMatch = isCorrect;
      _canAdvance = true;
      if (isCorrect) _score++;
    });

    _pulseController.repeat(reverse: true);
  }

  /// Avanza a la siguiente pregunta si es posible, o muestra los resultados finales.
  void _advanceNext() {
    if (!_canAdvance) return;

    if (_currentIndex < widget.quizData.length - 1) {
      _currentIndex++;
      _loadQuestion();
    } else {
      _showResults();
    }
  }

  /// Salta la pregunta actual sin responderla, pasando a la siguiente.
  void _skipQuestion() {
    if (_currentIndex < widget.quizData.length - 1) {
      _currentIndex++;
      _loadQuestion();
    } else {
      _showResults();
    }
  }

  /// Reinicia el quiz volviendo al inicio.
  void _restartQuiz() {
    Navigator.pop(context);
    setState(() {
      _currentIndex = 0;
      _score = 0;
      _loadQuestion();
    });
  }

  /// Muestra el diálogo con los resultados finales del quiz.
  void _showResults() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut),
          child: AlertDialog(
            backgroundColor: const Color(0xFF121826),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: widget.themeColor, width: 2),
            ),
            title: Column(
              children: [
                Icon(Icons.emoji_events, color: neonCyan, size: 60),
                const SizedBox(height: 10),
                Text(
                  '¡Cuestionario Terminado!',
                  style: TextStyle(
                    color: widget.themeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              'Tu puntuación:\n$_score / ${widget.quizData.length}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: _restartQuiz,
                    icon: const Icon(Icons.refresh, color: darkBackground),
                    label: const Text(
                      'VOLVER A INTENTAR',
                      style: TextStyle(
                        color: darkBackground,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.themeColor,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () {
                      context.pop();
                      context.pop();
                    },
                    icon: Icon(Icons.home, color: widget.themeColor),
                    label: Text(
                      'VOLVER AL INICIO',
                      style: TextStyle(
                        color: widget.themeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: BorderSide(
                        color: widget.themeColor.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Construye la interfaz de usuario de la pantalla del quiz.
  @override
  Widget build(BuildContext context) {
    final currentQuestion = widget.quizData[_currentIndex];

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: widget.themeColor),
        title: Text(
          'Pregunta ${_currentIndex + 1} de ${widget.quizData.length}',
          style: TextStyle(
            color: widget.themeColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.skip_next, color: widget.themeColor),
            onPressed: _skipQuestion,
            tooltip: 'Saltar pregunta',
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressIndicator(
                  value: (_currentIndex + 1) / widget.quizData.length,
                  backgroundColor: widget.themeColor.withValues(alpha: 0.2),
                  color: widget.themeColor,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(10),
                ),
                const SizedBox(height: 30),

                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    reverseDuration: const Duration(milliseconds: 400),
                    switchInCurve: Curves.elasticOut,
                    switchOutCurve: Curves.easeOutCubic,
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: animation,
                              child: child,
                            ),
                          );
                        },
                    child: ListView(
                      key: ValueKey<int>(_currentIndex),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF121826),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: widget.themeColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            currentQuestion['question'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 30),

                        ..._shuffledAnswers.map((answer) {
                          final isThisCorrectAnswer =
                              answer == currentQuestion['correctAnswer'];
                          final isThisSelectedWrong =
                              _isAnswered &&
                              answer == _selectedAnswer &&
                              !_isCorrectMatch;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 15),
                            child: TweenAnimationBuilder<double>(
                              key: ValueKey('shake_$_isAnswered\_$answer'),
                              tween: Tween(
                                begin: 0.0,
                                end: isThisSelectedWrong ? 1.0 : 0.0,
                              ),
                              duration: const Duration(milliseconds: 400),
                              builder: (context, value, child) {
                                final offset =
                                    math.sin(value * math.pi * 5) * 8;
                                return Transform.translate(
                                  offset: Offset(offset, 0),
                                  child: child,
                                );
                              },
                              child: InkWell(
                                onTap: () => _checkAnswer(answer),
                                borderRadius: BorderRadius.circular(15),
                                child: AnimatedBuilder(
                                  animation: _pulseAnimation,
                                  builder: (context, child) {
                                    Color btnColor = const Color(0xFF121826);
                                    Color borderColor = widget.themeColor
                                        .withValues(alpha: 0.5);
                                    double glowRadius = 0;

                                    if (_isAnswered) {
                                      if (isThisCorrectAnswer) {
                                        btnColor = Colors.green.withValues(
                                          alpha:
                                              0.2 +
                                              (_pulseAnimation.value * 0.3),
                                        );
                                        borderColor = Colors.greenAccent;
                                        glowRadius = _pulseAnimation.value * 20;
                                      } else if (isThisSelectedWrong) {
                                        btnColor = Colors.red.withValues(
                                          alpha: 0.3,
                                        );
                                        borderColor = Colors.redAccent;
                                      } else {
                                        btnColor = const Color(
                                          0xFF121826,
                                        ).withValues(alpha: 0.5);
                                        borderColor = Colors.transparent;
                                      }
                                    }

                                    return AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 20,
                                        horizontal: 15,
                                      ),
                                      decoration: BoxDecoration(
                                        color: btnColor,
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(
                                          color: borderColor,
                                          width: 2,
                                        ),
                                        boxShadow: glowRadius > 0
                                            ? [
                                                BoxShadow(
                                                  color: Colors.greenAccent
                                                      .withValues(alpha: 0.6),
                                                  blurRadius: glowRadius,
                                                ),
                                              ]
                                            : [],
                                      ),
                                      child: Text(
                                        answer,
                                        style: TextStyle(
                                          color:
                                              (_isAnswered &&
                                                  !isThisCorrectAnswer &&
                                                  !isThisSelectedWrong)
                                              ? Colors.white54
                                              : Colors.white,
                                          fontSize: 16,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ==================================================================
          // CAPA INVISIBLE GIGANTE (Toque en toda la pantalla) + SELLO + TEXTO
          // ==================================================================
          if (_isAnswered)
            Positioned.fill(
              child: GestureDetector(
                onTap: _advanceNext,
                // Le damos un ligero fondo oscuro para resaltar que ahora es un modal
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // El Sello Flotante
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Transform.rotate(
                              angle: _isCorrectMatch ? -0.1 : 0.1,
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                          decoration: BoxDecoration(
                            color: _isCorrectMatch
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (_isCorrectMatch
                                            ? Colors.greenAccent
                                            : Colors.redAccent)
                                        .withValues(alpha: 0.5),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Text(
                            _isCorrectMatch ? '¡CORRECTO!' : '¡INCORRECTO!',
                            style: const TextStyle(
                              color: darkBackground,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Texto parpadeante "Toca la pantalla para continuar"
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _pulseAnimation
                                .value, // Usa la misma animación del latido
                            child: const Text(
                              'Toca cualquier parte para continuar',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
