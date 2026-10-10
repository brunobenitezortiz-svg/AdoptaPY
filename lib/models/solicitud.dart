class Solicitud {
  final String id;
  final String mascotaId;
  final String adoptanteId;
  final String refugioId;
  final String estado;
  final String mensaje;
  final DateTime? fechaSolicitud;

  Solicitud({
    required this.id,
    required this.mascotaId,
    required this.adoptanteId,
    required this.refugioId,
    required this.estado,
    required this.mensaje,
    this.fechaSolicitud,
  });

  factory Solicitud.fromMap(
    String id,
    Map<String, dynamic> datos,
  ) {
    return Solicitud(
      id: id,
      mascotaId: datos['mascotaId'] ?? '',
      adoptanteId: datos['adoptanteId'] ?? '',
      refugioId: datos['refugioId'] ?? '',
      estado: datos['estado'] ?? 'pendiente',
      mensaje: datos['mensaje'] ?? '',
      fechaSolicitud:
          (datos['fechaSolicitud'] as dynamic)?.toDate(),
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
    };
  }
}