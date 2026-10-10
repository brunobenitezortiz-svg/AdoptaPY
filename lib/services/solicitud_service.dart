import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/solicitud.dart';

class SolicitudService {
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

Future<void> crearSolicitud({
required String mascotaId,
required String adoptanteId,
required String refugioId,
required String mensaje,
}) async {
final existentes = await _firestore
.collection('solicitudes')
.where('mascotaId', isEqualTo: mascotaId)
.where('adoptanteId', isEqualTo: adoptanteId)
.where('estado', isEqualTo: 'pendiente')
.limit(1)
.get();

if (existentes.docs.isNotEmpty) {
  throw Exception(
    'Ya tenés una solicitud pendiente para esta mascota.',
  );
}

final mascota = await _firestore
    .collection('mascotas')
    .doc(mascotaId)
    .get();

if (!mascota.exists ||
    mascota.data()?['estado'] != 'disponible') {
  throw Exception(
    'Esta mascota ya no está disponible para adopción.',
  );
}

final datosMascota = mascota.data()!;

if (datosMascota['refugioId'] != refugioId) {
  throw Exception(
    'El refugio indicado no corresponde a esta mascota.',
  );
}

final solicitud = Solicitud(
  id: '',
  mascotaId: mascotaId,
  adoptanteId: adoptanteId,
  refugioId: refugioId,
  estado: 'pendiente',
  mensaje: mensaje.trim(),
  fechaSolicitud: DateTime.now(),
);

await _firestore.collection('solicitudes').add({
  ...solicitud.toMap(),
  'fechaSolicitud': FieldValue.serverTimestamp(),
});

}

Future<List<Solicitud>> obtenerSolicitudesDelAdoptante(
String adoptanteId,
) async {
final snapshot = await _firestore
.collection('solicitudes')
.where('adoptanteId', isEqualTo: adoptanteId)
.get();

return snapshot.docs.map((documento) {
  return Solicitud.fromMap(
    documento.id,
    documento.data(),
  );
}).toList();

}

Future<List<Solicitud>> obtenerSolicitudesDelRefugio(
String refugioId,
) async {
final snapshot = await _firestore
.collection('solicitudes')
.where('refugioId', isEqualTo: refugioId)
.get();

return snapshot.docs.map((documento) {
  return Solicitud.fromMap(
    documento.id,
    documento.data(),
  );
}).toList();

}

Future<void> cancelarSolicitud(String solicitudId) async {
await _firestore.runTransaction((transaccion) async {
final referencia = _firestore
.collection('solicitudes')
.doc(solicitudId);

  final documento = await transaccion.get(referencia);

  if (!documento.exists ||
      documento.data()?['estado'] != 'pendiente') {
    throw Exception(
      'La solicitud ya no está pendiente.',
    );
  }

  transaccion.update(referencia, {
    'estado': 'cancelada',
  });
});

}

Future<void> rechazarSolicitud(String solicitudId) async {
await _firestore.runTransaction((transaccion) async {
final referencia = _firestore
.collection('solicitudes')
.doc(solicitudId);

  final documento = await transaccion.get(referencia);

  if (!documento.exists ||
      documento.data()?['estado'] != 'pendiente') {
    throw Exception(
      'La solicitud ya no está pendiente.',
    );
  }

  transaccion.update(referencia, {
    'estado': 'rechazada',
  });
});

}

Future<void> aceptarSolicitud(String solicitudId) async {
// Obtener la solicitud inicial para identificar la mascota.
final referenciaSolicitudInicial = _firestore
.collection('solicitudes')
.doc(solicitudId);

final documentoSolicitudInicial =
    await referenciaSolicitudInicial.get();

if (!documentoSolicitudInicial.exists) {
  throw Exception('La solicitud no existe.');
}

final datosIniciales = documentoSolicitudInicial.data()!;
final mascotaIdInicial = datosIniciales['mascotaId'] as String;
final refugioIdInicial = datosIniciales['refugioId'] as String;

// Obtener las solicitudes pendientes de esa mascota y refugio.
final consultaPendientes = await _firestore
    .collection('solicitudes')
    .where('mascotaId', isEqualTo: mascotaIdInicial)
    .where('refugioId', isEqualTo: refugioIdInicial)
    .where('estado', isEqualTo: 'pendiente')
    .get();

await _firestore.runTransaction((transaccion) async {
  final referenciaSolicitud = _firestore
      .collection('solicitudes')
      .doc(solicitudId);

  final documentoSolicitud =
      await transaccion.get(referenciaSolicitud);

  if (!documentoSolicitud.exists) {
    throw Exception('La solicitud no existe.');
  }

  final datosSolicitud = documentoSolicitud.data()!;

  if (datosSolicitud['estado'] != 'pendiente') {
    throw Exception(
      'Esta solicitud ya no está pendiente.',
    );
  }

  final mascotaId = datosSolicitud['mascotaId'] as String;
  final refugioId = datosSolicitud['refugioId'] as String;

  if (mascotaId != mascotaIdInicial ||
      refugioId != refugioIdInicial) {
    throw Exception(
      'La solicitud cambió durante la operación. Intentá nuevamente.',
    );
  }

  final referenciaMascota =
      _firestore.collection('mascotas').doc(mascotaId);

  final documentoMascota =
      await transaccion.get(referenciaMascota);

  if (!documentoMascota.exists ||
      documentoMascota.data()?['estado'] != 'disponible') {
    throw Exception(
      'Esta mascota ya no está disponible para adopción.',
    );
  }

  if (documentoMascota.data()?['refugioId'] != refugioId) {
    throw Exception(
      'El refugio no corresponde a esta mascota.',
    );
  }

  // Leer todos los documentos antes de comenzar las escrituras.
  final documentosPendientes = <DocumentSnapshot<Map<String, dynamic>>>[];

  for (final candidato in consultaPendientes.docs) {
    final documentoActual =
        await transaccion.get(candidato.reference);

    if (documentoActual.exists &&
        documentoActual.data()?['estado'] == 'pendiente' &&
        documentoActual.data()?['mascotaId'] == mascotaId &&
        documentoActual.data()?['refugioId'] == refugioId) {
      documentosPendientes.add(documentoActual);
    }
  }

  if (!documentosPendientes.any(
    (documento) => documento.id == solicitudId,
  )) {
    throw Exception(
      'No se pudo verificar la solicitud pendiente.',
    );
  }

  // Vincular la adopción con la solicitud aceptada.
  transaccion.update(referenciaMascota, {
    'estado': 'adoptado',
    'solicitudAceptadaId': solicitudId,
  });

  // Aceptar la solicitud elegida y rechazar las demás pendientes.
  for (final documento in documentosPendientes) {
    transaccion.update(documento.reference, {
      'estado': documento.id == solicitudId
          ? 'aceptada'
          : 'rechazada',
    });
  }
});

}
}
