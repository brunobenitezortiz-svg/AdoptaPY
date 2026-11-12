import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../models/mascota.dart';
import '../../theme/app_theme.dart';
import '../../widgets/adopta_widgets.dart';
import '../../services/auth_service.dart';
import '../../services/mascota_service.dart';
import 'publicar_mascota_screen.dart';

// ==========================================
// GESTION DE MASCOTAS DEL REFUGIO
// ==========================================

class MascotasScreen extends StatefulWidget {
  const MascotasScreen({super.key});

  @override
  State<MascotasScreen> createState() => _MascotasScreenState();
}

class _MascotasScreenState extends State<MascotasScreen> {
  late Future<List<Mascota>> _mascotasFuture;

  final Set<String> _renovandoMascotas = {};
  final Set<String> _eliminandoMascotas = {};

  @override
  void initState() {
    super.initState();
    _cargarMascotas();
  }

  // ========================================
  // CARGAR MASCOTAS DEL REFUGIO
  // ========================================

  void _cargarMascotas() {
    final usuario = AuthService().usuarioActual;

    if (usuario == null) {
      _mascotasFuture = Future.value([]);
      return;
    }

    _mascotasFuture = MascotaService().obtenerMascotasDelRefugio(usuario.uid);
  }

  // ========================================
  // ACTUALIZAR PUBLICACIONES
  // ========================================

  Future<void> _recargarMascotas() async {
    setState(_cargarMascotas);

    try {
      await _mascotasFuture;
    } catch (_) {
      // FutureBuilder mostrará el error.
    }
  }

  // ========================================
  // FORMATEAR FECHA
  // ========================================

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) {
      return 'No disponible';
    }

    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString();

    return '$dia/$mes/$anio';
  }

  bool _estaProcesando(String id) {
    return _renovandoMascotas.contains(id) || _eliminandoMascotas.contains(id);
  }

  // ========================================
  // RENOVAR PUBLICACION
  // ========================================

  Future<void> _renovarMascota(Mascota mascota) async {
    if (mascota.estado != 'disponible' ||
        !mascota.estaVencida ||
        _estaProcesando(mascota.id)) {
      return;
    }

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
                child: const Icon(
                  Icons.autorenew_rounded,
                  color: AppColors.primary,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Renovar publicación',
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
            '¿Querés renovar la publicación de '
            '${mascota.nombre} por otros 7 días?\n\n'
            'La fecha original de publicación '
            'se conservará.',
            style: const TextStyle(
              color: AppColors.muted,
              height: 1.55,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Renovar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true || !mounted) return;
    if (_estaProcesando(mascota.id)) return;

    setState(() {
      _renovandoMascotas.add(mascota.id);
    });

    try {
      final nuevaFecha = DateTime.now().add(const Duration(days: 7));

      await FirebaseFirestore.instance
          .collection('mascotas')
          .doc(mascota.id)
          .update({'fechaVencimiento': Timestamp.fromDate(nuevaFecha)});

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'La publicación de ${mascota.nombre} '
            'se renovó por 7 días.',
          ),
        ),
      );

      await _recargarMascotas();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo renovar la publicación. '
            'Intentá nuevamente.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _renovandoMascotas.remove(mascota.id);
        });
      }
    }
  }

  // ========================================
  // ELIMINAR PUBLICACION
  // ========================================

  Future<void> _eliminarMascota(Mascota mascota) async {
    if (_estaProcesando(mascota.id)) return;

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
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.primary,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Eliminar mascota',
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
            '¿Querés eliminar a ${mascota.nombre}?\n\n'
            'Esta acción no se puede deshacer.',
            style: const TextStyle(
              color: AppColors.muted,
              height: 1.55,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true || !mounted) return;
    if (_estaProcesando(mascota.id)) return;

    setState(() {
      _eliminandoMascotas.add(mascota.id);
    });

    try {
      await MascotaService().eliminarMascota(mascota.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${mascota.nombre} fue eliminada correctamente.'),
        ),
      );

      await _recargarMascotas();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar la mascota.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _eliminandoMascotas.remove(mascota.id);
        });
      }
    }
  }

  // ========================================
  // EDITAR MASCOTA
  // ========================================

  Future<void> _editarMascota(Mascota mascota) async {
    if (_estaProcesando(mascota.id)) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PublicarMascotaScreen(mascota: mascota),
      ),
    );

    if (!mounted) return;

    await _recargarMascotas();
  }

  // ========================================
  // PUBLICAR NUEVA MASCOTA
  // ========================================

  Future<void> _publicarMascota() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PublicarMascotaScreen()),
    );

    if (!mounted) return;

    await _recargarMascotas();
  }

  // ========================================
  // INTERFAZ PRINCIPAL
  // ========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mis mascotas'),
        backgroundColor: AppColors.background,
        scrolledUnderElevation: 0,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _recargarMascotas,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: FutureBuilder<List<Mascota>>(
              future: _mascotasFuture,
              builder: (context, snapshot) {
                final cargando =
                    snapshot.connectionState == ConnectionState.waiting;

                final mascotas = snapshot.data ?? [];

                final disponibles = mascotas
                    .where(
                      (mascota) =>
                          mascota.estado == 'disponible' &&
                          !mascota.estaVencida,
                    )
                    .length;

                final vencidas = mascotas
                    .where(
                      (mascota) =>
                          mascota.estado == 'disponible' && mascota.estaVencida,
                    )
                    .length;

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 38),
                  children: [
                    // ENCABEZADO
                    const PageHeading(
                      eyebrow: 'GESTIÓN DEL REFUGIO',
                      title: 'Mis publicaciones',
                      subtitle:
                          'Administrá los perfiles de tus '
                          'mascotas y mantené sus '
                          'publicaciones actualizadas.',
                    ),

                    const SizedBox(height: 25),

                    // BANNER
                    _BannerPublicaciones(onPublicar: _publicarMascota)
                        .animate()
                        .fadeIn(duration: 450.ms)
                        .slideY(begin: 0.05, end: 0, duration: 450.ms),

                    const SizedBox(height: 25),

                    // RESUMEN
                    _ResumenPublicaciones(
                      total: mascotas.length,
                      disponibles: disponibles,
                      vencidas: vencidas,
                      cargando: cargando || snapshot.hasError,
                    ),

                    const SizedBox(height: 30),

                    const SectionHeading(
                      title: 'Tus mascotas',
                      subtitle:
                          'Gestioná cada publicación '
                          'desde su tarjeta.',
                    ),

                    const SizedBox(height: 17),

                    // ESTADO DE CARGA
                    if (cargando)
                      const _PublicacionesCargando()
                    // ESTADO DE ERROR
                    else if (snapshot.hasError)
                      AppEmptyState(
                        icon: Icons.wifi_off_rounded,
                        title: 'No pudimos cargar tus publicaciones',
                        message:
                            'Revisá tu conexión e intentá '
                            'nuevamente.',
                        actionLabel: 'Reintentar',
                        onAction: _recargarMascotas,
                      )
                    // ESTADO VACIO
                    else if (mascotas.isEmpty)
                      AppEmptyState(
                        icon: Icons.pets_outlined,
                        title: 'Todavía no publicaste mascotas',
                        message:
                            'Publicá tu primera mascota '
                            'para ayudarla a encontrar '
                            'una familia.',
                        actionLabel: 'Publicar mascota',
                        onAction: _publicarMascota,
                      )
                    // LISTADO DE PUBLICACIONES
                    else ...[
                      for (final mascota in mascotas)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _TarjetaPublicacion(
                            mascota: mascota,
                            fechaPublicacion: _formatearFecha(
                              mascota.fechaPublicacion,
                            ),
                            fechaVencimiento: _formatearFecha(
                              mascota.vencimiento,
                            ),
                            renovando: _renovandoMascotas.contains(mascota.id),
                            eliminando: _eliminandoMascotas.contains(
                              mascota.id,
                            ),
                            onEditar: () {
                              _editarMascota(mascota);
                            },
                            onEliminar: () {
                              _eliminarMascota(mascota);
                            },
                            onRenovar: () {
                              _renovarMascota(mascota);
                            },
                          ),
                        ),
                    ],

                    const SizedBox(height: 15),

                    // CONSEJO
                    const _ConsejoPublicaciones(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// BANNER DE PUBLICACIONES
// ==========================================

class _BannerPublicaciones extends StatelessWidget {
  final VoidCallback onPublicar;

  const _BannerPublicaciones({required this.onPublicar});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF70C9F5), Color(0xFF378ED5), Color(0xFF1C64B1)],
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
            right: -40,
            top: -45,
            child: Icon(
              Icons.pets_rounded,
              color: Color(0x22FFFFFF),
              size: 185,
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
                        'UN HOGAR PARA CADA MASCOTA',
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
                const SizedBox(height: 21),
                Text(
                  'Cada publicación\nabre una puerta.',
                  style: GoogleFonts.quicksand(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    height: 1.17,
                  ),
                ),
                const SizedBox(height: 11),
                const Text(
                  'Compartí nuevas historias y ayudá '
                  'a encontrar familias.',
                  style: TextStyle(
                    color: Color(0xFFF0FAFF),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 21),
                FilledButton.icon(
                  onPressed: onPublicar,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 11,
                    ),
                  ),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 19),
                  label: const Text('Nueva publicación'),
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
// RESUMEN DE PUBLICACIONES
// ==========================================

class _ResumenPublicaciones extends StatelessWidget {
  final int total;
  final int disponibles;
  final int vencidas;
  final bool cargando;

  const _ResumenPublicaciones({
    required this.total,
    required this.disponibles,
    required this.vencidas,
    required this.cargando,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ContadorPublicaciones(
            cantidad: cargando ? '—' : '$total',
            titulo: 'Total',
            icono: Icons.pets_rounded,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _ContadorPublicaciones(
            cantidad: cargando ? '—' : '$disponibles',
            titulo: 'Disponibles',
            icono: Icons.check_circle_outline_rounded,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _ContadorPublicaciones(
            cantidad: cargando ? '—' : '$vencidas',
            titulo: 'Vencidas',
            icono: Icons.schedule_rounded,
          ),
        ),
      ],
    );
  }
}

class _ContadorPublicaciones extends StatelessWidget {
  final String cantidad;
  final String titulo;
  final IconData icono;

  const _ContadorPublicaciones({
    required this.cantidad,
    required this.titulo,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icono, color: AppColors.primary, size: 22),
          const SizedBox(height: 9),
          Text(
            cantidad,
            style: GoogleFonts.quicksand(
              color: AppColors.ink,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            maxLines: 1,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// TARJETA DE PUBLICACION
// ==========================================

class _TarjetaPublicacion extends StatelessWidget {
  final Mascota mascota;
  final String fechaPublicacion;
  final String fechaVencimiento;
  final bool renovando;
  final bool eliminando;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;
  final VoidCallback onRenovar;

  const _TarjetaPublicacion({
    required this.mascota,
    required this.fechaPublicacion,
    required this.fechaVencimiento,
    required this.renovando,
    required this.eliminando,
    required this.onEditar,
    required this.onEliminar,
    required this.onRenovar,
  });

  @override
  Widget build(BuildContext context) {
    final vencida = mascota.estaVencida;
    final disponible = mascota.estado == 'disponible';
    final puedeRenovar = disponible && vencida;
    final procesando = renovando || eliminando;

    final textoEstado = puedeRenovar
        ? 'Publicación vencida'
        : disponible
        ? 'Disponible'
        : mascota.estado;

    final colorEstado = puedeRenovar
        ? const Color(0xFFB58025)
        : disponible
        ? AppColors.primary
        : AppColors.muted;

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
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FOTO Y DATOS PRINCIPALES
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PetPhoto(
                  imageUrl: mascota.imagenUrl,
                  height: 88,
                  width: 88,
                  radius: BorderRadius.circular(18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mascota.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.quicksand(
                          color: AppColors.ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${mascota.especie} · ${mascota.raza}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        '${mascota.edad} · ${mascota.sexo} · ${mascota.tamano}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ESTADO DE PUBLICACION
            StatusPill(text: textoEstado, color: colorEstado),

            const SizedBox(height: 17),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 17),

            // FECHAS
            _FechaPublicacion(
              icono: Icons.calendar_today_outlined,
              titulo: 'Publicado',
              fecha: fechaPublicacion,
            ),
            const SizedBox(height: 12),
            _FechaPublicacion(
              icono: vencida
                  ? Icons.event_busy_outlined
                  : Icons.event_available_outlined,
              titulo: 'Vencimiento',
              fecha: fechaVencimiento,
            ),

            const SizedBox(height: 18),

            // ACCIONES DE EDICION Y ELIMINACION
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: [
                OutlinedButton.icon(
                  onPressed: procesando ? null : onEditar,
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: const Text('Editar'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: procesando ? null : onEliminar,
                  icon: eliminando
                      ? const SizedBox(
                          height: 17,
                          width: 17,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline_rounded, size: 17),
                  label: Text(eliminando ? 'Eliminando...' : 'Eliminar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),

            // RENOVACION DE PUBLICACION VENCIDA
            if (puedeRenovar) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: procesando ? null : onRenovar,
                  icon: renovando
                      ? const SizedBox(
                          height: 19,
                          width: 19,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.autorenew_rounded, size: 19),
                  label: Text(
                    renovando ? 'Renovando...' : 'Renovar por 7 días',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ==========================================
// FILA DE FECHA
// ==========================================

class _FechaPublicacion extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String fecha;

  const _FechaPublicacion({
    required this.icono,
    required this.titulo,
    required this.fecha,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 33,
          height: 33,
          decoration: BoxDecoration(
            color: AppColors.azulPastel,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icono, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            '$titulo: $fecha',
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// CARGA CON SKELETONIZER
// ==========================================

class _PublicacionesCargando extends StatelessWidget {
  const _PublicacionesCargando();

  @override
  Widget build(BuildContext context) {
    return const Skeletonizer(
      enabled: true,
      child: Column(
        children: [
          _TarjetaPublicacionCargando(),
          SizedBox(height: 16),
          _TarjetaPublicacionCargando(),
        ],
      ),
    );
  }
}

class _TarjetaPublicacionCargando extends StatelessWidget {
  const _TarjetaPublicacionCargando();

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
        children: [
          Row(
            children: [
              const Skeleton.leaf(
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: ColoredBox(color: AppColors.azulPastel),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nombre de mascota'),
                    SizedBox(height: 12),
                    Text('Especie y raza'),
                    SizedBox(height: 8),
                    Text('Edad y tamaño'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 14),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Fecha de publicación'),
          ),
          const SizedBox(height: 14),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Fecha de vencimiento'),
          ),
          const SizedBox(height: 20),
          const Row(
            children: [
              Text('Editar publicación'),
              SizedBox(width: 18),
              Text('Eliminar'),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================
// CONSEJO PARA EL REFUGIO
// ==========================================

class _ConsejoPublicaciones extends StatelessWidget {
  const _ConsejoPublicaciones();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.azulSuave,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            size: 24,
            color: AppColors.primary,
          ),
          SizedBox(width: 13),
          Expanded(
            child: Text(
              'Recordá revisar las fechas de vencimiento '
              'y mantener las fotografías y descripciones '
              'de tus mascotas actualizadas.',
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
