import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../models/solicitud.dart';
import '../models/mascota.dart';
import '../services/solicitud_service.dart';
import '../services/mascota_service.dart';
import '../theme/app_theme.dart';
import '../widgets/adopta_widgets.dart';

// ==========================================
// SOLICITUDES RECIBIDAS POR EL REFUGIO
// ==========================================

class SolicitudesRefugioScreen extends StatefulWidget {
  const SolicitudesRefugioScreen({super.key});

  @override
  State<SolicitudesRefugioScreen> createState() =>
      _SolicitudesRefugioScreenState();
}

class _SolicitudesRefugioScreenState extends State<SolicitudesRefugioScreen> {
  final SolicitudService _solicitudService = SolicitudService();

  final MascotaService _mascotaService = MascotaService();

  late Future<List<Solicitud>> _futuroSolicitudes;

  // Evitan repetir consultas cuando se reconstruye
  // la pantalla por un cambio de estado.
  final Map<String, Future<Mascota?>> _consultasMascotas = {};

  final Map<String, Future<DocumentSnapshot<Map<String, dynamic>>>>
  _consultasAdoptantes = {};

  bool _procesando = false;

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
    _consultasAdoptantes.clear();

    _futuroSolicitudes = usuario == null
        ? Future.value([])
        : _solicitudService.obtenerSolicitudesDelRefugio(usuario.uid);
  }

  // ========================================
  // CONSULTAR MASCOTA RELACIONADA
  // ========================================

  Future<Mascota?> _obtenerMascota(String mascotaId) {
    return _consultasMascotas.putIfAbsent(
      mascotaId,
      () => _mascotaService.obtenerMascotaPorId(mascotaId),
    );
  }

  // ========================================
  // CONSULTAR DATOS DEL ADOPTANTE
  // ========================================

  Future<DocumentSnapshot<Map<String, dynamic>>> _obtenerAdoptante(
    String adoptanteId,
  ) {
    return _consultasAdoptantes.putIfAbsent(
      adoptanteId,
      () =>
          FirebaseFirestore.instance.collection('users').doc(adoptanteId).get(),
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
  // ACEPTAR O RECHAZAR SOLICITUD
  // ========================================

  Future<void> _gestionarSolicitud(
    Solicitud solicitud, {
    required bool aceptar,
  }) async {
    if (_procesando) return;

    final accion = aceptar ? 'aceptar' : 'rechazar';

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
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
                child: Icon(
                  aceptar
                      ? Icons.check_circle_outline_rounded
                      : Icons.help_outline_rounded,
                  color: AppColors.primary,
                  size: 25,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  aceptar ? 'Aceptar solicitud' : 'Rechazar solicitud',
                  style: GoogleFonts.quicksand(
                    color: AppColors.ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          content: Text(
            aceptar
                ? '¿Querés aceptar esta solicitud? '
                      'La mascota quedará marcada como '
                      'adoptada y las demás solicitudes '
                      'pendientes serán rechazadas.'
                : '¿Querés rechazar esta solicitud?',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 14,
              height: 1.6,
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Volver'),
            ),

            FilledButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              icon: Icon(
                aceptar ? Icons.check_rounded : Icons.close_rounded,
                size: 18,
              ),
              label: Text(aceptar ? 'Aceptar' : 'Rechazar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true || !mounted || _procesando) {
      return;
    }

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
                ? 'Solicitud aceptada. '
                      'La mascota figura como adoptada.'
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

  // ========================================
  // COLOR SEGUN ESTADO
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
        return const Color(0xFFB58025);
    }
  }

  // ========================================
  // TEXTO SEGUN ESTADO
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
  // FORMATO DE RESPUESTAS
  // ========================================

  String _textoSiNo(bool? valor) {
    if (valor == null) {
      return 'No informado';
    }

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

  // ========================================
  // FORMATEAR FECHA
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
  // DATO INDIVIDUAL DEL CUESTIONARIO
  // ========================================

  Widget _datoCuestionario({
    required IconData icono,
    required String titulo,
    required String valor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icono, color: AppColors.primary, size: 19),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  valor,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // CUESTIONARIO DEL ADOPTANTE
  // ========================================

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
      margin: const EdgeInsets.only(top: 17),
      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: AppColors.azulSuave,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ENCABEZADO DEL CUESTIONARIO
          Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: AppColors.azulPastel,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: AppColors.primary,
                  size: 21,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Text(
                  'Hogar y cuidados',
                  style: GoogleFonts.quicksand(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          const Text(
            'Respuestas proporcionadas por el adoptante.',
            style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.5),
          ),

          const SizedBox(height: 17),

          const Divider(color: AppColors.border, height: 1),

          const SizedBox(height: 18),

          if (!tieneCuestionario)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Esta solicitud fue enviada antes '
                'de que se incorporara el '
                'cuestionario de adopción.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  height: 1.6,
                ),
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

  // ========================================
  // DATOS DEL ADOPTANTE
  // ========================================

  Widget _construirDatosAdoptante(String adoptanteId) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _obtenerAdoptante(adoptanteId),

      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Skeletonizer(
            enabled: true,
            child: Container(
              margin: const EdgeInsets.only(top: 17),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.azulSuave,
                borderRadius: BorderRadius.circular(19),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Datos del adoptante',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 17),
                  Text('Nombre del adoptante'),
                  SizedBox(height: 12),
                  Text('Correo electrónico'),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const _MensajeDatosNoDisponibles();
        }

        final datos = snapshot.data!.data() ?? {};

        final nombre = datos['nombre']?.toString().trim() ?? '';

        final email = datos['email']?.toString().trim() ?? '';

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 17),
          padding: const EdgeInsets.all(17),

          decoration: BoxDecoration(
            color: AppColors.azulSuave,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TITULO
              Row(
                children: [
                  Container(
                    width: 39,
                    height: 39,
                    decoration: BoxDecoration(
                      color: AppColors.azulPastel,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),

                  const SizedBox(width: 11),

                  Expanded(
                    child: Text(
                      'Datos del adoptante',
                      style: GoogleFonts.quicksand(
                        color: AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // NOMBRE
              _datoCuestionario(
                icono: Icons.badge_outlined,
                titulo: 'Nombre',
                valor: nombre.isNotEmpty ? nombre : 'Sin nombre registrado',
              ),

              // CORREO ELECTRONICO
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.email_outlined,
                      color: AppColors.primary,
                      size: 19,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Correo electrónico',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 5),

                        SelectableText(
                          email.isNotEmpty ? email : 'Sin correo registrado',
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
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

  // ========================================
  // TARJETA DE UNA SOLICITUD
  // ========================================

  Widget _construirTarjetaSolicitud(Solicitud solicitud) {
    final pendiente = solicitud.estado.toLowerCase() == 'pendiente';

    return Container(
          margin: const EdgeInsets.only(bottom: 16),

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
                // FOTO Y NOMBRE DE LA MASCOTA
                FutureBuilder<Mascota?>(
                  future: _obtenerMascota(solicitud.mascotaId),

                  builder: (context, mascotaSnapshot) {
                    final mascota = mascotaSnapshot.data;

                    final cargando =
                        mascotaSnapshot.connectionState ==
                        ConnectionState.waiting;

                    return Row(
                      children: [
                        PetPhoto(
                          imageUrl: mascota?.imagenUrl ?? '',
                          height: 78,
                          width: 78,
                          radius: BorderRadius.circular(18),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cargando
                                    ? 'Cargando mascota...'
                                    : mascota?.nombre ??
                                          'Mascota no disponible',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.quicksand(
                                  color: AppColors.ink,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),

                              const SizedBox(height: 9),

                              StatusPill(
                                text: _textoEstado(solicitud.estado),
                                color: _colorEstado(solicitud.estado),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 18),

                const Divider(color: AppColors.border, height: 1),

                const SizedBox(height: 16),

                // FECHA DE SOLICITUD
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
                        'Recibida el '
                        '${_formatearFecha(solicitud.fechaSolicitud)}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                // DATOS DEL ADOPTANTE
                _construirDatosAdoptante(solicitud.adoptanteId),

                // CUESTIONARIO COMPLETO
                _construirCuestionario(solicitud),

                const SizedBox(height: 21),

                // MOTIVO DE ADOPCION
                Row(
                  children: [
                    Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: AppColors.azulPastel,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: AppColors.primary,
                        size: 19,
                      ),
                    ),

                    const SizedBox(width: 11),

                    Expanded(
                      child: Text(
                        'Motivo de adopción',
                        style: GoogleFonts.quicksand(
                          color: AppColors.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: AppColors.azulSuave,
                    borderRadius: BorderRadius.circular(17),
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

                // BOTONES DE ACEPTAR Y RECHAZAR
                if (pendiente) ...[
                  const SizedBox(height: 22),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _procesando
                              ? null
                              : () {
                                  _gestionarSolicitud(
                                    solicitud,
                                    aceptar: false,
                                  );
                                },
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text('Rechazar'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            padding: const EdgeInsets.symmetric(horizontal: 9),
                          ),
                        ),
                      ),

                      const SizedBox(width: 11),

                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _procesando
                              ? null
                              : () {
                                  _gestionarSolicitud(solicitud, aceptar: true);
                                },
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Aceptar'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            padding: const EdgeInsets.symmetric(horizontal: 9),
                          ),
                        ),
                      ),
                    ],
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

  // ========================================
  // INTERFAZ PRINCIPAL
  // ========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text('Solicitudes recibidas'),
        backgroundColor: AppColors.background,
        scrolledUnderElevation: 0,
      ),

      body: Stack(
        children: [
          RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _actualizar,

            child: FutureBuilder<List<Solicitud>>(
              future: _futuroSolicitudes,

              builder: (context, snapshot) {
                final cargando =
                    snapshot.connectionState == ConnectionState.waiting;

                final solicitudes = [...?snapshot.data];

                solicitudes.sort((a, b) {
                  final fechaA = a.fechaSolicitud;
                  final fechaB = b.fechaSolicitud;

                  if (fechaA == null && fechaB == null) {
                    return 0;
                  }

                  if (fechaA == null) {
                    return 1;
                  }

                  if (fechaB == null) {
                    return -1;
                  }

                  return fechaB.compareTo(fechaA);
                });

                final pendientes = solicitudes
                    .where(
                      (solicitud) =>
                          solicitud.estado.toLowerCase() == 'pendiente',
                    )
                    .length;

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),

                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),

                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 38),

                      children: [
                        // ENCABEZADO
                        const PageHeading(
                          eyebrow: 'POSTULACIONES',
                          title: 'Solicitudes recibidas',
                          subtitle:
                              'Conocé a las personas '
                              'interesadas en adoptar '
                              'y ayudá a encontrar '
                              'el hogar ideal.',
                        ),

                        const SizedBox(height: 25),

                        // BANNER DE RESUMEN
                        _BannerSolicitudesRefugio(
                              total: solicitudes.length,
                              pendientes: pendientes,
                              cargando: cargando || snapshot.hasError,
                            )
                            .animate()
                            .fadeIn(duration: 450.ms)
                            .slideY(begin: 0.05, end: 0, duration: 450.ms),

                        const SizedBox(height: 31),

                        // TITULO DE SECCION
                        const SectionHeading(
                          title: 'Tus postulaciones',
                          subtitle:
                              'Revisá cada historia '
                              'con atención y cariño.',
                        ),

                        const SizedBox(height: 18),

                        // CARGA
                        if (cargando)
                          const _SolicitudesRefugioCargando()
                        // ERROR
                        else if (snapshot.hasError)
                          AppEmptyState(
                            icon: Icons.wifi_off_rounded,
                            title: 'No pudimos cargar las solicitudes',
                            message:
                                'Revisá tu conexión '
                                'e intentá nuevamente.',
                            actionLabel: 'Reintentar',
                            onAction: _actualizar,
                          )
                        // SIN SOLICITUDES
                        else if (solicitudes.isEmpty)
                          const AppEmptyState(
                            icon: Icons.inbox_outlined,
                            title: 'Todavía no recibiste solicitudes',
                            message:
                                'Cuando alguien quiera '
                                'adoptar una de tus mascotas, '
                                'su solicitud aparecerá acá.',
                          )
                        // LISTADO
                        else ...[
                          for (final solicitud in solicitudes)
                            _construirTarjetaSolicitud(solicitud),
                        ],

                        const SizedBox(height: 18),

                        const _ConsejoSolicitudesRefugio(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // INDICADOR DE OPERACION
          if (_procesando)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x440A345B),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

// ==========================================
// BANNER DE SOLICITUDES RECIBIDAS
// ==========================================

class _BannerSolicitudesRefugio extends StatelessWidget {
  final int total;
  final int pendientes;
  final bool cargando;

  const _BannerSolicitudesRefugio({
    required this.total,
    required this.pendientes,
    required this.cargando,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF70C9F5), Color(0xFF378FD5), Color(0xFF1C64B1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(29),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2756B8F2),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),

      clipBehavior: Clip.antiAlias,

      child: Stack(
        children: [
          const Positioned(
            right: -35,
            top: -40,
            child: Icon(
              Icons.volunteer_activism_rounded,
              size: 180,
              color: Color(0x20FFFFFF),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(23),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x35FFFFFF),
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
                        'NUEVAS OPORTUNIDADES',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'Cada solicitud puede\ncambiar una vida.',
                  style: GoogleFonts.quicksand(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    letterSpacing: -0.6,
                  ),
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    Expanded(
                      child: _ContadorRefugio(
                        icono: Icons.description_outlined,
                        cantidad: cargando ? '—' : '$total',
                        titulo: 'Recibidas',
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: _ContadorRefugio(
                        icono: Icons.schedule_rounded,
                        cantidad: cargando ? '—' : '$pendientes',
                        titulo: 'Pendientes',
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
// CONTADOR DE SOLICITUDES
// ==========================================

class _ContadorRefugio extends StatelessWidget {
  final IconData icono;
  final String cantidad;
  final String titulo;

  const _ContadorRefugio({
    required this.icono,
    required this.cantidad,
    required this.titulo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),

      decoration: BoxDecoration(
        color: const Color(0x30FFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x30FFFFFF)),
      ),

      child: Row(
        children: [
          Icon(icono, color: Colors.white, size: 23),

          const SizedBox(width: 10),

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
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  titulo,
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
// MENSAJE SIN DATOS DEL ADOPTANTE
// ==========================================

class _MensajeDatosNoDisponibles extends StatelessWidget {
  const _MensajeDatosNoDisponibles();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 17),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.azulSuave,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.person_off_outlined, color: AppColors.primary, size: 23),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Datos del adoptante no disponibles.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// TARJETAS DE CARGA
// ==========================================

class _SolicitudesRefugioCargando extends StatelessWidget {
  const _SolicitudesRefugioCargando();

  @override
  Widget build(BuildContext context) {
    return const Skeletonizer(
      enabled: true,
      child: Column(
        children: [
          _TarjetaSolicitudCargando(),
          SizedBox(height: 16),
          _TarjetaSolicitudCargando(),
        ],
      ),
    );
  }
}

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
          const Row(
            children: [
              Skeleton.leaf(
                child: SizedBox(
                  width: 78,
                  height: 78,
                  child: ColoredBox(color: AppColors.azulPastel),
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nombre de la mascota'),
                    SizedBox(height: 12),
                    Text('Estado de solicitud'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          const Text('Fecha de la solicitud'),
          const SizedBox(height: 18),
          const Text(
            'Nombre del adoptante',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 13),
          const Text('Correo electrónico'),
          const SizedBox(height: 22),
          const Text(
            'Información del hogar y cuidados',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 13),
          const Text('Respuestas del cuestionario'),
          const SizedBox(height: 18),
          const Text('Motivo de adopción'),
        ],
      ),
    );
  }
}

// ==========================================
// CONSEJO FINAL
// ==========================================

class _ConsejoSolicitudesRefugio extends StatelessWidget {
  const _ConsejoSolicitudesRefugio();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.azulSuave,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: AppColors.primary,
            size: 23,
          ),
          SizedBox(width: 13),
          Expanded(
            child: Text(
              'Revisá con atención las respuestas '
              'de cada adoptante antes de aceptar '
              'una solicitud. Una adopción responsable '
              'comienza con una buena decisión.',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 12,
                height: 1.55,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
