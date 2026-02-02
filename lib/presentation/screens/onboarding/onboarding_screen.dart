import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// Importamos el tema para acceder a los colores neón (neonCyan, neonMagenta)
import 'package:superteach_app/config/theme/app_theme.dart';

// ============================================================================
// PANTALLA: ONBOARDING (INTRODUCCIÓN)
// ============================================================================
// PROPÓSITO:
// Presentar los beneficios de la app al usuario nuevo.
// Navegación: Slide de 3 páginas -> Botón "Comenzar" -> Ir a Login.
// ============================================================================

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Datos de las diapositivas (Slides)
  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Bienvenido al Futuro',
      'desc': 'SuperTeach lleva tu aprendizaje al siguiente nivel con tecnología inclusiva.',
      'icon': Icons.rocket_launch_rounded,
    },
    {
      'title': 'Cuestionarios IA',
      'desc': 'Genera exámenes inteligentes en segundos y evalúa tus conocimientos.',
      'icon': Icons.psychology_rounded,
    },
    {
      'title': 'Estadísticas Reales',
      'desc': 'Visualiza tu progreso académico con gráficos de alto contraste.',
      'icon': Icons.bar_chart_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    // CORRECCIÓN: Eliminamos la variable 'colors' que no se usaba.
    // Usaremos directamente las constantes del tema o Theme.of(context) donde sea necesario.
    
    final isLastPage = _currentPage == _slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 1. BOTÓN SALTAR (Arriba a la derecha)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.go('/login'), // Salta directo al Login
                child: const Text('SALTAR', style: TextStyle(color: Colors.white54)),
              ),
            ),

            // 2. CARRUSEL DE INFORMACIÓN
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Círculo de Neón (Usamos neonCyan importado de app_theme)
                        Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: neonCyan.withOpacity(0.1),
                            boxShadow: [
                              BoxShadow(color: neonCyan.withOpacity(0.5), blurRadius: 30, spreadRadius: 5)
                            ],
                          ),
                          child: Icon(slide['icon'], size: 80, color: neonCyan),
                        ),
                        const SizedBox(height: 40),
                        
                        // Título
                        Text(slide['title'], 
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white, fontWeight: FontWeight.bold
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        
                        // Descripción
                        Text(slide['desc'],
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 3. INDICADORES Y BOTÓN DE ACCIÓN
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Puntos indicadores (Dots animados)
                  Row(
                    children: List.generate(_slides.length, (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 10),
                      height: 10,
                      width: _currentPage == index ? 30 : 10, // El activo es más largo
                      decoration: BoxDecoration(
                        // Si es la página actual, usa Magenta, si no, blanco transparente
                        color: _currentPage == index ? neonMagenta : Colors.white24,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    )),
                  ),

                  // Botón Siguiente / Comenzar
                  FilledButton(
                    onPressed: () {
                      if (isLastPage) {
                        context.go('/login'); // Finalizar Onboarding e ir a Login
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300), 
                          curve: Curves.easeInOut
                        );
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: isLastPage ? neonCyan : const Color(0xFF1E2330),
                      foregroundColor: isLastPage ? Colors.black : Colors.white,
                    ),
                    child: Text(isLastPage ? 'COMENZAR' : 'SIGUIENTE'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}