import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential> registrarUsuario({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> iniciarSesion({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> cerrarSesion() async {
    await _auth.signOut();
  }

  Future<void> recuperarContrasena(String email) async {
    await _auth.sendPasswordResetEmail(
      email: email,
    );
  }

  User? get usuarioActual => _auth.currentUser;
}