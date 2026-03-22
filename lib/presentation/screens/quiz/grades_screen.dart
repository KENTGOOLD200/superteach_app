import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:superteach_app/domain/entities/user.dart';
import 'package:superteach_app/config/theme/app_theme.dart';

// ============================================================================
// PANTALLA: CALIFICACIONES DE CUESTIONARIO
// ============================================================================

class GradesScreen extends StatefulWidget {
  final Map<String, dynamic> quiz;
  final User user;
  final Color themeColor;

  const GradesScreen({
    super.key,
    required this.quiz,
    required this.user,
    required this.themeColor,
  });

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  List<dynamic> _grades = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    setState(() {
      _isLoading = true;
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

      final response = await dio.get('/quizzes/${widget.quiz['_id']}/grades');

      if (response.statusCode == 200) {
        setState(() {
          _grades = response.data['grades'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar calificaciones';
        _isLoading = false;
      });
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
        title: Text(
          'Calificaciones - ${widget.quiz['topic']}',
          style: TextStyle(color: widget.themeColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _loadGrades,
            icon: Icon(Icons.refresh, color: widget.themeColor),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del cuestionario
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF121826),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: widget.themeColor.withValues(alpha: 0.3), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.quiz['topic'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${widget.quiz['questions'].length} preguntas • Máx. ${widget.quiz['maxAttempts'] ?? 0} intentos',
                    style: const TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${_grades.length} estudiante${_grades.length != 1 ? 's' : ''} han realizado el cuestionario',
                    style: TextStyle(color: widget.themeColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Lista de calificaciones
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: widget.themeColor))
                  : _errorMessage.isNotEmpty
                      ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent)))
                      : _grades.isEmpty
                          ? Center(
                              child: Text(
                                'Ningún estudiante ha realizado este cuestionario aún',
                                style: const TextStyle(color: Colors.white54),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _grades.length,
                              itemBuilder: (context, index) {
                                final grade = _grades[index];
                                final student = grade['student'];
                                final attempts = grade['attempts'] ?? [];
                                final bestAttempt = attempts.isNotEmpty
                                    ? attempts.reduce((a, b) => a['score'] > b['score'] ? a : b)
                                    : null;

                                return Card(
                                  color: const Color(0xFF121826),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    side: BorderSide(color: widget.themeColor.withValues(alpha: 0.2), width: 1),
                                  ),
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: Padding(
                                    padding: const EdgeInsets.all(15),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: widget.themeColor.withValues(alpha: 0.2),
                                              child: Text(
                                                student['fullName'][0].toUpperCase(),
                                                style: TextStyle(
                                                  color: widget.themeColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 15),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    student['fullName'],
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  Text(
                                                    student['username'],
                                                    style: const TextStyle(color: Colors.white54),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (bestAttempt != null) ...[
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: bestAttempt['score'] >= 70
                                                      ? Colors.green.withValues(alpha: 0.2)
                                                      : bestAttempt['score'] >= 50
                                                          ? Colors.orange.withValues(alpha: 0.2)
                                                          : Colors.red.withValues(alpha: 0.2),
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: bestAttempt['score'] >= 70
                                                        ? Colors.green
                                                        : bestAttempt['score'] >= 50
                                                            ? Colors.orange
                                                            : Colors.red,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Text(
                                                  '${bestAttempt['score']}/100',
                                                  style: TextStyle(
                                                    color: bestAttempt['score'] >= 70
                                                        ? Colors.green
                                                        : bestAttempt['score'] >= 50
                                                            ? Colors.orange
                                                            : Colors.red,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (attempts.isNotEmpty) ...[
                                          const SizedBox(height: 15),
                                          Text(
                                            'Intentos realizados: ${attempts.length}',
                                            style: const TextStyle(color: Colors.white54),
                                          ),
                                          const SizedBox(height: 10),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: attempts.map<Widget>((attempt) {
                                              final isBest = bestAttempt != null && attempt['_id'] == bestAttempt['_id'];
                                              return Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                decoration: BoxDecoration(
                                                  color: isBest
                                                      ? widget.themeColor.withValues(alpha: 0.2)
                                                      : const Color(0xFF0F1419),
                                                  borderRadius: BorderRadius.circular(15),
                                                  border: Border.all(
                                                    color: isBest ? widget.themeColor : Colors.white24,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      '${attempt['score']}/100',
                                                      style: TextStyle(
                                                        color: isBest ? widget.themeColor : Colors.white70,
                                                        fontWeight: isBest ? FontWeight.bold : FontWeight.normal,
                                                      ),
                                                    ),
                                                    if (isBest) ...[
                                                      const SizedBox(width: 5),
                                                      Icon(
                                                        Icons.star,
                                                        color: widget.themeColor,
                                                        size: 14,
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
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
    );
  }
}