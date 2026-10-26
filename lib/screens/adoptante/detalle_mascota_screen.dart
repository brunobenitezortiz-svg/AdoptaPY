
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/mascota.dart';
import '../../services/auth_service.dart';
import '../../services/favorito_service.dart';
import '../../services/solicitud_service.dart';

class DetalleMascotaScreen extends StatefulWidget {
  final Mascota mascota;

  const DetalleMascotaScreen({
    super.key,
    required this.mascota,
  });

  @override
  State<DetalleMascotaScreen> createState() =>
      _DetalleMascotaScreenState();
}

class _DetalleMascotaScreenState extends State<DetalleMascotaScreen> {
  final FavoritoService _favoritoService = FavoritoService();
  final SolicitudService _solicitudService = SolicitudService();

  bool _esFavorito = false;
  String? _favoritoId;
  bool _cargandoFavorito = true;
  bool _actualizandoFavorito = false;
  bool _enviandoSolicitud = false;

  String? _nombreRefugio;
  String? _emailRefugio;
  bool _cargandoRefugio = true;

  @override
  void initState() {
    super.initState();
    _cargarFavorito();
    _cargarDatosRefugio();
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) {
      return 'No disponible';
    }

    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString();

    return '$dia/$mes/$anio';
  }

  Future<void> _cargarDatosRefugio() async {
    try {
      final documento = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.mascota.refugioId)
          .get();

      if (!mounted) return;

      if (documento.exists) {
        final datos = documento.data()!;

        setState(() {
          _nombreRefugio = datos['nombre']?.toString();
          _emailRefugio = datos['email']?.toString();
          _cargandoRefugio = false;
        });
      } else {
        setState(() {
          _cargandoRefugio = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargandoRefugio = false;
      });
    }
  }

  Future<void> _cargarFavorito() async {
    final usuario = AuthService().usuarioActual;

    if (usuario == null) {
      if (mounted) {
        setState(() {
          _cargandoFavorito = false;
        });
      }
      return;
    }

    try {
      final favorito = await _favoritoService.obtenerFavorito(
        usuarioId: usuario.uid,
        mascotaId: widget.mascota.id,
      );

      if (!mounted) return;

      setState(() {
        _esFavorito = favorito != null;
        _favoritoId = favorito?.id;
        _cargandoFavorito = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargandoFavorito = false;
      });
    }
  }

  Future<void> _cambiarFavorito() async {
    final usuario = AuthService().usuarioActual;

    if (usuario == null || _actualizandoFavorito) {
      return;
    }

    setState(() {
      _actualizandoFavorito = true;
    });

    try {
      if (_esFavorito && _favoritoId != null) {
        await _favoritoService.eliminarFavorito(_favoritoId!);

        if (!mounted) return;

        setState(() {
          _esFavorito = false;
          _favoritoId = null;
        });
      } else {
        await _favoritoService.agregarFavorito(
          usuarioId: usuario.uid,
          mascotaId: widget.mascota.id,
        );

        final favorito = await _favoritoService.obtenerFavorito(
          usuarioId: usuario.uid,
          mascotaId: widget.mascota.id,
        );

        if (!mounted) return;

        setState(() {
          _esFavorito = favorito != null;
          _favoritoId = favorito?.id;
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo actualizar el favorito.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _actualizandoFavorito = false;
        });
      }
    }
  }

  Future<void> _solicitarAdopcion() async {
    final usuario = AuthService().usuarioActual;

    if (usuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Iniciá sesión para solicitar una adopción.',
          ),
        ),
      );
      return;
    }

    if (!widget.mascota.disponibleParaAdopcion) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Esta publicación ya no está disponible para adopción.',
          ),
        ),
      );
      return;
    }

    final resultado = await showDialog<_DatosFormularioAdopcion>(
      context: context,
      builder: (dialogContext) {
        return _FormularioAdopcionDialog(
          nombreMascota: widget.mascota.nombre,
        );
      },
    );

    if (resultado == null || !mounted) {
      return;
    }

    setState(() {
      _enviandoSolicitud = true;
    });

    try {
      await _solicitudService.crearSolicitud(
        mascotaId: widget.mascota.id,
        adoptanteId: usuario.uid,
        refugioId: widget.mascota.refugioId,
        mensaje: resultado.mensaje,
        tipoVivienda: resultado.tipoVivienda,
        tienePatio: resultado.tienePatio,
        tiempoDisponible: resultado.tiempoDisponible,
        tieneHijos: resultado.tieneHijos,
        otrasMascotas: resultado.otrasMascotas,
        experienciaMascotas: resultado.experienciaMascotas,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Solicitud de adopción enviada!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      final error = e.toString();

      String mensajeError =
          'No se pudo enviar la solicitud. Intentá nuevamente.';

      if (error.contains('Ya tenés una solicitud pendiente')) {
        mensajeError =
            'Ya tenés una solicitud pendiente para esta mascota.';
      } else if (error.contains('ya no está disponible')) {
        mensajeError =
            'Esta mascota ya no está disponible para adopción.';
      } else if (error.contains('permission-denied')) {
        mensajeError =
            'La publicación puede haber vencido o ya no estar disponible.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensajeError),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _enviandoSolicitud = false;
        });
      }
    }
  }

  Widget _construirSeccionRefugio() {
    if (_cargandoRefugio) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_nombreRefugio == null && _emailRefugio == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.info_outline),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No se pudieron cargar los datos del refugio.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.home_work_outlined,
                    size: 28,
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nombreRefugio?.isNotEmpty == true
                            ? _nombreRefugio!
                            : 'Refugio',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Responsable de esta mascota',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_emailRefugio?.isNotEmpty == true) ...[
              const Divider(height: 28),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.email_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Correo electrónico',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(_emailRefugio!),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mascota = widget.mascota;

    return Scaffold(
      appBar: AppBar(
        title: Text(mascota.nombre),
        actions: [
          if (_cargandoFavorito)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            )
          else
            IconButton(
              onPressed:
                  _actualizandoFavorito ? null : _cambiarFavorito,
              tooltip: _esFavorito
                  ? 'Quitar de favoritos'
                  : 'Agregar a favoritos',
              icon: Icon(
                _esFavorito
                    ? Icons.favorite
                    : Icons.favorite_border,
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 280,
              width: double.infinity,
              child: mascota.imagenUrl.isNotEmpty
                  ? Image.network(
                      mascota.imagenUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.pets, size: 100),
                        );
                      },
                    )
                  : const Center(
                      child: Icon(Icons.pets, size: 100),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mascota.nombre,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${mascota.especie} · ${mascota.raza}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Información',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DatoMascota(
                    icono: Icons.cake_outlined,
                    titulo: 'Edad',
                    valor: mascota.edad,
                  ),
                  _DatoMascota(
                    icono: Icons.wc_outlined,
                    titulo: 'Sexo',
                    valor: mascota.sexo,
                  ),
                  _DatoMascota(
                    icono: Icons.straighten,
                    titulo: 'Tamaño',
                    valor: mascota.tamano,
                  ),
                  _DatoMascota(
                    icono: Icons.info_outline,
                    titulo: 'Estado',
                    valor: mascota.estado,
                  ),
                  _DatoMascota(
                    icono: Icons.calendar_today_outlined,
                    titulo: 'Publicado',
                    valor: _formatearFecha(
                      mascota.fechaPublicacion,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Descripción',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    mascota.descripcion,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Sobre el refugio',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _construirSeccionRefugio(),
                  if (mascota.disponibleParaAdopcion) ...[
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _enviandoSolicitud
                            ? null
                            : _solicitarAdopcion,
                        icon: _enviandoSolicitud
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.volunteer_activism,
                              ),
                        label: Text(
                          _enviandoSolicitud
                              ? 'Enviando solicitud...'
                              : 'Solicitar adopción',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DatosFormularioAdopcion {
  final String tipoVivienda;
  final bool tienePatio;
  final String tiempoDisponible;
  final bool tieneHijos;
  final String otrasMascotas;
  final bool experienciaMascotas;
  final String mensaje;

  const _DatosFormularioAdopcion({
    required this.tipoVivienda,
    required this.tienePatio,
    required this.tiempoDisponible,
    required this.tieneHijos,
    required this.otrasMascotas,
    required this.experienciaMascotas,
    required this.mensaje,
  });
}

class _FormularioAdopcionDialog extends StatefulWidget {
  final String nombreMascota;

  const _FormularioAdopcionDialog({
    required this.nombreMascota,
  });

  @override
  State<_FormularioAdopcionDialog> createState() =>
      _FormularioAdopcionDialogState();
}

class _FormularioAdopcionDialogState
    extends State<_FormularioAdopcionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _mensajeController = TextEditingController();
  final _otrasMascotasController = TextEditingController();

  String? _tipoVivienda;
  bool? _tienePatio;
  String? _tiempoDisponible;
  bool? _tieneHijos;
  bool? _tieneOtrasMascotas;
  bool? _experienciaMascotas;

  @override
  void dispose() {
    _mensajeController.dispose();
    _otrasMascotasController.dispose();
    super.dispose();
  }

  Widget _tituloSeccion(
    IconData icono,
    String titulo,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 12,
        bottom: 14,
      ),
      child: Row(
        children: [
          Icon(
            icono,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectorSiNo({
    required String pregunta,
    required bool? valor,
    required ValueChanged<bool?> alCambiar,
  }) {
    return FormField<bool>(
      key: ValueKey(pregunta),
      initialValue: valor,
      validator: (_) {
        if (valor == null) {
          return 'Seleccioná una opción.';
        }
        return null;
      },
      builder: (campo) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pregunta,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: [
                ChoiceChip(
                  label: const Text('Sí'),
                  selected: valor == true,
                  onSelected: (_) {
                    alCambiar(true);
                    campo.didChange(true);
                  },
                ),
                ChoiceChip(
                  label: const Text('No'),
                  selected: valor == false,
                  onSelected: (_) {
                    alCambiar(false);
                    campo.didChange(false);
                  },
                ),
              ],
            ),
            if (campo.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  campo.errorText!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _enviar() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      _DatosFormularioAdopcion(
        tipoVivienda: _tipoVivienda!,
        tienePatio: _tienePatio!,
        tiempoDisponible: _tiempoDisponible!,
        tieneHijos: _tieneHijos!,
        otrasMascotas: _tieneOtrasMascotas!
            ? _otrasMascotasController.text.trim()
            : 'No tiene otras mascotas',
        experienciaMascotas: _experienciaMascotas!,
        mensaje: _mensajeController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.pets),
          SizedBox(width: 10),
          Expanded(
            child: Text('Solicitud de adopción'),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Completá este formulario para solicitar la adopción de ${widget.nombreMascota}. '
                  'Tus respuestas ayudarán al refugio a conocerte mejor.',
                ),
                const SizedBox(height: 16),
                _tituloSeccion(
                  Icons.home_outlined,
                  'Tu hogar',
                ),
                DropdownButtonFormField<String>(
                  initialValue: _tipoVivienda,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de vivienda',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'casa',
                      child: Text('Casa'),
                    ),
                    DropdownMenuItem(
                      value: 'departamento',
                      child: Text('Departamento'),
                    ),
                    DropdownMenuItem(
                      value: 'otro',
                      child: Text('Otro'),
                    ),
                  ],
                  onChanged: (valor) {
                    setState(() {
                      _tipoVivienda = valor;
                    });
                  },
                  validator: (valor) => valor == null
                      ? 'Seleccioná tu tipo de vivienda.'
                      : null,
                ),
                const SizedBox(height: 18),
                _selectorSiNo(
                  pregunta: '¿Tenés patio?',
                  valor: _tienePatio,
                  alCambiar: (valor) {
                    setState(() {
                      _tienePatio = valor;
                    });
                  },
                ),
                const SizedBox(height: 12),
                _tituloSeccion(
                  Icons.schedule_outlined,
                  'Tu disponibilidad',
                ),
                DropdownButtonFormField<String>(
                  initialValue: _tiempoDisponible,
                  decoration: const InputDecoration(
                    labelText: 'Tiempo diario disponible',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: '1-2',
                      child: Text('1 a 2 horas'),
                    ),
                    DropdownMenuItem(
                      value: '3-5',
                      child: Text('3 a 5 horas'),
                    ),
                    DropdownMenuItem(
                      value: '6+',
                      child: Text('Más de 5 horas'),
                    ),
                  ],
                  onChanged: (valor) {
                    setState(() {
                      _tiempoDisponible = valor;
                    });
                  },
                  validator: (valor) => valor == null
                      ? 'Seleccioná una opción.'
                      : null,
                ),
                const SizedBox(height: 18),
                _tituloSeccion(
                  Icons.family_restroom_outlined,
                  'Convivencia',
                ),
                _selectorSiNo(
                  pregunta: '¿Conviven niños en tu hogar?',
                  valor: _tieneHijos,
                  alCambiar: (valor) {
                    setState(() {
                      _tieneHijos = valor;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _selectorSiNo(
                  pregunta: '¿Tenés otras mascotas?',
                  valor: _tieneOtrasMascotas,
                  alCambiar: (valor) {
                    setState(() {
                      _tieneOtrasMascotas = valor;
                    });
                  },
                ),
                if (_tieneOtrasMascotas == true) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _otrasMascotasController,
                    maxLength: 300,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: '¿Cuáles y cuántas?',
                      hintText: 'Ej.: 2 perros y 1 gato',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    validator: (valor) {
                      if (_tieneOtrasMascotas == true &&
                          (valor == null ||
                              valor.trim().isEmpty)) {
                        return 'Describí tus otras mascotas.';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 16),
                _tituloSeccion(
                  Icons.volunteer_activism_outlined,
                  'Experiencia',
                ),
                _selectorSiNo(
                  pregunta:
                      '¿Tuviste mascotas anteriormente?',
                  valor: _experienciaMascotas,
                  alCambiar: (valor) {
                    setState(() {
                      _experienciaMascotas = valor;
                    });
                  },
                ),
                const SizedBox(height: 14),
                _tituloSeccion(
                  Icons.edit_note_outlined,
                  'Motivo de adopción',
                ),
                TextFormField(
                  controller: _mensajeController,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Mensaje para el refugio',
                    hintText:
                        'Contá por qué querés adoptar y cómo cuidarías a la mascota...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'Escribí un mensaje para el refugio.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Tus respuestas serán compartidas con el refugio '
                  'responsable de esta mascota.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _enviar,
          icon: const Icon(Icons.send_outlined),
          label: const Text('Enviar solicitud'),
        ),
      ],
    );
  }
}

class _DatoMascota extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;

  const _DatoMascota({
    required this.icono,
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icono, size: 24),
          const SizedBox(width: 14),
          Text(
            '$titulo: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
