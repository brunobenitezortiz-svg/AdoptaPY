import 'package:cloud_firestore/cloud_firestore.dart';

class UsuarioService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> crearUsuario({
    required String uid,
    required String nombre,
    required String email,
    required String rol,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'nombre': nombre,
      'email': email,
      'rol': rol,
      'fechaRegistro': FieldValue.serverTimestamp(),
    });
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> obtenerUsuario(
    String uid,
  ) async {
    return await _firestore.collection('users').doc(uid).get();
  }
}