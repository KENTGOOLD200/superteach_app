import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Importamos Riverpod
import 'package:gap/gap.dart';
import 'package:superteach_app/config/theme/app_theme.dart'; // 👈 IMPORTANTE: Aquí están los colores neonCyan y neonMagenta
import 'package:superteach_app/presentation/providers/auth_provider.dart'; // Importamos nuestro cerebro
import 'package:superteach_app/presentation/widgets/inputs/custom_text_form_field.dart';

// ============================================================================
// PANTALLA DE LOGIN (CONECTADA A RIVERPOD Y CON COLORES VÍVIDOS)
// ============================================================================
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    
    // 1. ESCUCHA ACTIVA (LISTENER)
    ref.listen(authProvider, (previous, next) {
      
      // Si hay un mensaje de error, mostramos un SnackBar rojo
      if (next.errorMessage.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage, style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }

      // Si el estado cambia a 'authenticated', ¡Éxito!
      if (next.status == AuthStatus.authenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡ACCESO CONCEDIDO! Bienvenido a SuperTeach', style: TextStyle(color: Colors.black)),
            backgroundColor: neonCyan, // Usamos el cian neón importado
          ),
        );
      }
    });

    // 2. OBTENEMOS EL ESTADO ACTUAL PARA LA UI
    final authState = ref.watch(authProvider);

    return Scaffold(
      // Si está cargando, bloqueamos la pantalla con un Stack
      body: Stack(
        children: [
          // El formulario de siempre
          const SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: _LoginForm(),
              ),
            ),
          ),

          // CAPA DE CARGA (Loading Overlay)
          if (authState.status == AuthStatus.checking)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: const Center(
                child: CircularProgressIndicator(color: neonCyan),
              ),
            )
        ],
      ),
    );
  }
}

class _LoginForm extends ConsumerStatefulWidget {
  const _LoginForm();

  @override
  ConsumerState<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<_LoginForm> {
  bool isTeacher = false;
  
  // Controladores
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyles = Theme.of(context).textTheme;
    // Aunque tenemos el theme, usaremos las constantes directas para más vibración

    final authNotifier = ref.read(authProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Gap(40),
        
        // --- LOGO Y TÍTULO ---
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: neonCyan.withOpacity(0.1),
            boxShadow: [
              BoxShadow(color: neonCyan.withOpacity(0.4), blurRadius: 20, spreadRadius: 2)
            ],
          ),
          child: const Icon(Icons.rocket_launch_rounded, size: 60, color: neonCyan),
        ),
        const Gap(20),
        Text('SUPERTEACH', 
          style: textStyles.headlineMedium?.copyWith(
            color: Colors.white, 
            fontWeight: FontWeight.w900, 
            letterSpacing: 2.0
          )
        ),
        Text('Access Protocol v1.0', style: textStyles.bodySmall?.copyWith(color: neonMagenta)),
        const Gap(50),

        // --- INPUTS ---
        CustomTextFormField(
          label: 'Identificación (Email)',
          hint: 'usuario@superteach.com',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
          onChanged: (value) => emailController.text = value,
        ),
        const Gap(20),
        CustomTextFormField(
          label: 'Clave de Acceso',
          hint: '******',
          obscureText: true,
          prefixIcon: Icons.lock_outline,
          onChanged: (value) => passwordController.text = value,
        ),
        
        const Gap(30),

        // --- SELECCIÓN DE ROL VIBRANTE (COLORES PUROS) ---
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            // Fondo suave según el rol
            color: isTeacher ? neonMagenta.withOpacity(0.1) : neonCyan.withOpacity(0.1),
            
            // Borde brillante
            border: Border.all(
              color: isTeacher ? neonMagenta : neonCyan,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(15),
            
            // Glow exterior
            boxShadow: [
              BoxShadow(
                color: isTeacher ? neonMagenta.withOpacity(0.4) : neonCyan.withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 1,
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isTeacher ? 'MODO: PROFESOR' : 'MODO: ESTUDIANTE',
                style: TextStyle(
                  color: isTeacher ? neonMagenta : neonCyan,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  fontSize: 16,
                ),
              ),
              Switch(
                value: isTeacher,
                activeColor: Colors.white,
                activeTrackColor: neonMagenta,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: neonCyan,
                onChanged: (value) => setState(() => isTeacher = value),
              ),
            ],
          ),
        ),

        const Gap(40),

        // --- BOTÓN DE ACCESO ---
        SizedBox(
          width: double.infinity,
          height: 55,
          child: FilledButton(
            onPressed: () {
              authNotifier.loginUser(
                emailController.text, 
                passwordController.text
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: neonCyan, // Color vibrante directo
              foregroundColor: Colors.black, // Texto negro para contraste
              shadowColor: neonCyan,
              elevation: 10,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text('INICIAR SISTEMA', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
            ),
          ),
        ),
        const Gap(20),
      ],
    );
  }
}