import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// LOGIN CON EMAIL y CONTRASEÑA
  Future<AuthResult> loginWithEmail(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      return AuthResult(false, 'Completa todos los campos');
    }
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return AuthResult(true, 'Inicio de sesión correcto');
    } on FirebaseAuthException catch (e) {
      return AuthResult(false, e.message ?? 'Error al iniciar sesión');
    }
  }

  /// LOGIN CON GOOGLE
  Future<AuthResult> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return AuthResult(false, 'Inicio de sesión cancelado');

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      return AuthResult(true, 'Inicio de sesión con Google correcto');
    } on FirebaseAuthException catch (e) {
      return AuthResult(false, e.message ?? 'Error al iniciar sesión con Google');
    }
  }

  /// REGISTRO CON EMAIL
  Future<AuthResult> registerWithEmail(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      return AuthResult(false, 'Datos de inicio de sesión no válidos');
    }
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return AuthResult(true, 'Usuario creado correctamente');
    } on FirebaseAuthException catch (e) {
      return AuthResult(false, e.message ?? 'Error al registrar usuario');
    }
  }

  /// RESET PASSWORD
  Future<AuthResult> resetPassword(String email) async {
    if (email.isEmpty) return AuthResult(false, 'Introduce tu email');
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult(true, 'Email de recuperación enviado');
    } on FirebaseAuthException catch (e) {
      return AuthResult(false, e.message ?? 'Error al enviar email');
    }
  }

  /// LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }
}

/// Clase para manejar resultados y mensajes
class AuthResult {
  final bool success;
  final String message;

  AuthResult(this.success, this.message);
}
