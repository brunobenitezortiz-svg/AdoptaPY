
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

class _DetalleMascotaScreenState
    extends State<DetalleMascotaScreen> {
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

    String mensaje = '';
    String? errorMensaje;

    final resultado = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, actualizarDialogo) {
            return AlertDialog(
              title: const Text('Solicitar adopción'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contale al refugio por qué te gustaría adoptar a ${widget.mascota.nombre}.',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      maxLines: 4,
                      maxLength: 500,
                      onChanged: (valor) {
                        mensaje = valor;

                        if (errorMensaje != null &&
                            valor.trim().isNotEmpty) {
                          actualizarDialogo(() {
                            errorMensaje = null;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Mensaje para el refugio',
                        hintText: 'Quiero darle un hogar porque...',
                        border: const OutlineInputBorder(),
                        alignLabelWithHint: true,
                        errorText: errorMensaje,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (mensaje.trim().isEmpty) {
                      actualizarDialogo(() {
                        errorMensaje =
                            'Escribí un mensaje para el refugio.';
                      });
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      mensaje.trim(),
                    );
                  },
                  child: const Text('Enviar solicitud'),
                ),
              ],
            );
          },
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
        mensaje: resultado,
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

    if (_nombreRefugio == null &&
        _emailRefugio == null) {
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
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface,
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
              onPressed: _actualizandoFavorito
                  ? null
                  : _cambiarFavorito,
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

                  if (mascota.estado == 'disponible') ...[
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