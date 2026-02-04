// ============================================================================
// ARCHIVO: REGISTER_SCREEN.DART
// CAPA: PRESENTATION / SCREENS / AUTH
// DESCRIPCIÓN: PANTALLA DE REGISTRO (CON CAMPO USUARIO)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:superteach_app/config/helpers/app_validators.dart';
import 'package:superteach_app/config/theme/app_theme.dart';
import 'package:superteach_app/domain/entities/user.dart';
import 'package:superteach_app/presentation/providers/register_provider.dart';
import 'package:superteach_app/presentation/widgets/inputs/custom_text_form_field.dart';

class RegisterScreen extends ConsumerWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Referencias al estado y notificador
    final registerState = ref.watch(registerProvider);
    final registerNotifier = ref.read(registerProvider.notifier);
    final textStyles = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.go('/login'),
        ),
        // CONSERVADO: Tus cambios en el título
        centerTitle: true,
        title: Text('Crear Cuenta', style: textStyles.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // CONSERVADO: Tu mensaje centrado
              Center(
                child: Text('Completa todos los campos obligatorios (*)', style: textStyles.bodySmall?.copyWith(color: neonCyan)),
              ),
              const Gap(30),

              // ==============================================================
              // FORMULARIO DE DATOS
              // ==============================================================
              
              CustomTextFormField(
                label: 'Nombre Completo (*)',
                prefixIcon: Icons.person_outline,
                onChanged: registerNotifier.onNameChanged,
                errorMessage: registerState.isFormPosted ? AppValidators.name(registerState.name) : null,
              ),
              const Gap(20),

              // ⚠️ NUEVO CAMPO: USUARIO
              CustomTextFormField(
                label: 'Usuario (*)',
                hint: 'Crea un nombre de usuario único',
                prefixIcon: Icons.alternate_email,
                onChanged: registerNotifier.onUsernameChanged,
                errorMessage: registerState.isFormPosted 
                    ? (AppValidators.username(registerState.username) ?? (registerState.usernameError.isNotEmpty ? registerState.usernameError : null))
                    : null,
              ),
              const Gap(20),

              CustomTextFormField(
                label: 'Teléfono Móvil (*)',
                hint: 'Solo números (máx 10)',
                prefixIcon: Icons.phone_android_outlined,
                keyboardType: TextInputType.number,
                onChanged: registerNotifier.onPhoneChanged,
                errorMessage: registerState.isFormPosted ? AppValidators.phone(registerState.phone) : null,
              ),
              const Gap(20),

              CustomTextFormField(
                label: 'Correo Electrónico (*)',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                onChanged: registerNotifier.onEmailChanged,
                errorMessage: registerState.isFormPosted 
                    ? (AppValidators.email(registerState.email) ?? (registerState.emailError.isNotEmpty ? registerState.emailError : null))
                    : null,
              ),
              const Gap(20),

              CustomTextFormField(
                label: 'Contraseña (*)',
                hint: '8+ chars, Mayús, Minús, #, @',
                obscureText: true,
                prefixIcon: Icons.lock_outline,
                onChanged: registerNotifier.onPasswordChanged,
                errorMessage: registerState.isFormPosted ? AppValidators.password(registerState.password) : null,
              ),
              const Gap(20),

              CustomTextFormField(
                label: 'Confirmar Contraseña (*)',
                obscureText: true,
                prefixIcon: Icons.lock_reset,
                onChanged: registerNotifier.onConfirmPasswordChanged,
                errorMessage: registerState.isFormPosted && (registerState.password != registerState.confirmPassword)
                    ? 'Las contraseñas no coinciden' : null,
              ),
              const Gap(30),

              // ==============================================================
              // SELECCIÓN DE ROL
              // ==============================================================
              _RoleSelector(
                isTeacher: registerState.role == UserRole.teacher,
                onChanged: registerNotifier.onRoleChanged,
              ),
              const Gap(20),

              // ==============================================================
              // ZONA DINÁMICA DE CÓDIGO (CONSERVADA)
              // ==============================================================
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white10),
                ),
                child: registerState.role == UserRole.teacher 
                  // --- VISTA DE PROFESOR ---
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Zona de Profesor", style: TextStyle(color: neonMagenta, fontWeight: FontWeight.bold)),
                        const Gap(15),
                        CustomTextFormField(
                          label: 'Crear Código (*)',
                          hint: 'Ej: HISTORIA-2024',
                          prefixIcon: Icons.add_circle_outline,
                          onChanged: registerNotifier.onTeacherCodeChanged,
                          errorMessage: registerState.isFormPosted 
                             ? (AppValidators.classCode(registerState.teacherClassCode) ?? (registerState.classCodeError.isNotEmpty ? registerState.classCodeError : null))
                             : null,
                        ),
                      ],
                    )
                  // --- VISTA DE ESTUDIANTE (CON SWITCH) ---
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Zona de Estudiante", style: TextStyle(color: neonCyan, fontWeight: FontWeight.bold)),
                        const Gap(10),
                        
                        // SWITCH
                        SwitchListTile(
                          title: const Text('¿Tienes un Código de Clase?', style: TextStyle(color: Colors.white)),
                          subtitle: const Text('Activa si te vas a unir a una clase', style: TextStyle(color: Colors.white54, fontSize: 12)),
                          value: registerState.hasClassCode,
                          activeThumbColor: neonCyan,
                          contentPadding: EdgeInsets.zero,
                          onChanged: registerNotifier.onStudentTypeChanged,
                        ),

                        // Renderizado Condicional
                        if (registerState.hasClassCode) ...[
                          const Gap(15),
                          CustomTextFormField(
                            label: 'Ingresar Código (*)',
                            hint: 'Ej: MAT-101',
                            prefixIcon: Icons.class_outlined,
                            onChanged: registerNotifier.onStudentCodeChanged,
                            errorMessage: registerState.isFormPosted 
                               ? (AppValidators.classCode(registerState.studentClassCode) ?? (registerState.classCodeError.isNotEmpty ? registerState.classCodeError : null)) 
                               : null,
                          ),
                        ]
                      ],
                    ),
              ),

              const Gap(40),

              // ==============================================================
              // BOTÓN FINAL
              // ==============================================================
              SizedBox(
                width: double.infinity,
                height: 55,
                child: FilledButton(
                  onPressed: registerState.isPosting 
                    ? null 
                    : () async {
                        final success = await registerNotifier.onSubmit();
                        if (success && context.mounted) {
                          // ÉXITO
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('¡Bienvenido a SuperTeach!'), backgroundColor: neonCyan),
                          );
                          context.go('/login');
                        } else if (context.mounted) {
                          // ERROR
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(
                                content: Text('No se pudo crear la cuenta'), 
                                backgroundColor: Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
                             ),
                          );
                        }
                      },
                  style: FilledButton.styleFrom(
                    backgroundColor: registerState.role == UserRole.teacher ? neonMagenta : neonCyan,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: registerState.isPosting
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text('FINALIZAR REGISTRO', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const Gap(20),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget auxiliar del selector de rol (conservado)
class _RoleSelector extends StatelessWidget {
  final bool isTeacher;
  final Function(bool) onChanged;

  const _RoleSelector({required this.isTeacher, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isTeacher ? neonMagenta.withOpacity(0.1) : neonCyan.withOpacity(0.1),
        border: Border.all(color: isTeacher ? neonMagenta : neonCyan),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(isTeacher ? 'SOY PROFESOR' : 'SOY ESTUDIANTE', style: TextStyle(color: isTeacher ? neonMagenta : neonCyan, fontWeight: FontWeight.bold)),
          Switch(
            value: isTeacher,
            activeThumbColor: Colors.white,
            activeTrackColor: neonMagenta,
            inactiveTrackColor: neonCyan,
            inactiveThumbColor: Colors.white,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}