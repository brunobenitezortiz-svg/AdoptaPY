import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/favorito.dart';

class FavoritoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> agregarFavorito({
    required String usuarioId,
    required String mascotaId,
  }) async {
    await _firestore.collection('favoritos').add({
      'usuarioId': usuarioId,
      'mascotaId': mascotaId,
      'fecha': FieldValue.serverTimestamp(),
    });
  }

  Future<void> eliminarFavorito(String favoritoId) async {
    await _firestore
        .collection('favoritos')
        .doc(favoritoId)
        .delete();
  }

  Future<Favorito?> obtenerFavorito({
    required String usuarioId,
    required String mascotaId,
  }) async {
    final snapshot = await _firestore
        .collection('favoritos')
        .where('usuarioId', isEqualTo: usuarioId)
        .where('mascotaId', isEqualTo: mascotaId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final documento = snapshot.docs.first;

    return Favorito.fromMap(
      documento.id,
      documento.data(),
    );
  }

  Future<List<Favorito>> obtenerFavoritos(
    String usuarioId,
  ) async {
    final snapshot = await _firestore
        .collection('favoritos')
        .where(
          'usuarioId',
          isEqualTo: usuarioId,
        )
        .get();

    return snapshot.docs.map((documento) {
      return Favorito.fromMap(
        documento.id,
        documento.data(),
      );
    }).toList();
  }
}