class Favorito {
  final String id;
  final String usuarioId;
  final String mascotaId;
  final DateTime? fecha;

  Favorito({
    required this.id,
    required this.usuarioId,
    required this.mascotaId,
    this.fecha,
  });

  factory Favorito.fromMap(
    String id,
    Map<String, dynamic> datos,
  ) {
    return Favorito(
      id: id,
      usuarioId: datos['usuarioId'] ?? '',
      mascotaId: datos['mascotaId'] ?? '',
      fecha: (datos['fecha'] as dynamic)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'usuarioId': usuarioId,
      'mascotaId': mascotaId,
      'fecha': fecha,
    };
  }
}