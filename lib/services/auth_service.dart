import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../config.dart';

/// Registro, inicio de sesión y recuperación de contraseña.
/// Cada usuario registrado queda guardado en la colección `usuarios`.
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static User? get usuarioActual => _auth.currentUser;
  static Stream<User?> get cambios => _auth.authStateChanges();

  static bool esCorreoAdmin(String? email) =>
      email != null && AppConfig.adminEmails.contains(email.toLowerCase().trim());

  static Future<void> registrar({
    required String nombre,
    required String email,
    required String password,
    required String telefono,
    required String tipoUsuario,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user!;
    await user.updateDisplayName(nombre.trim());
    await _db.collection('usuarios').doc(user.uid).set(<String, dynamic>{
      'nombre': nombre.trim(),
      'email': email.trim().toLowerCase(),
      'telefono': telefono.trim(),
      'tipoUsuario': tipoUsuario,
      'rol': 'usuario',
      'favoritos': <String>[],
      'aceptoTratamientoDatos': true,
      'creadoEn': FieldValue.serverTimestamp(),
      'ultimoIngreso': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> iniciarSesion(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await asegurarPerfil(cred.user!);
  }

  /// Crea el perfil si el usuario fue creado desde la consola de Firebase
  /// y actualiza la fecha de último ingreso.
  static Future<void> asegurarPerfil(User user) async {
    final ref = _db.collection('usuarios').doc(user.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set(<String, dynamic>{
        'nombre': user.displayName ?? (user.email ?? 'Usuario').split('@').first,
        'email': (user.email ?? '').toLowerCase(),
        'telefono': '',
        'tipoUsuario': AppConfig.tiposUsuario.first,
        'rol': 'usuario',
        'favoritos': <String>[],
        'aceptoTratamientoDatos': true,
        'creadoEn': FieldValue.serverTimestamp(),
        'ultimoIngreso': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.update(<String, dynamic>{'ultimoIngreso': FieldValue.serverTimestamp()});
    }
  }

  static Future<void> recuperarPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  static Future<void> cerrarSesion() => _auth.signOut();

  /// Traduce los códigos de error de Firebase a mensajes en español.
  static String mensajeError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'El correo electrónico no es válido.';
        case 'user-disabled':
          return 'Esta cuenta está deshabilitada.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Correo o contraseña incorrectos.';
        case 'email-already-in-use':
          return 'Ya existe una cuenta con ese correo.';
        case 'weak-password':
          return 'La contraseña es muy débil (mínimo 6 caracteres).';
        case 'network-request-failed':
          return 'Sin conexión a internet. Intente de nuevo.';
        case 'too-many-requests':
          return 'Demasiados intentos. Espere un momento.';
        case 'operation-not-allowed':
          return 'El registro con correo no está habilitado en Firebase.';
        default:
          return e.message ?? 'Ocurrió un error (${e.code}).';
      }
    }
    if (e is FirebaseException) {
      if (e.code == 'permission-denied') {
        return 'No tiene permisos para esta acción.';
      }
      return e.message ?? 'Error de Firebase (${e.code}).';
    }
    return 'Ocurrió un error inesperado: $e';
  }
}
