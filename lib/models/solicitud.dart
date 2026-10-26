
import 'package:cloud_firestore/cloud_firestore.dart';

class Solicitud {
  final String id;
  final String mascotaId;
  final String adoptanteId;
  final String refugioId;
  final String estado;
  final String mensaje;
  final DateTime? fechaSolicitud;

  // Información del hogar del adoptante
  final String? tipoVivienda;
  final bool? tienePatio;
  final String? tiempoDisponible;
  final bool? tieneHijos;
  final String? otrasMascotas;
  final bool? experienciaMascotas;

  Solicitud({
    required this.id,
    required this.mascotaId,
    required this.adoptanteId,
    required this.refugioId,
    required this.estado,
    required this.mensaje,
    this.fechaSolicitud,
    this.tipoVivienda,
    this.tienePatio,
    this.tiempoDisponible,
    this.tieneHijos,
    this.otrasMascotas,
    this.experienciaMascotas,
  });

  factory Solicitud.fromMap(
    String id,
    Map<String, dynamic> datos,
  ) {
    final fecha = datos['fechaSolicitud'];

    return Solicitud(
      id: id,
      mascotaId: datos['mascotaId'] ?? '',
      adoptanteId: datos['adoptanteId'] ?? '',
      refugioId: datos['refugioId'] ?? '',
      estado: datos['estado'] ?? 'pendiente',
      mensaje: datos['mensaje'] ?? '',
      fechaSolicitud: fecha is Timestamp
          ? fecha.toDate()
          : fecha is DateTime
              ? fecha
              : null,

      tipoVivienda: datos['tipoVivienda'] as String?,
      tienePatio: datos['tienePatio'] as bool?,
      tiempoDisponible: datos['tiempoDisponible'] as String?,
      tieneHijos: datos['tieneHijos'] as bool?,
      otrasMascotas: datos['otrasMascotas'] as String?,
      experienciaMascotas: datos['experienciaMascotas'] as bool?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mascotaId': mascotaId,
      'adoptanteId': adoptanteId,
      'refugioId': refugioId,
      'estado': estado,
      'mensaje': mensaje,
      'fechaSolicitud': fechaSolicitud,
      if (tipoVivienda != null) 'tipoVivienda': tipoVivienda,
      if (tienePatio != null) 'tienePatio': tienePatio,
      if (tiempoDisponible != null)
        'tiempoDisponible': tiempoDisponible,
      if (tieneHijos != null) 'tieneHijos': tieneHijos,
      if (otrasMascotas != null) 'otrasMascotas': otrasMascotas,
      if (experienciaMascotas != null)
        'experienciaMascotas': experienciaMascotas,
    };
  }
}
