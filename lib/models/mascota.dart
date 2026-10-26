
class Mascota {
  final String id;
  final String nombre;
  final String especie;
  final String raza;
  final String edad;
  final String sexo;
  final String tamano;
  final String descripcion;
  final String imagenUrl;
  final String estado;
  final String refugioId;
  final DateTime? fechaPublicacion;
  final DateTime? fechaVencimiento;

  Mascota({
    required this.id,
    required this.nombre,
    required this.especie,
    required this.raza,
    required this.edad,
    required this.sexo,
    required this.tamano,
    required this.descripcion,
    required this.imagenUrl,
    required this.estado,
    required this.refugioId,
    this.fechaPublicacion,
    this.fechaVencimiento,
  });

  // Calcula el vencimiento de una publicación.
  DateTime? get vencimiento {
    if (fechaVencimiento != null) {
      return fechaVencimiento;
    }

    if (fechaPublicacion != null) {
      return fechaPublicacion!.add(
        const Duration(days: 7),
      );
    }

    return null;
  }

  // Indica si la publicación ya venció.
  bool get estaVencida {
    final fechaLimite = vencimiento;

    if (fechaLimite == null) {
      return true;
    }

    return !DateTime.now().isBefore(fechaLimite);
  }

  // Una mascota adoptada no puede estar disponible.
  bool get disponibleParaAdopcion {
    return estado == 'disponible' && !estaVencida;
  }

  factory Mascota.fromMap(
    String id,
    Map<String, dynamic> datos,
  ) {
    return Mascota(
      id: id,
      nombre: datos['nombre'] ?? '',
      especie: datos['especie'] ?? '',
      raza: datos['raza'] ?? '',
      edad: datos['edad'] ?? '',
      sexo: datos['sexo'] ?? '',
      tamano: datos['tamano'] ?? '',
      descripcion: datos['descripcion'] ?? '',
      imagenUrl: datos['imagenUrl'] ?? '',
      estado: datos['estado'] ?? 'disponible',
      refugioId: datos['refugioId'] ?? '',
      fechaPublicacion:
          (datos['fechaPublicacion'] as dynamic)?.toDate(),
      fechaVencimiento:
          (datos['fechaVencimiento'] as dynamic)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'especie': especie,
      'raza': raza,
      'edad': edad,
      'sexo': sexo,
      'tamano': tamano,
      'descripcion': descripcion,
      'imagenUrl': imagenUrl,
      'estado': estado,
      'refugioId': refugioId,
      'fechaPublicacion': fechaPublicacion,
      if (fechaVencimiento != null)
        'fechaVencimiento': fechaVencimiento,
    };
  }
}
