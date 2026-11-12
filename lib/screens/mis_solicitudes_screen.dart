import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../models/mascota.dart';
import '../models/solicitud.dart';
import '../services/mascota_service.dart';
import '../services/solicitud_service.dart';
import '../theme/app_theme.dart';
import '../widgets/adopta_widgets.dart';

// ==========================================
// PANTALLA DE MIS SOLICITUDES
// ==========================================

class MisSolicitudesScreen extends StatefulWidget {
  const MisSolicitudesScreen({super.key});

  @override
  State<MisSolicitudesScreen> createState() => _MisSolicitudesScreenState();
}

class _MisSolicitudesScreenState extends State<MisSolicitudesScreen> {
  final SolicitudService _solicitudService = SolicitudService();

  final MascotaService _mascotaService = MascotaService();

  late Future<List<Solicitud>> _futuroSolicitudes;

  final Map<String, Future<Mascota?>> _consultasMascotas = {};

  String? _cancelandoSolicitudId;

  @override
  void initState() {
    super.initState();
    _cargarSolicitudes();
  }

  // ========================================
  // CARGAR SOLICITUDES
  // ========================================

  void _cargarSolicitudes() {
    final usuario = FirebaseAuth.instance.currentUser;

    _consultasMascotas.clear();

    _futuroSolicitudes = usuario == null
        ? Future.value([])
        : _solicitudService.obtenerSolicitudesDelAdoptante(usuario.uid);
  }

  // ========================================
  // CONSULTAR DATOS DE LAS MASCOTAS
  // ========================================

  Future<Mascota?> _obtenerMascota(String mascotaId) {
    return _consultasMascotas.putIfAbsent(
      mascotaId,
      () => _mascotaService.obtenerMascotaPorId(mascotaId),
    );
  }

  // ========================================
  // ACTUALIZAR SOLICITUDES
  // ========================================

  Future<void> _actualizar() async {
    setState(_cargarSolicitudes);

    try {
      await _futuroSolicitudes;
    } catch (_) {
      // FutureBuilder mostrará el error.
    }
  }

  // ========================================
  // COLORES DE LOS ESTADOS
  // ========================================

  Color _colorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'aceptada':
        return AppColors.primary;

      case 'rechazada':
        return const Color(0xFFC25353);

      case 'cancelada':
        return AppColors.muted;

      default:
        return const Color(0xFFB97723);
    }
  }

  // ========================================
  // TEXTO DE LOS ESTADOS
  // ========================================

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

  // ========================================
  // FECHA DE SOLICITUD
  // ========================================

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) {
      return 'Fecha no disponible';
    }

    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString();

    return '$dia/$mes/$anio';
  }

  // ========================================
  // CANCELAR UNA SOLICITUD
  // ========================================

  Future<void> _cancelarSolicitud(Solicitud solicitud) async {
    if (_cancelandoSolicitudId != null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (contexto) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(27),
          ),

          title: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: AppColors.azulPastel,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.help_outline_rounded,
                  color: AppColors.primary,
                  size: 25,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  'Cancelar solicitud',
                  style: GoogleFonts.quicksand(
                    color: AppColors.ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          content: const Text(
            '¿Estás seguro de que querés cancelar '
            'esta solicitud de adopción? '
            'Esta acción no se puede deshacer.',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 14,
              height: 1.55,
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(contexto, false);
              },
              child: const Text('Volver'),
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(contexto, true);
              },
              child: const Text('Sí, cancelar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true || !mounted) return;

    setState(() {
      _cancelandoSolicitudId = solicitud.id;
    });

    try {
      await _solicitudService.cancelarSolicitud(solicitud.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud cancelada correctamente.')),
      );

      await _actualizar();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo cancelar la solicitud.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _cancelandoSolicitudId = null;
        });
      }
    }
  }

  // ========================================
  // INTERFAZ PRINCIPAL
  // ========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text('Mis solicitudes'),
        backgroundColor: AppColors.background,
        scrolledUnderElevation: 0,
      ),

      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _actualizar,

        child: FutureBuilder<List<Solicitud>>(
          future: _futuroSolicitudes,

          builder: (context, snapshot) {
            final cargando =
                snapshot.connectionState == ConnectionState.waiting;

            final hayError = snapshot.hasError;

            final solicitudes = [...?snapshot.data];

            // ORDENAR DE MAS RECIENTE A MAS ANTIGUA
            solicitudes.sort((a, b) {
              if (a.fechaSolicitud == null && b.fechaSolicitud == null) {
                return 0;
              }

              if (a.fechaSolicitud == null) {
                return 1;
              }

              if (b.fechaSolicitud == null) {
                return -1;
              }

              return b.fechaSolicitud!.compareTo(a.fechaSolicitud!);
            });

            final pendientes = solicitudes
                .where(
                  (solicitud) => solicitud.estado.toLowerCase() == 'pendiente',
                )
                .length;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),

                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),

                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 38),

                  children: [
                    // ENCABEZADO
                    const PageHeading(
                      eyebrow: 'SEGUIMIENTO DE ADOPCIONES',
                      title: 'Cada historia tiene su camino.',
                      subtitle:
                          'Consultá el estado de tus '
                          'solicitudes y seguí cada paso '
                          'hacia una nueva amistad.',
                    ),

                    const SizedBox(height: 25),

                    // RESUMEN GENERAL
                    _ResumenSolicitudes(
                          total: solicitudes.length,
                          pendientes: pendientes,
                          cargando: cargando || hayError,
                        )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.04, end: 0, duration: 400.ms),

                    const SizedBox(height: 32),

                    // TITULO DE LA SECCION
                    const SectionHeading(
                      title: 'Tus solicitudes',
                      subtitle:
                          'El estado de cada adopción '
                          'en un solo lugar.',
                    ),

                    const SizedBox(height: 18),

                    // ==================================
                    // ESTADO DE CARGA
                    // ==================================
                    if (cargando)
                      const _SolicitudesCargando()
                    // ==================================
                    // ESTADO DE ERROR
                    // ==================================
                    else if (hayError)
                      AppEmptyState(
                        icon: Icons.wifi_off_rounded,
                        title: 'No se pudieron cargar tus solicitudes',
                        message:
                            'Revisá tu conexión '
                            'e intentá nuevamente.',
                        actionLabel: 'Reintentar',
                        onAction: _actualizar,
                      )
                    // ==================================
                    // ESTADO VACIO
                    // ==================================
                    else if (solicitudes.isEmpty)
                      const AppEmptyState(
                        icon: Icons.mark_email_unread_outlined,
                        title: 'Todavía no enviaste solicitudes',
                        message:
                            'Explorá el catálogo y conocé '
                            'a las mascotas que esperan '
                            'encontrar una familia.',
                      )
                    // ==================================
                    // MOSTRAR SOLICITUDES
                    // ==================================
                    else ...[
                      for (final solicitud in solicitudes)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 15),

                          child: _TarjetaSolicitud(
                            solicitud: solicitud,
                            mascotaFuture: _obtenerMascota(solicitud.mascotaId),
                            textoEstado: _textoEstado(solicitud.estado),
                            colorEstado: _colorEstado(solicitud.estado),
                            fecha: _formatearFecha(solicitud.fechaSolicitud),
                            cancelando: _cancelandoSolicitudId == solicitud.id,
                            onCancelar:
                                solicitud.estado.toLowerCase() == 'pendiente' &&
                                    _cancelandoSolicitudId == null
                                ? () {
                                    _cancelarSolicitud(solicitud);
                                  }
                                : null,
                          ),
                        ),

                      const SizedBox(height: 11),

                      const _MensajeSeguimiento(),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ==========================================
// RESUMEN DE SOLICITUDES
// ==========================================

class _ResumenSolicitudes extends StatelessWidget {
  final int total;
  final int pendientes;
  final bool cargando;

  const _ResumenSolicitudes({
    required this.total,
    required this.pendientes,
    required this.cargando,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF70C9F5), Color(0xFF378FD5), Color(0xFF2069B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        borderRadius: BorderRadius.circular(29),

        boxShadow: const [
          BoxShadow(
            color: Color(0x2756B8F2),
            blurRadius: 23,
            offset: Offset(0, 10),
          ),
        ],
      ),

      clipBehavior: Clip.antiAlias,

      child: Stack(
        children: [
          // DECORACION SUPERIOR
          const Positioned(
            right: -32,
            top: -35,
            child: Icon(
              Icons.pets_rounded,
              size: 180,
              color: Color(0x1CFFFFFF),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(22),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ETIQUETA
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),

                  decoration: BoxDecoration(
                    color: const Color(0x32FFFFFF),
                    borderRadius: BorderRadius.circular(100),
                  ),

                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 14,
                      ),

                      SizedBox(width: 7),

                      Text(
                        'TU CAMINO HACIA LA ADOPCIÓN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  'Cada solicitud es una\nnueva oportunidad.',
                  style: GoogleFonts.quicksand(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 22),

                // CONTADORES
                Row(
                  children: [
                    Expanded(
                      child: _ContadorSolicitud(
                        icono: Icons.description_outlined,
                        cantidad: cargando ? '—' : '$total',
                        etiqueta: 'Solicitudes',
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: _ContadorSolicitud(
                        icono: Icons.schedule_rounded,
                        cantidad: cargando ? '—' : '$pendientes',
                        etiqueta: 'Pendientes',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// CONTADORES
// ==========================================

class _ContadorSolicitud extends StatelessWidget {
  final IconData icono;
  final String cantidad;
  final String etiqueta;

  const _ContadorSolicitud({
    required this.icono,
    required this.cantidad,
    required this.etiqueta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),

      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white.withValues(alpha: 0.23)),
      ),

      child: Row(
        children: [
          Icon(icono, color: Colors.white, size: 23),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cantidad,
                  style: GoogleFonts.quicksand(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  etiqueta,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// TARJETA DE SOLICITUD
// ==========================================

class _TarjetaSolicitud extends StatelessWidget {
  final Solicitud solicitud;
  final Future<Mascota?> mascotaFuture;
  final String textoEstado;
  final Color colorEstado;
  final String fecha;
  final bool cancelando;
  final VoidCallback? onCancelar;

  const _TarjetaSolicitud({
    required this.solicitud,
    required this.mascotaFuture,
    required this.textoEstado,
    required this.colorEstado,
    required this.fecha,
    required this.cancelando,
    required this.onCancelar,
  });

  @override
  Widget build(BuildContext context) {
    final pendiente = solicitud.estado.toLowerCase() == 'pendiente';

    return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D164E86),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),

          child: Padding(
            padding: const EdgeInsets.all(18),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // DATOS DE LA MASCOTA
                FutureBuilder<Mascota?>(
                  future: mascotaFuture,

                  builder: (context, mascotaSnapshot) {
                    final mascota = mascotaSnapshot.data;

                    final cargando =
                        mascotaSnapshot.connectionState ==
                        ConnectionState.waiting;

                    return Row(
                      children: [
                        // FOTOGRAFIA
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0D164E86),
                                blurRadius: 11,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),

                          child: PetPhoto(
                            imageUrl: mascota?.imagenUrl ?? '',
                            height: 78,
                            width: 78,
                            radius: BorderRadius.circular(18),
                          ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // NOMBRE
                              Text(
                                cargando
                                    ? 'Cargando mascota...'
                                    : mascota?.nombre ??
                                          'Mascota no disponible',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.quicksand(
                                  color: AppColors.ink,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),

                              const SizedBox(height: 9),

                              // ESTADO
                              StatusPill(text: textoEstado, color: colorEstado),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 19),

                const Divider(color: AppColors.border, height: 1),

                const SizedBox(height: 17),

                // FECHA
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: AppColors.primary,
                      size: 17,
                    ),

                    const SizedBox(width: 9),

                    Expanded(
                      child: Text(
                        'Solicitada el $fecha',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 19),

                // TITULO DEL MENSAJE
                Row(
                  children: [
                    Container(
                      width: 33,
                      height: 33,
                      decoration: BoxDecoration(
                        color: AppColors.azulPastel,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),

                    const SizedBox(width: 11),

                    Text(
                      'Tu mensaje al refugio',
                      style: GoogleFonts.quicksand(
                        color: AppColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // MENSAJE
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),

                  decoration: BoxDecoration(
                    color: AppColors.azulSuave,
                    borderRadius: BorderRadius.circular(16),
                  ),

                  child: Text(
                    solicitud.mensaje.isEmpty
                        ? 'Sin mensaje'
                        : solicitud.mensaje,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ),

                // BOTON DE CANCELACION
                if (pendiente) ...[
                  const SizedBox(height: 15),

                  Align(
                    alignment: Alignment.centerRight,

                    child: TextButton.icon(
                      onPressed: onCancelar,

                      icon: cancelando
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.close_rounded, size: 17),

                      label: Text(
                        cancelando ? 'Cancelando...' : 'Cancelar solicitud',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 280.ms)
        .slideY(begin: 0.035, end: 0, duration: 280.ms);
  }
}

// ==========================================
// ESTADO DE CARGA CON SKELETONIZER
// ==========================================

class _SolicitudesCargando extends StatelessWidget {
  const _SolicitudesCargando();

  @override
  Widget build(BuildContext context) {
    return const Skeletonizer(
      enabled: true,
      child: Column(
        children: [
          _TarjetaSolicitudCargando(),
          SizedBox(height: 15),
          _TarjetaSolicitudCargando(),
        ],
      ),
    );
  }
}

// ==========================================
// TARJETA TEMPORAL DE CARGA
// ==========================================

class _TarjetaSolicitudCargando extends StatelessWidget {
  const _TarjetaSolicitudCargando();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.border),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Skeleton.leaf(
                child: SizedBox(
                  width: 78,
                  height: 78,
                  child: ColoredBox(color: AppColors.azulPastel),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nombre de la mascota',
                      style: GoogleFonts.quicksand(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 11),

                    const Text('Estado de solicitud'),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 23),

          const Divider(),

          const SizedBox(height: 15),

          const Text('Fecha de la solicitud'),

          const SizedBox(height: 16),

          const Text(
            'Tu mensaje al refugio',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 11),

          const Text(
            'Mensaje enviado al refugio '
            'para solicitar la adopción.',
          ),
        ],
      ),
    );
  }
}

// ==========================================
// MENSAJE INFERIOR
// ==========================================

class _MensajeSeguimiento extends StatelessWidget {
  const _MensajeSeguimiento();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: AppColors.azulSuave,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),

      child: const Row(
        children: [
          Icon(Icons.favorite_rounded, color: AppColors.primary, size: 22),

          SizedBox(width: 13),

          Expanded(
            child: Text(
              'Cada adopción comienza con una decisión '
              'llena de cariño y responsabilidad.',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 12,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
