import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart'; // Plugin para recortar formato 1:1
import 'package:flutter/foundation.dart' show kIsWeb; // Para detectar si estamos en Chrome/Web
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';

import 'package:superteach_app/config/helpers/app_validators.dart';

// Importaciones de tu proyecto
import 'package:superteach_app/config/theme/app_theme.dart';
import 'package:superteach_app/config/api_client.dart';
import 'package:superteach_app/presentation/providers/auth_provider.dart';
import 'package:superteach_app/presentation/widgets/inputs/custom_text_form_field.dart';

// ============================================================================
// PANTALLA: MI PERFIL (INTEGRACIÓN NATIVA DE CÁMARA, GALERÍA Y RECORTADOR)
// ============================================================================

class ProfileScreen extends ConsumerStatefulWidget {
  final String currentName;
  final String username;
  final String phone;                   
  final String profilePicture;
  final String role;
  final bool hasClassCode;
  final String token; // 🛡️ Token JWT para autorizar la petición PUT

  const ProfileScreen({
    super.key,
    required this.currentName,
    required this.username,
    required this.phone,
    required this.profilePicture,
    required this.role,
    required this.hasClassCode,
    required this.token,
  });

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // ⚠️ TRUCO WEB/MÓVIL: Usamos Bytes (Uint8List) en lugar de File.
  // Esto evita que la aplicación colapse al ejecutarse en navegadores web (Chrome).
  Uint8List? _imageBytes;
  String _profilePicture = '';
  final ImagePicker _picker = ImagePicker();

  // Variables para controlar el estado de la pantalla
  bool _isEditing = false;
  bool _isSaving = false;
  bool _hasSubmitted = false; // Para activar validación visual en el formulario

  // Clave del formulario (para validar antes de guardar)
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto para los campos del formulario
  late TextEditingController _nameCtrl;
  late TextEditingController _userCtrl;
  late TextEditingController _phoneCtrl;

  // 🎨 COLOR DINÁMICO: Asigna automáticamente Magenta (Profesor) o Cian (Estudiante)
  Color get themeColor => widget.role.toLowerCase() == 'teacher' ? neonMagenta : neonCyan;

  @override
  void initState() {
    super.initState();
    // Inicializamos las cajas de texto con los datos que provienen de la BD
    _nameCtrl = TextEditingController(text: widget.currentName);
    _userCtrl = TextEditingController(text: widget.username);
    _phoneCtrl = TextEditingController(text: widget.phone);

    // Guardamos la URL/base64 original para poder actualizarla cuando cambie en el provider
    _profilePicture = widget.profilePicture;
    _imageBytes = _decodeProfileImage(_profilePicture);
  }

  @override
  void dispose() {
    // Limpieza de memoria obligatoria
    _nameCtrl.dispose();
    _userCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // ==========================================================================
  // FUNCIÓN NATIVA: ELEGIR IMAGEN Y RECORTAR (COMPATIBLE CON WEB Y MÓVIL)
  // ==========================================================================
  Future<void> _pickAndCropImage(ImageSource source) async {
    // 1. GESTIÓN DE PERMISOS NATIVOS (Solo se ejecuta en dispositivos móviles)
    if (!kIsWeb && source == ImageSource.camera) {
      var status = await Permission.camera.request();
      if (status.isPermanentlyDenied) {
        openAppSettings(); // Lo mandamos a la configuración del celular
        return;
      } else if (!status.isGranted) {
        _showSnackBar('Permiso de cámara denegado.', isError: true);
        return;
      }
    }

    try {
      // 2. ABRIR CÁMARA O GALERÍA
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile == null) return; // Si el usuario canceló, no hacemos nada

      // 🛡️ PROTECCIÓN ANTI-CRASH: Verificamos que la pantalla siga abierta
      if (!mounted) return; 

      // 3. RECORTADOR DE IMAGEN (Cuadrado perfecto 1:1)
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1), // 👈 Fuerza el cuadrado
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Recortar Perfil',
            toolbarColor: darkBackground,
            toolbarWidgetColor: themeColor,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true, // Bloquea la forma
          ),
          IOSUiSettings(
            title: 'Recortar Perfil', 
            aspectRatioLockEnabled: true,
          ),
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.page, // 👈 Evita el overflow en Web
          ),
        ],
      );

      // 4. GUARDAR EN MEMORIA RAM
      if (croppedFile != null) { 
        final bytes = await croppedFile.readAsBytes();
        setState(() => _imageBytes = bytes);
        _showSnackBar('¡Imagen lista para guardar!');
      }
    } catch (e) {
      _showSnackBar('Ocurrió un error al procesar la imagen.', isError: true);
    }
  }

  // ==========================================================================
  // CONEXIÓN AL BACKEND: GUARDAR CAMBIOS Y FOTO
  // ==========================================================================
  Future<void> _saveChanges() async {
    setState(() {
      _hasSubmitted = true;
      _isSaving = true;
    });

    // Validación local antes de realizar la petición
    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() => _isSaving = false);
      _showSnackBar('Corrige los campos marcados antes de guardar.', isError: true);
      return;
    }

    try {
      String? base64Image;
      if (_imageBytes != null) {
        base64Image = "data:image/png;base64,${base64Encode(_imageBytes!)}";
      }

      print("⏳ Enviando petición a la API..."); // Se verá en la consola de VS Code

      final response = await ApiClient.client.put(
        '/users/profile',
        data: {
          "name": _nameCtrl.text.trim(),
          "username": _userCtrl.text.trim(),
          "phone": _phoneCtrl.text.trim(),
          "profilePicture": ?base64Image, 
        },
        options: Options(
          headers: {
            // 🔐 Necesitamos enviar el token JWT para que el middleware verifyToken permita la petición
            'Authorization': 'Bearer ${widget.token}',
          },
        ),
      );

      if (response.statusCode == 200) {
        // 1. Extraemos los datos que el backend pudiera haber devuelto
        final payload = response.data is Map ? response.data as Map<String, dynamic> : {};
        final serverUser = (payload['user'] ?? payload['data'] ?? payload) as Map<String, dynamic>?;

        // 2. Valores que el usuario escribió (y que queremos asegurar que queden guardados)
        final sentName = _nameCtrl.text.trim();
        final sentUsername = _userCtrl.text.trim();
        final sentPhone = _phoneCtrl.text.trim();
        final sentProfile = base64Image;

        // 3. Mezclamos lo que mandamos + lo que nos devolvió el servidor
        final finalName = (serverUser != null ? serverUser['name'] as String? : null) ?? sentName;
        final finalUsername = (serverUser != null ? serverUser['username'] as String? : null) ?? sentUsername;
        final finalPhone = (serverUser != null ? serverUser['phone'] as String? : null) ?? sentPhone;
        final serverPic = serverUser != null ? serverUser['profilePicture'] as String? : null;
        final finalProfilePicture = (serverPic != null && serverPic.isNotEmpty) ? serverPic : sentProfile;

        // 4. Actualizamos el AuthProvider (estado y persistencia local)
        ref.read(authProvider.notifier).updateUserProfile(
          fullName: finalName,
          username: finalUsername,
          phone: finalPhone,
          profilePicture: finalProfilePicture,
        );

        // 5. Actualizamos los campos de la UI (incluyendo la imagen) para que se vea en el mismo momento
        setState(() {
          _isEditing = false;
          _nameCtrl.text = finalName;
          _userCtrl.text = finalUsername;
          _phoneCtrl.text = finalPhone;

          _profilePicture = finalProfilePicture ?? '';
          _imageBytes = _decodeProfileImage(_profilePicture);
        });

        _showSnackBar('¡Perfil actualizado correctamente en la nube!');
      } else {
        // Mostrar mensaje cuando el backend responde con 4xx/5xx
        final errorMsg = (response.data != null && response.data is Map && response.data['error'] != null)
            ? response.data['error']
            : response.statusMessage ?? 'Error inesperado (${response.statusCode})';
        _showSnackBar('Error: $errorMsg', isError: true);
      }
      
    } on DioException catch (e) {
      // 🚦 ATRAPAMOS EL ERROR EXACTO QUE ENVÍA NODE.JS
      String errorMsg = 'Error del servidor';
      if (e.response != null && e.response?.data != null) {
        // Si Node.js mandó un JSON con { "error": "mensaje..." }
        errorMsg = e.response?.data['error'] ?? e.response?.statusMessage ?? 'Error desconocido';
      } else {
        // Si el servidor ni siquiera respondió (ej. IP incorrecta)
        errorMsg = e.message ?? 'Error de conexión';
      }
      print("❌ Error de API: $errorMsg"); 
      _showSnackBar('Error: $errorMsg', isError: true);
      
    } catch (e) {
      print("❌ Error inesperado: $e");
      _showSnackBar('Ocurrió un error inesperado.', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ==========================================================================
  // WIDGET DE MENSAJES (Sincronizado con el tema Cyberpunk)
  // ==========================================================================
  Uint8List? _decodeProfileImage(String? profilePicture) {
    if (profilePicture == null || profilePicture.isEmpty) return null;
    if (!profilePicture.startsWith('data:image')) return null;

    try {
      return base64Decode(profilePicture.split(',').last);
    } catch (_) {
      return null;
    }
  }

  ImageProvider? _getAvatarImage() {
    // Prioriza la imagen que el usuario haya elegido en esta pantalla
    if (_imageBytes != null) {
      return MemoryImage(_imageBytes!);
    }

    // Si el usuario ya tenía una foto en su perfil (URL o base64), la usamos
    if (_profilePicture.isNotEmpty) {
      if (_profilePicture.startsWith('data:image')) {
        final decoded = _decodeProfileImage(_profilePicture);
        return decoded != null ? MemoryImage(decoded) : null;
      }
      return NetworkImage(_profilePicture);
    }

    return null;
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: darkBackground, fontWeight: FontWeight.bold)),
        backgroundColor: isError ? Colors.redAccent : themeColor,
      )
    );
  }

  // ==========================================================================
  // INTERFAZ DE USUARIO (UI)
  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    // REGLA DE NEGOCIO: Un estudiante matriculado no puede cambiar su nombre
    final bool canEditName = !(widget.role.toLowerCase() == 'student' && widget.hasClassCode);

    // Escuchamos el estado de auth para mantener el formulario en sincronía con el usuario activo.
    // Esto cubre el caso en que el usuario llega a esta pantalla con datos que aún no estaban cargados.
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user != null && !_isEditing) {
      // Solo actualizamos si el usuario cambió (o si en el estado actual no tenemos datos)
      final shouldSyncFields =
          _nameCtrl.text != user.fullName ||
          _userCtrl.text != user.username ||
          _phoneCtrl.text != user.phone ||
          _profilePicture != user.profilePicture;

      if (shouldSyncFields) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          setState(() {
            _nameCtrl.text = user.fullName;
            _userCtrl.text = user.username;
            _phoneCtrl.text = user.phone;
            _profilePicture = user.profilePicture;
            _imageBytes = _decodeProfileImage(_profilePicture);
          });
        });
      }
    }

    // También reaccionamos si cambia el estado (por ejemplo, al guardar perfil)
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (!mounted) return;
      final changedUser = next.user;
      if (changedUser == null) return;

      if (!_isEditing) {
        final shouldSyncFields =
            _nameCtrl.text != changedUser.fullName ||
            _userCtrl.text != changedUser.username ||
            _phoneCtrl.text != changedUser.phone ||
            _profilePicture != changedUser.profilePicture;

        if (shouldSyncFields) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _nameCtrl.text = changedUser.fullName;
              _userCtrl.text = changedUser.username;
              _phoneCtrl.text = changedUser.phone;
              _profilePicture = changedUser.profilePicture;
              _imageBytes = _decodeProfileImage(_profilePicture);
            });
          });
        }
      }
    });

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: themeColor),
        title: const Text('Mi Perfil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          // BOTÓN LÁPIZ: Alterna entre Modo Edición y Modo Lectura
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit, color: themeColor),
            onPressed: () {
              setState(() {
                if (_isEditing) {
                  // Si el usuario cancela, restauramos los valores guardados en el estado global
                  final currentUser = ref.read(authProvider).user;
                  if (currentUser != null) {
                    _nameCtrl.text = currentUser.fullName;
                    _userCtrl.text = currentUser.username;
                    _phoneCtrl.text = currentUser.phone;
                    _profilePicture = currentUser.profilePicture;
                    _imageBytes = _decodeProfileImage(_profilePicture);
                  }
                  _hasSubmitted = false;
                }
                _isEditing = !_isEditing;
              });
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            
            // --- 1. SECCIÓN DE FOTO DE PERFIL ---
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Builder(builder: (context) {
                  final avatarImage = _getAvatarImage();
                  return CircleAvatar(
                    radius: 70,
                    backgroundColor: const Color(0xFF121826),
                    backgroundImage: avatarImage,
                    child: avatarImage == null ? Icon(Icons.person, size: 70, color: themeColor) : null,
                  );
                }),
                // Botón de cámara (Solo aparece en modo edición)
                if (_isEditing)
                  Container(
                    decoration: BoxDecoration(color: themeColor, shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: darkBackground),
                      onPressed: () {
                        // Modal para elegir origen de la foto
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: const Color(0xFF121826),
                          builder: (context) => SafeArea(
                            child: Wrap(
                              children: [
                                ListTile(
                                  leading: Icon(Icons.camera, color: themeColor),
                                  title: const Text('Tomar Foto', style: TextStyle(color: Colors.white)),
                                  onTap: () { Navigator.pop(context); _pickAndCropImage(ImageSource.camera); },
                                ),
                                ListTile(
                                  leading: Icon(Icons.photo_library, color: themeColor),
                                  title: const Text('Elegir de la Galería', style: TextStyle(color: Colors.white)),
                                  onTap: () { Navigator.pop(context); _pickAndCropImage(ImageSource.gallery); },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            
            // --- 2. INSIGNIA DE ROL ---
            Text('Rol: ${widget.role.toUpperCase()}', style: TextStyle(color: themeColor, fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),

            // --- 3. FORMULARIO DE DATOS ---
            Form(
              key: _formKey,
              autovalidateMode: _hasSubmitted
                  ? AutovalidateMode.always
                  : AutovalidateMode.disabled,
              child: Column(
                children: [
                  CustomTextFormField(
                    label: 'Nombre Completo',
                    prefixIcon: Icons.badge,
                    controller: _nameCtrl,
                    enabled: _isEditing && canEditName,
                    validator: (value) {
                      if (!(_isEditing && canEditName)) return null;
                      return AppValidators.name(value);
                    },
                    hint: 'Ej: María Pérez',
                  ),
                  if (!canEditName && _isEditing)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                      child: Text(
                        'No puedes editar tu nombre mientras estás en una clase.',
                        style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ),
                  const SizedBox(height: 20),

                  CustomTextFormField(
                    label: 'Usuario',
                    prefixIcon: Icons.alternate_email,
                    controller: _userCtrl,
                    enabled: _isEditing,
                    validator: (value) => _isEditing ? AppValidators.username(value) : null,
                    hint: 'Ej: user123',
                  ),
                  const SizedBox(height: 20),

                  CustomTextFormField(
                    label: 'Teléfono',
                    prefixIcon: Icons.phone,
                    controller: _phoneCtrl,
                    enabled: _isEditing,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: (value) {
                      if (!_isEditing) return null;
                      final base = AppValidators.phone(value);
                      if (base != null) return base;
                      final digits = value?.trim().replaceAll(' ', '') ?? '';
                      if (digits.length != 10) return 'El teléfono debe tener 10 dígitos';
                      return null;
                    },
                    hint: 'Solo números (10 dígitos)',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // --- 4. BOTÓN DE GUARDAR (Solo visible en edición) ---
            if (_isEditing)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveChanges,
                  icon: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: darkBackground, strokeWidth: 2))
                      : const Icon(Icons.save, color: darkBackground),
                  label: Text(_isSaving ? 'GUARDANDO...' : 'GUARDAR CAMBIOS', style: const TextStyle(color: darkBackground, fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

}
