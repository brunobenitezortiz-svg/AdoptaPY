import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/mascota.dart';

class MascotaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> crearMascota(Mascota mascota) async {
    await _firestore.collection('mascotas').add(
      mascota.toMap(),
    );
  }

  Future<List<Mascota>> obtenerMascotas() async {
    final snapshot = await _firestore
        .collection('mascotas')
        .orderBy('fechaPublicacion', descending: true)
        .get();

    return snapshot.docs.map((documento) {
      return Mascota.fromMap(
        documento.id,
        documento.data(),
      );
    }).toList();
  }

  Future<List<Mascota>> obtenerMascotasDelRefugio(
    String refugioId,
  ) async {
    final snapshot = await _firestore
        .collection('mascotas')
        .where('refugioId', isEqualTo: refugioId)
        .get();

    return snapshot.docs.map((documento) {
      return Mascota.fromMap(
        documento.id,
        documento.data(),
      );
    }).toList();
  }

  Future<void> actualizarMascota(
    String mascotaId,
    Map<String, dynamic> datos,
  ) async {
    await _firestore
        .collection('mascotas')
        .doc(mascotaId)
        .update(datos);
  }

  Future<void> eliminarMascota(String mascotaId) async {
    await _firestore
        .collection('mascotas')
        .doc(mascotaId)
        .delete();
  }
    Future<Mascota?> obtenerMascotaPorId(String mascotaId) async {
    final documento = await _firestore
        .collection('mascotas')
        .doc(mascotaId)
        .get();

    if (!documento.exists) {
      return null;
    }

    return Mascota.fromMap(
      documento.id,
      documento.data()!,
    );
  }
}