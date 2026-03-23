import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:superteach_app/domain/entities/user.dart';
import 'package:superteach_app/config/theme/app_theme.dart';
import 'package:superteach_app/config/api_client.dart';

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
  bool _isLoading = true;
  String _errorMessage = '';
  List<dynamic> _studentGrades = [];

  // Variables para las estadísticas globales
  int _totalClassAttempts = 0;
  int _totalCorrect = 0;
  int _totalIncorrect = 0;
  double _classAverage = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchGrades();
  }

  Future<void> _fetchGrades() async {
    try {
      final dio = await ApiClient.authenticatedClient();
      final response = await dio.get('/quizzes/${widget.quiz['_id']}/grades');

      if (response.statusCode == 200) {
        final rawGrades = response.data['grades'] as List;

        // 🛡️ REGLA DE ORO: Filtramos para que NO aparezca el profesor
        // Si el ID del estudiante es exactamente igual al ID del usuario actual (el profe), lo ignoramos.
        // 🛡️ REGLA DE ORO: Filtramos por NOMBRE DE USUARIO (100% infalible)
        final studentsOnly = rawGrades.where((g) {
          final studentUsername = g['student']['username']?.toString() ?? '';
          return studentUsername != widget.user.username; 
        }).toList();

        int sumScores = 0;
        int totalValidStudents = 0;

        for (var student in studentsOnly) {
          final attempts = student['attempts'] as List;
          if (attempts.isNotEmpty) {
            _totalClassAttempts += attempts.length;
            
            // Calculamos mejor nota del alumno
            final bestAttempt = attempts.reduce((a, b) => a['score'] > b['score'] ? a : b);
            student['bestScore'] = bestAttempt['score'];
            
            sumScores += (bestAttempt['score'] as num).toInt();
            totalValidStudents++;

            // Sumamos aciertos y errores para el pastel
            for (var attempt in attempts) {
              _totalCorrect += (attempt['correctAnswers'] as num).toInt();
              final totalQ = (attempt['totalQuestions'] as num).toInt();
              _totalIncorrect += (totalQ - (attempt['correctAnswers'] as num).toInt());
            }
          } else {
            student['bestScore'] = 0;
          }
        }

        if (totalValidStudents > 0) {
          _classAverage = sumScores / totalValidStudents;
        }

        setState(() {
          _studentGrades = studentsOnly; // 👈 Guardamos la lista ya filtrada
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'No se pudieron cargar las calificaciones.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 AHORA USAMOS UN TAB CONTROLLER PARA DIVIDIR EN DOS PANTALLAS
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: darkBackground,
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A0E17),
          elevation: 0,
          iconTheme: IconThemeData(color: widget.themeColor),
          title: Text(
            'Calificaciones - ${widget.quiz['topic']}', 
            style: TextStyle(color: widget.themeColor, fontWeight: FontWeight.bold, fontSize: 18)
          ),
          bottom: TabBar(
            indicatorColor: widget.themeColor,
            labelColor: widget.themeColor,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(icon: Icon(Icons.people_alt_outlined), text: 'Alumnos'),
              Tab(icon: Icon(Icons.pie_chart_outline), text: 'Estadísticas'),
            ],
          ),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: widget.themeColor))
            : _errorMessage.isNotEmpty
                ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent)))
                : TabBarView(
                    children: [
                      _buildStudentsList(), // Pestaña 1 (Tu diseño)
                      _buildStatistics(),   // Pestaña 2 (El Pastel)
                    ],
                  ),
      ),
    );
  }

  // ========================================================================
  // PESTAÑA 1: LISTA DE ALUMNOS (MANTENIENDO TU DISEÑO)
  // ========================================================================
  Widget _buildStudentsList() {
    if (_studentGrades.isEmpty) {
      return const Center(child: Text('Aún no hay alumnos evaluados.', style: TextStyle(color: Colors.white54)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: _studentGrades.length,
      itemBuilder: (context, index) {
        final data = _studentGrades[index];
        final student = data['student'];
        final attempts = data['attempts'] as List;
        final bestScore = data['bestScore'];

        final String fullName = student['fullName'] ?? 'Desconocido';
        final String initials = fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';

        return Card(
          color: const Color(0xFF121826),
          margin: const EdgeInsets.only(bottom: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: widget.themeColor.withOpacity(0.3), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: widget.themeColor.withOpacity(0.2),
                  child: Text(initials, style: TextStyle(color: widget.themeColor, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('@${student['username']}', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                      const SizedBox(height: 10),
                      Text('Intentos realizados: ${attempts.length}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.themeColor.withOpacity(0.1),
                          border: Border.all(color: widget.themeColor),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$bestScore/100 ★', 
                          style: TextStyle(color: widget.themeColor, fontWeight: FontWeight.bold, fontSize: 12)
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: bestScore >= 70 ? Colors.greenAccent : Colors.redAccent),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$bestScore/100',
                    style: TextStyle(
                      color: bestScore >= 70 ? Colors.greenAccent : Colors.redAccent,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ========================================================================
  // PESTAÑA 2: ESTADÍSTICAS EN PASTEL
  // ========================================================================
  Widget _buildStatistics() {
    if (_totalClassAttempts == 0) {
      return const Center(child: Text('No hay datos suficientes para graficar.', style: TextStyle(color: Colors.white54)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tarjeta de Promedio
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF121826),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: widget.themeColor.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Text('PROMEDIO DE LA CLASE', style: TextStyle(color: Colors.white54, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(
                  '${_classAverage.toStringAsFixed(1)} / 100',
                  style: TextStyle(
                    color: _classAverage >= 70 ? Colors.greenAccent : Colors.redAccent,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Gráfico de Pastel
          const Text('Aciertos vs Errores (Toda la clase)', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                sectionsSpace: 5,
                centerSpaceRadius: 60,
                sections: [
                  PieChartSectionData(
                    color: Colors.greenAccent,
                    value: _totalCorrect.toDouble(),
                    title: 'Correctas\n$_totalCorrect',
                    radius: 70,
                    titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkBackground),
                  ),
                  PieChartSectionData(
                    color: Colors.redAccent,
                    value: _totalIncorrect.toDouble(),
                    title: 'Errores\n$_totalIncorrect',
                    radius: 70,
                    titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}