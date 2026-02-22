import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart'; // 👈 IMPORTANTE: Necesario para navegar
import 'package:superteach_app/config/theme/app_theme.dart';
import 'package:superteach_app/presentation/providers/auth_provider.dart';
import 'package:superteach_app/presentation/widgets/inputs/custom_text_form_field.dart';

// ============================================================================
// PANTALLA DE LOGIN (CON ACCESO A REGISTRO)
// ============================================================================

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Stack(
        children: [
          const SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: _LoginForm(), 
              ),
            ),
          ),

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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  bool isTeacher = false;
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
    final authNotifier = ref.read(authProvider.notifier);

    // ========================================================================
    // ESCUCHADOR DE EVENTOS (LISTENER)
    // ========================================================================
    ref.listen(authProvider, (previous, next) {
      
      // CASO DE ERROR
      if (next.errorMessage.isNotEmpty) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage, style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Limpieza visual de contraseña
        passwordController.clear(); 
      }

      // CASO DE ÉXITO
      if (next.status == AuthStatus.authenticated) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡ACCESO CONCEDIDO! Bienvenido', style: TextStyle(color: Colors.black)),
            backgroundColor: neonCyan,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/home'); // NAVEGACIÓN SEGURA A HOME
      }
    });

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Gap(40),
          
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
            style: textStyles.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2.0)
          ),
          Text('Access Protocol v1.0', style: textStyles.bodySmall?.copyWith(color: neonMagenta)),
          const Gap(50),

          // --- INPUT EMAIL ---
          CustomTextFormField(
            label: 'Identificación (Email)',
            hint: 'usuario@superteach.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            controller: emailController, 
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'El email es obligatorio';
              return null;
            },
          ),
          const Gap(20),
          
          // --- INPUT CONTRASEÑA ---
          CustomTextFormField(
            label: 'Contraseña',
            hint: '********',
            obscureText: true,
            prefixIcon: Icons.lock_outline,
            controller: passwordController, 
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Ingresa tu contraseña';
              return null;
            },
          ),
          
          const Gap(30),

          // --- SWITCH DE ROL ---
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: isTeacher ? neonMagenta.withOpacity(0.1) : neonCyan.withOpacity(0.1),
              border: Border.all(color: isTeacher ? neonMagenta : neonCyan, width: 2),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(color: isTeacher ? neonMagenta.withOpacity(0.4) : neonCyan.withOpacity(0.4), blurRadius: 15, spreadRadius: 1)
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isTeacher ? 'MODO: PROFESOR' : 'MODO: ESTUDIANTE',
                  style: TextStyle(color: isTeacher ? neonMagenta : neonCyan, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16),
                ),
                Switch(
                  value: isTeacher,
                  activeThumbColor: Colors.white,
                  activeTrackColor: neonMagenta,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: neonCyan,
                  onChanged: (value) => setState(() => isTeacher = value),
                ),
              ],
            ),
          ),

          const Gap(40),

          // --- BOTÓN INICIAR ---
          SizedBox(
            width: double.infinity,
            height: 55,
            child: FilledButton(
              onPressed: () {
                if (_formKey.currentState?.validate() != true) return;

                authNotifier.loginUser(
                  emailController.text.trim(), 
                  passwordController.text.trim(),
                  isTeacher 
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: neonCyan,
                foregroundColor: Colors.black,
                shadowColor: neonCyan,
                elevation: 10,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text('INICIAR SISTEMA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          const Gap(20),

          // --- NUEVO: ENLACE A REGISTRO ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('¿No tienes cuenta?', style: TextStyle(color: Colors.white54)),
              TextButton(
                // Navegación segura usando GoRouter
                onPressed: () => context.push('/register'), 
                child: const Text(
                  'Regístrate aquí', 
                  style: TextStyle(
                    color: neonCyan, 
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                    decorationColor: neonCyan,
                  )
                ),
              )
            ],
          ),
          const Gap(30), // Espacio extra al final para scrolling
        ],
      ),
    );
  }
}