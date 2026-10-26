
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/solicitud.dart';
import '../../models/mascota.dart';
import '../../services/solicitud_service.dart';
import '../../services/mascota_service.dart';

class SolicitudesRefugioScreen extends StatefulWidget {
  const SolicitudesRefugioScreen({super.key});

  @override
  State<SolicitudesRefugioScreen> createState() =>
      _SolicitudesRefugioScreenState();
}

class _SolicitudesRefugioScreenState
    extends State<SolicitudesRefugioScreen> {
  final SolicitudService _solicitudService = SolicitudService();
  final MascotaService _mascotaService = MascotaService();

  late Future<List<Solicitud>> _futuroSolicitudes;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _cargarSolicitudes();
  }

  void _cargarSolicitudes() {
    final usuario = FirebaseAuth.instance.currentUser;

    _futuroSolicitudes = usuario == null
        ? Future.value([])
        : _solicitudService.obtenerSolicitudesDelRefugio(
            usuario.uid,
          );
  }

  Future<void> _actualizar() async {
    setState(_cargarSolicitudes);
    await _futuroSolicitudes;
  }

  Future<void> _gestionarSolicitud(
    Solicitud solicitud, {
    required bool aceptar,
  }) async {
    final accion = aceptar ? 'aceptar' : 'rechazar';

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          aceptar ? 'Aceptar solicitud' : 'Rechazar solicitud',
        ),
        content: Text(
          aceptar
              ? '¿Querés aceptar esta solicitud? La mascota quedará marcada como adoptada y las demás solicitudes pendientes serán rechazadas.'
              : '¿Querés rechazar esta solicitud?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Volver'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(aceptar ? 'Aceptar' : 'Rechazar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() {
      _procesando = true;
    });

    try {
      if (aceptar) {
        await _solicitudService.aceptarSolicitud(solicitud.id);
      } else {
        await _solicitudService.rechazarSolicitud(solicitud.id);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            aceptar
                ? 'Solicitud aceptada. La mascota figura como adoptada.'
                : 'Solicitud rechazada.',
          ),
        ),
      );

      await _actualizar();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo $accion la solicitud: '
            '${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _procesando = false;
        });
      }
    }
  }

  Color _colorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'aceptada':
        return Colors.green;
      case 'rechazada':
        return Colors.red;
      case 'cancelada':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  String _textoEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'aceptada':
        return 'Aceptada';
      case 'rechazada':
        return 'Rechazada';
      case 'cancelada':
        return 'Cancelada';
      default:
        return 'Pendiente';
    }
  }

  String _textoSiNo(bool? valor) {
    if (valor == null) return 'No informado';
    return valor ? 'Sí' : 'No';
  }

  String _textoVivienda(String? valor) {
    switch (valor) {
      case 'casa':
        return 'Casa';
      case 'departamento':
        return 'Departamento';
      case 'otro':
        return 'Otro';
      default:
        return 'No informado';
    }
  }

  String _textoTiempo(String? valor) {
    switch (valor) {
      case '1-2':
        return '1 a 2 horas diarias';
      case '3-5':
        return '3 a 5 horas diarias';
      case '6+':
        return 'Más de 5 horas diarias';
      default:
        return 'No informado';
    }
  }

  Widget _datoCuestionario({
    required IconData icono,
    required String titulo,
    required String valor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icono,
            size: 21,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirCuestionario(Solicitud solicitud) {
    final tieneCuestionario =
        solicitud.tipoVivienda != null ||
        solicitud.tienePatio != null ||
        solicitud.tiempoDisponible != null ||
        solicitud.tieneHijos != null ||
        solicitud.otrasMascotas != null ||
        solicitud.experienciaMascotas != null;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .primary
              .withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.assignment_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Información del hogar y cuidados',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Respuestas proporcionadas por el adoptante',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Divider(height: 26),
          if (!tieneCuestionario)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Esta solicitud fue enviada antes de que '
                'se incorporara el cuestionario de adopción.',
              ),
            )
          else ...[
            _datoCuestionario(
              icono: Icons.home_outlined,
              titulo: 'Tipo de vivienda',
              valor: _textoVivienda(solicitud.tipoVivienda),
            ),
            _datoCuestionario(
              icono: Icons.yard_outlined,
              titulo: '¿Tiene patio?',
              valor: _textoSiNo(solicitud.tienePatio),
            ),
            _datoCuestionario(
              icono: Icons.schedule_outlined,
              titulo: 'Tiempo disponible para la mascota',
              valor: _textoTiempo(solicitud.tiempoDisponible),
            ),
            _datoCuestionario(
              icono: Icons.family_restroom_outlined,
              titulo: '¿Conviven niños en el hogar?',
              valor: _textoSiNo(solicitud.tieneHijos),
            ),
            _datoCuestionario(
              icono: Icons.pets_outlined,
              titulo: 'Otras mascotas',
              valor: solicitud.otrasMascotas?.isNotEmpty == true
                  ? solicitud.otrasMascotas!
                  : 'No informado',
            ),
            _datoCuestionario(
              icono: Icons.volunteer_activism_outlined,
              titulo: 'Experiencia previa con mascotas',
              valor: _textoSiNo(solicitud.experienciaMascotas),
            ),
          ],
        ],
      ),
    );
  }

  Widget _construirDatosAdoptante(String adoptanteId) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(adoptanteId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          );
        }

        if (snapshot.hasError ||
            !snapshot.hasData ||
            !snapshot.data!.exists) {
          return const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.person_outline),
            title: Text('Datos del adoptante no disponibles'),
          );
        }

        final datos = snapshot.data!.data()!;
        final nombre = datos['nombre']?.toString().trim() ?? '';
        final email = datos['email']?.toString().trim() ?? '';

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.person_outline),
                  SizedBox(width: 8),
                  Text(
                    'Datos del adoptante',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.badge_outlined, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nombre',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          nombre.isNotEmpty
                              ? nombre
                              : 'Sin nombre registrado',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.email_outlined, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Correo electrónico',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        SelectableText(
                          email.isNotEmpty
                              ? email
                              : 'Sin correo registrado',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitudes recibidas'),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _actualizar,
            child: FutureBuilder<List<Solicitud>>(
              future: _futuroSolicitudes,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return ListView(
                    children: const [
                      SizedBox(height: 150),
                      Center(
                        child: Text(
                          'No se pudieron cargar las solicitudes.',
                        ),
                      ),
                    ],
                  );
                }

                final solicitudes = snapshot.data ?? [];

                solicitudes.sort((a, b) {
                  final fechaA = a.fechaSolicitud;
                  final fechaB = b.fechaSolicitud;

                  if (fechaA == null && fechaB == null) return 0;
                  if (fechaA == null) return 1;
                  if (fechaB == null) return -1;

                  return fechaB.compareTo(fechaA);
                });

                if (solicitudes.isEmpty) {
                  return ListView(
                    children: const [
                      SizedBox(height: 150),
                      Icon(
                        Icons.inbox_outlined,
                        size: 70,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Center(
                        child: Text(
                          'Todavía no recibiste solicitudes.',
                        ),
                      ),
                    ],
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: solicitudes.length,
                  itemBuilder: (context, indice) {
                    final solicitud = solicitudes[indice];

                    return FutureBuilder<Mascota?>(
                      future: _mascotaService.obtenerMascotaPorId(
                        solicitud.mascotaId,
                      ),
                      builder: (context, mascotaSnapshot) {
                        final mascota = mascotaSnapshot.data;
                        final pendiente =
                            solicitud.estado == 'pendiente';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 14),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mascotaSnapshot.connectionState ==
                                          ConnectionState.waiting
                                      ? 'Cargando mascota...'
                                      : mascota?.nombre ??
                                          'Mascota no disponible',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Text('Estado: '),
                                    Chip(
                                      label: Text(
                                        _textoEstado(solicitud.estado),
                                      ),
                                      labelStyle: TextStyle(
                                        color: _colorEstado(
                                          solicitud.estado,
                                        ),
                                      ),
                                      backgroundColor: _colorEstado(
                                        solicitud.estado,
                                      ).withValues(alpha: 0.12),
                                    ),
                                  ],
                                ),

                                _construirDatosAdoptante(
                                  solicitud.adoptanteId,
                                ),

                                _construirCuestionario(solicitud),

                                const SizedBox(height: 16),
                                const Text(
                                  'Motivo de adopción:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  solicitud.mensaje.isEmpty
                                      ? 'Sin mensaje'
                                      : solicitud.mensaje,
                                ),

                                if (pendiente) ...[
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: _procesando
                                              ? null
                                              : () => _gestionarSolicitud(
                                                    solicitud,
                                                    aceptar: false,
                                                  ),
                                          icon: const Icon(Icons.close),
                                          label: const Text('Rechazar'),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: _procesando
                                              ? null
                                              : () => _gestionarSolicitud(
                                                    solicitud,
                                                    aceptar: true,
                                                  ),
                                          icon: const Icon(Icons.check),
                                          label: const Text('Aceptar'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          if (_procesando)
            const ColoredBox(
              color: Color(0x33000000),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
