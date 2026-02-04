// ============================================================================
// ARCHIVO: REGISTER_PROVIDER.DART
// CAPA: PRESENTATION / PROVIDERS
// DESCRIPCIÓN: GESTOR DE ESTADO DEL REGISTRO (CON USUARIO ÚNICO)
// ============================================================================

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superteach_app/config/helpers/app_validators.dart';
import 'package:superteach_app/domain/entities/user.dart';
import 'package:superteach_app/infrastructure/datasources/auth_datasource_impl.dart';

// 1. ESTADO
class RegisterState {
  final bool isPosting;
  final bool isFormPosted;
  final bool isValid;

  // --- DATOS DEL USUARIO ---
  final String name;
  final String username; // ⚠️ NUEVO CAMPO
  final String email;
  final String password;
  final String confirmPassword;
  final String phone;
  final UserRole role;

  // --- ESCUELA ---
  final bool hasClassCode;
  final String teacherClassCode;
  final String studentClassCode;
  
  // --- ERRORES ---
  final String emailError;
  final String usernameError; // ⚠️ NUEVO ERROR
  final String classCodeError;

  RegisterState({
    this.isPosting = false,
    this.isFormPosted = false,
    this.isValid = false,
    this.name = '',
    this.username = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.phone = '',
    this.role = UserRole.student,
    this.hasClassCode = false,
    this.teacherClassCode = '',
    this.studentClassCode = '',
    this.emailError = '',
    this.usernameError = '',
    this.classCodeError = '',
  });

  RegisterState copyWith({
    bool? isPosting,
    bool? isFormPosted,
    bool? isValid,
    String? name,
    String? username,
    String? email,
    String? password,
    String? confirmPassword,
    String? phone,
    UserRole? role,
    bool? hasClassCode,
    String? teacherClassCode,
    String? studentClassCode,
    String? emailError,
    String? usernameError,
    String? classCodeError,
  }) => RegisterState(
    isPosting: isPosting ?? this.isPosting,
    isFormPosted: isFormPosted ?? this.isFormPosted,
    isValid: isValid ?? this.isValid,
    name: name ?? this.name,
    username: username ?? this.username,
    email: email ?? this.email,
    password: password ?? this.password,
    confirmPassword: confirmPassword ?? this.confirmPassword,
    phone: phone ?? this.phone,
    role: role ?? this.role,
    hasClassCode: hasClassCode ?? this.hasClassCode,
    teacherClassCode: teacherClassCode ?? this.teacherClassCode,
    studentClassCode: studentClassCode ?? this.studentClassCode,
    emailError: emailError ?? this.emailError,
    usernameError: usernameError ?? this.usernameError,
    classCodeError: classCodeError ?? this.classCodeError,
  );
}

// 2. NOTIFIER
class RegisterNotifier extends AutoDisposeNotifier<RegisterState> {
  final authDataSource = MockAuthDataSource();
  Timer? _debounceTimer;

  @override
  RegisterState build() => RegisterState();

  // --- SETTERS ---
  void onNameChanged(String value) { 
    state = state.copyWith(name: value); 
    _validateForm(); 
  }

  void onPasswordChanged(String value) { state = state.copyWith(password: value); _validateForm(); }
  void onConfirmPasswordChanged(String value) { state = state.copyWith(confirmPassword: value); _validateForm(); }
  void onPhoneChanged(String value) { state = state.copyWith(phone: value); _validateForm(); }

  // ⚠️ NUEVO: VALIDACIÓN DE USUARIO ÚNICO
  void onUsernameChanged(String value) {
    state = state.copyWith(username: value.trim(), usernameError: '');
    
    if (AppValidators.username(value) != null) { 
      _validateForm(); return; 
    }

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      final exists = await authDataSource.checkUsernameExists(value.trim());
      if (exists) {
        state = state.copyWith(usernameError: 'Este nombre de usuario ya está en uso');
      }
      _validateForm();
    });
  }

  void onEmailChanged(String value) {
    state = state.copyWith(email: value.trim(), emailError: '');
    if (AppValidators.email(value) != null) { _validateForm(); return; }
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      final exists = await authDataSource.checkEmailExists(value.trim());
      if (exists) state = state.copyWith(emailError: 'Ese correo electrónico ya está ligado a otra cuenta');
      _validateForm();
    });
  }

  void onRoleChanged(bool isTeacher) {
    state = state.copyWith(
      role: isTeacher ? UserRole.teacher : UserRole.student,
      hasClassCode: false,
      teacherClassCode: '',
      studentClassCode: '',
      classCodeError: '',
    );
    _validateForm();
  }

  void onStudentTypeChanged(bool hasCode) {
    state = state.copyWith(hasClassCode: hasCode, classCodeError: '');
    _validateForm();
  }

  void onTeacherCodeChanged(String value) {
    state = state.copyWith(teacherClassCode: value.toUpperCase(), classCodeError: '');
    if (value.length < 4) { _validateForm(); return; }
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      final exists = await authDataSource.checkClassCodeExists(value);
      if (exists) state = state.copyWith(classCodeError: 'Este código ya está en uso, elige otro.');
      _validateForm();
    });
  }

  void onStudentCodeChanged(String value) {
    state = state.copyWith(studentClassCode: value.toUpperCase(), classCodeError: '');
    if (value.length < 4) { _validateForm(); return; }
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      final exists = await authDataSource.checkClassCodeExists(value);
      if (!exists) state = state.copyWith(classCodeError: 'Este código de clase no existe');
      _validateForm();
    });
  }

  // --- VALIDACIÓN CENTRAL ---
  void _validateForm() {
    // Valida nombre (solo letras)
    final nameOk = AppValidators.name(state.name) == null;
    
    // ⚠️ Valida usuario único
    final usernameOk = AppValidators.username(state.username) == null && state.usernameError.isEmpty;

    final emailOk = AppValidators.email(state.email) == null && state.emailError.isEmpty;
    final phoneOk = AppValidators.phone(state.phone) == null;
    final passOk = AppValidators.password(state.password) == null;
    final confirmOk = state.password == state.confirmPassword;

    bool classOk = true;
    if (state.role == UserRole.teacher) {
      classOk = AppValidators.classCode(state.teacherClassCode) == null && state.classCodeError.isEmpty;
    } else {
      if (!state.hasClassCode) {
        classOk = true; 
      } else {
        classOk = AppValidators.classCode(state.studentClassCode) == null && state.classCodeError.isEmpty;
      }
    }

    state = state.copyWith(
      isValid: nameOk && usernameOk && emailOk && phoneOk && passOk && confirmOk && classOk
    );
  }

  // --- SUBMIT ---
  Future<bool> onSubmit() async {
    state = state.copyWith(isFormPosted: true);
    _validateForm();
    if (!state.isValid) return false;

    state = state.copyWith(isPosting: true);

    try {
      await authDataSource.register(
        email: state.email.trim(),
        password: state.password,
        name: state.name.trim(),
        username: state.username.trim(), // ⚠️ Se envía
        role: state.role == UserRole.teacher ? 'teacher' : 'student',
        phone: state.phone.trim(),
        createdClassCode: state.role == UserRole.teacher ? state.teacherClassCode : null,
      );
      
      state = state.copyWith(isPosting: false);
      return true;
    } catch (e) {
      state = state.copyWith(isPosting: false, emailError: e.toString());
      return false;
    }
  }
}

final registerProvider = NotifierProvider.autoDispose<RegisterNotifier, RegisterState>(() {
  return RegisterNotifier();
});