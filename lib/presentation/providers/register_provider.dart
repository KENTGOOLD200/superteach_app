// ============================================================================
// ARCHIVO: REGISTER_PROVIDER.DART
// CAPA: PRESENTATION / PROVIDERS
// DESCRIPCIÓN: GESTOR DE ESTADO DEL FORMULARIO DE REGISTRO (RIVERPOD 2.0)
// ============================================================================

import 'dart:async'; // Necesario para el Debounce (Timer)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superteach_app/config/helpers/app_validators.dart';
import 'package:superteach_app/domain/entities/user.dart';
import 'package:superteach_app/infrastructure/datasources/auth_datasource_impl.dart';

// ============================================================================
// 1. CLASE DE ESTADO (REGISTER STATE)
// ============================================================================
// Almacena una "foto" inmutable de todos los campos del formulario y sus errores.
class RegisterState {
  final bool isPosting;        // Indica si se está enviando a la BD (Cargando)
  final bool isFormPosted;     // Indica si el usuario ya presionó "Enviar" (para activar alertas rojas)
  final bool isValid;          // Resumen: ¿Todo el formulario es correcto?
  
  // --- DATOS DEL USUARIO ---
  final String name;
  final String email;
  final String password;
  final String confirmPassword;
  final String phone;
  final String photoUrl;
  final UserRole role;         // Enum: teacher o student

  // --- LÓGICA DE CLASES (SCHOOL LOGIC) ---
  final bool hasClassCode;     // TRUE: Estudiante se une a clase. FALSE: Estudiante independiente.
  final String teacherClassCode; // Código que el Profesor CREA.
  final String studentClassCode; // Código que el Estudiante INGRESA.
  
  // --- ERRORES DINÁMICOS (ASÍNCRONOS) ---
  final String emailError;       // Ej: "El correo ya existe"
  final String classCodeError;   // Ej: "El código no existe" o "Ya está en uso"

  RegisterState({
    this.isPosting = false,
    this.isFormPosted = false,
    this.isValid = false,
    this.name = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.phone = '',
    this.photoUrl = '',
    this.role = UserRole.student,
    this.hasClassCode = false, // Por defecto: Estudiante Independiente (Sin código)
    this.teacherClassCode = '',
    this.studentClassCode = '',
    this.emailError = '',
    this.classCodeError = '',
  });

  // Método copyWith para actualizar el estado inmutable
  RegisterState copyWith({
    bool? isPosting,
    bool? isFormPosted,
    bool? isValid,
    String? name,
    String? email,
    String? password,
    String? confirmPassword,
    String? phone,
    String? photoUrl,
    UserRole? role,
    bool? hasClassCode,
    String? teacherClassCode,
    String? studentClassCode,
    String? emailError,
    String? classCodeError,
  }) => RegisterState(
    isPosting: isPosting ?? this.isPosting,
    isFormPosted: isFormPosted ?? this.isFormPosted,
    isValid: isValid ?? this.isValid,
    name: name ?? this.name,
    email: email ?? this.email,
    password: password ?? this.password,
    confirmPassword: confirmPassword ?? this.confirmPassword,
    phone: phone ?? this.phone,
    photoUrl: photoUrl ?? this.photoUrl,
    role: role ?? this.role,
    hasClassCode: hasClassCode ?? this.hasClassCode,
    teacherClassCode: teacherClassCode ?? this.teacherClassCode,
    studentClassCode: studentClassCode ?? this.studentClassCode,
    emailError: emailError ?? this.emailError,
    classCodeError: classCodeError ?? this.classCodeError,
  );
}

// ============================================================================
// 2. NOTIFIER (REGISTER NOTIFIER)
// ============================================================================
// Contiene la lógica de negocio, validaciones y comunicación con el Datasource.
class RegisterNotifier extends AutoDisposeNotifier<RegisterState> {
  
  // Instancia del Mock Database
  final authDataSource = MockAuthDataSource();
  Timer? _debounceTimer; // Timer para no saturar con peticiones en cada tecla

  @override
  RegisterState build() => RegisterState();

  // --- MÉTODOS DE ACTUALIZACIÓN DE CAMPOS (INPUTS) ---

  void onNameChanged(String value) { 
    state = state.copyWith(name: value); 
    _validateForm(); 
  }

  void onPasswordChanged(String value) { 
    state = state.copyWith(password: value); 
    _validateForm(); 
  }

  void onConfirmPasswordChanged(String value) { 
    state = state.copyWith(confirmPassword: value); 
    _validateForm(); 
  }

  void onPhoneChanged(String value) { 
    state = state.copyWith(phone: value); 
    _validateForm(); 
  }

  void onPhotoUrlChanged(String value) { 
    state = state.copyWith(photoUrl: value); 
    _validateForm(); 
  }

  // --- VALIDACIÓN DE EMAIL (ASÍNCRONA) ---
  void onEmailChanged(String value) {
    state = state.copyWith(email: value.trim(), emailError: '');
    
    // 1. Validación Regex inmediata
    if (AppValidators.email(value) != null) { 
      _validateForm(); 
      return; 
    }

    // 2. Validación en BD (Debounce de 500ms)
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      final exists = await authDataSource.checkEmailExists(value.trim());
      if (exists) {
        // ERROR ESPECÍFICO SOLICITADO
        state = state.copyWith(emailError: 'Ese correo electrónico ya está ligado a otra cuenta');
      }
      _validateForm();
    });
  }

  // --- GESTIÓN DE ROLES ---
  void onRoleChanged(bool isTeacher) {
    state = state.copyWith(
      role: isTeacher ? UserRole.teacher : UserRole.student,
      hasClassCode: false, // Resetear switch al cambiar de rol
      teacherClassCode: '',
      studentClassCode: '',
      classCodeError: '',
    );
    _validateForm();
  }

  // --- LÓGICA DE ESTUDIANTE (SWITCH DE CÓDIGO) ---
  void onStudentTypeChanged(bool hasCode) {
    state = state.copyWith(
      hasClassCode: hasCode,
      classCodeError: '', // Limpiamos errores al cambiar el switch
    );
    _validateForm();
  }

  // --- LÓGICA DE CÓDIGOS DE CLASE (PROFESOR VS ALUMNO) ---
  
  // Caso Profesor: Crea un código (Debe ser único)
  void onTeacherCodeChanged(String value) {
    state = state.copyWith(teacherClassCode: value.toUpperCase(), classCodeError: '');
    if (value.length < 4) { _validateForm(); return; }
    
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      final exists = await authDataSource.checkClassCodeExists(value);
      if (exists) {
        state = state.copyWith(classCodeError: 'Este código ya está en uso, elige otro.');
      }
      _validateForm();
    });
  }

  // Caso Estudiante: Ingresa código (Debe existir)
  void onStudentCodeChanged(String value) {
    state = state.copyWith(studentClassCode: value.toUpperCase(), classCodeError: '');
    if (value.length < 4) { _validateForm(); return; }
    
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      final exists = await authDataSource.checkClassCodeExists(value);
      if (!exists) {
        state = state.copyWith(classCodeError: 'Este código de clase no existe');
      }
      _validateForm();
    });
  }

  // --- MÉTODO CENTRAL DE VALIDACIÓN ---
  // Revisa todos los campos para decidir si 'isValid' es true o false.
  void _validateForm() {
    final nameOk = AppValidators.name(state.name) == null;
    final emailOk = AppValidators.email(state.email) == null && state.emailError.isEmpty;
    final phoneOk = AppValidators.phone(state.phone) == null;
    final passOk = AppValidators.password(state.password) == null;
    final confirmOk = state.password == state.confirmPassword;
    final photoOk = AppValidators.photoUrl(state.photoUrl) == null;

    bool classOk = true;
    
    // Lógica Condicional de Clases
    if (state.role == UserRole.teacher) {
      // Profesor: Obligatorio tener código válido y único
      classOk = AppValidators.classCode(state.teacherClassCode) == null && state.classCodeError.isEmpty;
    } else {
      // Estudiante: 
      // Si switch apagado (!hasClassCode) -> Válido (Independiente)
      // Si switch encendido -> Obligatorio tener código válido y existente
      if (!state.hasClassCode) {
        classOk = true; 
      } else {
        classOk = AppValidators.classCode(state.studentClassCode) == null && state.classCodeError.isEmpty;
      }
    }

    state = state.copyWith(
      isValid: nameOk && emailOk && phoneOk && passOk && confirmOk && photoOk && classOk
    );
  }

  // --- ENVÍO DEL FORMULARIO (SUBMIT) ---
  Future<bool> onSubmit() async {
    state = state.copyWith(isFormPosted: true); // Activa los bordes rojos
    _validateForm();
    if (!state.isValid) return false;

    state = state.copyWith(isPosting: true); // Activa spinner de carga

    try {
      // Generación de Avatar por defecto si no hay foto
      String finalPhoto = state.photoUrl.trim();
      if (finalPhoto.isEmpty) {
        final cleanName = state.name.trim().replaceAll(' ', '+');
        finalPhoto = "https://ui-avatars.com/api/?name=$cleanName&background=00FFFF&color=000&size=256"; 
      }

      // Llamada al Datasource
      await authDataSource.register(
        email: state.email.trim(),
        password: state.password,
        name: state.name.trim(),
        role: state.role == UserRole.teacher ? 'teacher' : 'student',
        phone: state.phone.trim(),
        photoUrl: finalPhoto,
        createdClassCode: state.role == UserRole.teacher ? state.teacherClassCode : null,
      );
      
      state = state.copyWith(isPosting: false);
      return true;
    } catch (e) {
      // Captura de errores del backend (ej: Email duplicado)
      state = state.copyWith(isPosting: false, emailError: e.toString());
      return false;
    }
  }
}

// ============================================================================
// 3. PROVIDER GLOBAL (EXPOSICIÓN)
// ============================================================================
final registerProvider = NotifierProvider.autoDispose<RegisterNotifier, RegisterState>(() {
  return RegisterNotifier();
});