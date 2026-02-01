import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:superteach_app/config/theme/app_theme.dart';
import 'package:superteach_app/presentation/providers/auth_provider.dart';
import 'package:superteach_app/presentation/widgets/inputs/custom_text_form_field.dart';

// ============================================================================
// PANTALLA DE LOGIN (SMART VALIDATION & UX)
// ============================================================================
// PROPÓSITO:
// 1. Maneja la entrada de datos del usuario.
// 2. Aplica limpieza de datos (.trim) para evitar errores por espacios.
// 3. Gestiona la retroalimentación visual (Carga, Errores, Éxito).
// 4. Usa un 'Form' global para validar campos vacíos antes de enviar.
// ============================================================================

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    
    // 1. ESCUCHA DE ESTADO (LISTENER)
    // Reacciona a cambios: Error -> Muestra SnackBar Rojo / Éxito -> Muestra SnackBar Cian
    ref.listen(authProvider, (previous, next) {
      if (next.errorMessage.isNotEmpty) {
        // UX: Limpiamos mensajes anteriores para que no se acumulen
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage, style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating, // Flotante se ve más moderno
          ),
        );
      }

      if (next.status == AuthStatus.authenticated) {
        // UX: Limpiamos cualquier error previo
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡ACCESO CONCEDIDO! Bienvenido', style: TextStyle(color: Colors.black)),
            backgroundColor: neonCyan,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    // Leemos el estado para saber si debemos mostrar el círculo de carga
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Capa del Formulario (SafeArea para respetar el notch)
          const SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: _LoginForm(),
              ),
            ),
          ),

          // Capa de Bloqueo (Loading Overlay)
          // Se muestra solo si estamos verificando credenciales
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

// Sub-widget con estado para manejar los controladores de texto y el Form
class _LoginForm extends ConsumerStatefulWidget {
  const _LoginForm();
  @override
  ConsumerState<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<_LoginForm> {
  // LLAVE DEL FORMULARIO: Nos permite saber si todos los inputs son válidos
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  bool isTeacher = false;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    // Buena práctica: Limpiar controladores al salir de la pantalla
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyles = Theme.of(context).textTheme;
    final authNotifier = ref.read(authProvider.notifier);

    // Envolvemos todo en 'Form' para habilitar la validación automática
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Gap(40),
          
          // --- LOGO ---
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
            onChanged: (value) => emailController.text = value,
            // VALIDACIÓN: Si retorna un String, es error. Si es null, es válido.
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'El email es obligatorio';
              return null;
            },
          ),
          const Gap(20),
          
          // --- INPUT PASSWORD ---
          CustomTextFormField(
            label: 'Clave de Acceso',
            hint: '******',
            obscureText: true,
            prefixIcon: Icons.lock_outline,
            onChanged: (value) => passwordController.text = value,
            // VALIDACIÓN DE CAMPO VACÍO
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Ingresa tu clave';
              return null;
            },
          ),
          
          const Gap(30),

          // --- SWITCH DE ROL (VIBRANTE) ---
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

          // --- BOTÓN DE INICIO ---
          SizedBox(
            width: double.infinity,
            height: 55,
            child: FilledButton(
              onPressed: () {
                // 1. VALIDACIÓN VISUAL:
                // Verifica si los campos cumplen las reglas del 'validator'.
                // Si falla, pone los bordes rojos automáticamente y detiene la función.
                if (_formKey.currentState?.validate() != true) {
                  return; 
                }

                // 2. LLAMADA AL BACKEND:
                // Usamos .trim() para limpiar espacios accidentales antes y después del texto.
                authNotifier.loginUser(
                  emailController.text.trim(), 
                  passwordController.text.trim()
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
        ],
      ),
    );
  }
}