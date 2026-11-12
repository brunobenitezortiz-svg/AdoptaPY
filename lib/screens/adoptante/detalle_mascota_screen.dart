import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../models/mascota.dart';
import '../../theme/app_theme.dart';
import '../../widgets/adopta_widgets.dart';
import '../../services/auth_service.dart';
import '../../services/favorito_service.dart';
import '../../services/solicitud_service.dart';

// ==========================================
// PANTALLA DE DETALLE DE MASCOTA
// ==========================================

class DetalleMascotaScreen extends StatefulWidget {
  final Mascota mascota;

  const DetalleMascotaScreen({super.key, required this.mascota});

  @override
  State<DetalleMascotaScreen> createState() => _DetalleMascotaScreenState();
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

  // ========================================
  // CARGAR INFORMACION DEL REFUGIO
  // ========================================

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

  // ========================================
  // CONSULTAR FAVORITO
  // ========================================

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

  // ========================================
  // AGREGAR O QUITAR FAVORITO
  // ========================================

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
        const SnackBar(content: Text('No se pudo actualizar el favorito.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _actualizandoFavorito = false;
        });
      }
    }
  }

  // ========================================
  // ENVIAR SOLICITUD DE ADOPCION
  // ========================================

  Future<void> _solicitarAdopcion() async {
    final usuario = AuthService().usuarioActual;

    if (usuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Iniciá sesión para solicitar una adopción.'),
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
        return _FormularioAdopcionDialog(nombreMascota: widget.mascota.nombre);
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
        const SnackBar(content: Text('¡Solicitud de adopción enviada!')),
      );
    } catch (e) {
      if (!mounted) return;

      final error = e.toString();

      String mensajeError =
          'No se pudo enviar la solicitud. Intentá nuevamente.';

      if (error.contains('Ya tenés una solicitud pendiente')) {
        mensajeError = 'Ya tenés una solicitud pendiente para esta mascota.';
      } else if (error.contains('ya no está disponible')) {
        mensajeError = 'Esta mascota ya no está disponible para adopción.';
      } else if (error.contains('permission-denied')) {
        mensajeError =
            'La publicación puede haber vencido o ya no estar disponible.';
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensajeError)));
    } finally {
      if (mounted) {
        setState(() {
          _enviandoSolicitud = false;
        });
      }
    }
  }

  // ========================================
  // INFORMACION DEL REFUGIO
  // ========================================

  Widget _construirSeccionRefugio() {
    if (_cargandoRefugio) {
      return Skeletonizer(
        enabled: true,
        child: _TarjetaSuperficie(
          child: Row(
            children: [
              const Skeleton.leaf(
                child: CircleAvatar(
                  radius: 27,
                  backgroundColor: AppColors.azulPastel,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nombre del refugio',
                      style: GoogleFonts.quicksand(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Correo electrónico del refugio'),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_nombreRefugio == null && _emailRefugio == null) {
      return const _TarjetaSuperficie(
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: AppColors.primary,
              size: 25,
            ),
            SizedBox(width: 13),
            Expanded(
              child: Text(
                'No se pudieron cargar los datos del refugio.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _TarjetaSuperficie(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 57,
                height: 57,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.azulPastel, AppColors.azulClaro],
                  ),
                  borderRadius: BorderRadius.circular(19),
                ),
                child: const Icon(
                  Icons.home_work_rounded,
                  color: AppColors.primary,
                  size: 28,
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
                      style: GoogleFonts.quicksand(
                        color: AppColors.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      'Responsable de esta mascota',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.verified_rounded,
                color: AppColors.primary,
                size: 21,
              ),
            ],
          ),

          if (_emailRefugio?.isNotEmpty == true) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Divider(color: AppColors.border, height: 1),
            ),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.mail_outline_rounded,
                  color: AppColors.primary,
                  size: 20,
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
                        _emailRefugio!,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ========================================
  // INTERFAZ PRINCIPAL
  // ========================================

  @override
  Widget build(BuildContext context) {
    final mascota = widget.mascota;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const BrandLogo(compact: true),
        scrolledUnderElevation: 0,
        actions: [
          if (_cargandoFavorito)
            const Padding(
              padding: EdgeInsets.all(15),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              tooltip: _esFavorito
                  ? 'Quitar de favoritos'
                  : 'Agregar a favoritos',
              onPressed: _actualizandoFavorito ? null : _cambiarFavorito,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.azulSuave,
                foregroundColor: AppColors.primary,
              ),
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Icon(
                  _esFavorito
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  key: ValueKey(_esFavorito),
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
            ),

          const SizedBox(width: 13),
        ],
      ),

      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ==================================
                  // FOTO PRINCIPAL
                  // ==================================

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 9, 16, 0),

                    child: _FotoPrincipal(mascota: mascota)
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.035, end: 0, duration: 400.ms),
                  ),

                  // ==================================
                  // INFORMACION GENERAL
                  // ==================================
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 26, 20, 38),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // NOMBRE DE LA MASCOTA
                        Text(
                          mascota.nombre,
                          style: GoogleFonts.quicksand(
                            color: AppColors.ink,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                            letterSpacing: -1,
                          ),
                        ),

                        const SizedBox(height: 9),

                        // ESPECIE Y RAZA
                        Row(
                          children: [
                            const Icon(
                              Icons.pets_rounded,
                              color: AppColors.celeste,
                              size: 19,
                            ),

                            const SizedBox(width: 9),

                            Expanded(
                              child: Text(
                                '${mascota.especie} · ${mascota.raza}',
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 25),

                        // CARACTERISTICAS
                        Row(
                          children: [
                            Expanded(
                              child: _DatoMascota(
                                icono: Icons.cake_outlined,
                                titulo: 'Edad',
                                valor: mascota.edad,
                              ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: _DatoMascota(
                                icono: Icons.wc_rounded,
                                titulo: 'Sexo',
                                valor: mascota.sexo,
                              ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: _DatoMascota(
                                icono: Icons.straighten_rounded,
                                titulo: 'Tamaño',
                                valor: mascota.tamano,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // ==================================
                        // HISTORIA
                        // ==================================
                        const _TituloDetalle(
                          icono: Icons.favorite_outline_rounded,
                          titulo: 'Conocé mi historia',
                        ),

                        const SizedBox(height: 15),

                        _TarjetaSuperficie(
                          child: Text(
                            mascota.descripcion.isNotEmpty
                                ? mascota.descripcion
                                : 'Todavía no hay una descripción disponible.',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 14,
                              height: 1.75,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ==================================
                        // PUBLICACION
                        // ==================================
                        const _TituloDetalle(
                          icono: Icons.info_outline_rounded,
                          titulo: 'Información de adopción',
                        ),

                        const SizedBox(height: 15),

                        _TarjetaSuperficie(
                          child: Column(
                            children: [
                              _LineaInformacion(
                                icono: Icons.check_circle_outline,
                                titulo: 'Estado',
                                valor: mascota.estado,
                              ),

                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 17),
                                child: Divider(
                                  color: AppColors.border,
                                  height: 1,
                                ),
                              ),

                              _LineaInformacion(
                                icono: Icons.calendar_today_outlined,
                                titulo: 'Publicado',
                                valor: _formatearFecha(
                                  mascota.fechaPublicacion,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 29),

                        // ==================================
                        // REFUGIO
                        // ==================================
                        const _TituloDetalle(
                          icono: Icons.home_work_outlined,
                          titulo: 'El refugio que me cuida',
                        ),

                        const SizedBox(height: 15),

                        _construirSeccionRefugio(),

                        const SizedBox(height: 25),

                        // MENSAJE FINAL
                        const _MensajeDetalle(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // ==================================
      // BOTON FIJO DE ADOPCION
      // ==================================
      bottomNavigationBar: mascota.disponibleParaAdopcion
          ? SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 13, 20, 14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.border)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x10164E86),
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Center(
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: SizedBox(
                      width: double.infinity,
                      height: 57,
                      child: FilledButton.icon(
                        onPressed: _enviandoSolicitud
                            ? null
                            : _solicitarAdopcion,
                        icon: _enviandoSolicitud
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.favorite_rounded, size: 22),
                        label: Text(
                          _enviandoSolicitud
                              ? 'Enviando solicitud...'
                              : 'Quiero adoptar a ${mascota.nombre}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

// ==========================================
// FOTOGRAFIA PRINCIPAL
// ==========================================

class _FotoPrincipal extends StatelessWidget {
  final Mascota mascota;

  const _FotoPrincipal({required this.mascota});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 315,
      decoration: BoxDecoration(
        color: AppColors.azulPastel,
        borderRadius: BorderRadius.circular(29),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1456B8F2),
            blurRadius: 22,
            offset: Offset(0, 9),
          ),
        ],
      ),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(29),

        child: Stack(
          fit: StackFit.expand,
          children: [
            PetPhoto(
              imageUrl: mascota.imagenUrl,
              width: double.infinity,
              height: 315,
              radius: BorderRadius.zero,
            ),

            // SOMBRA SUAVE INFERIOR
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0x550A345B)],
                    stops: [0.55, 1],
                  ),
                ),
              ),
            ),

            // ETIQUETA SUPERIOR
            Positioned(
              top: 17,
              left: 17,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      mascota.disponibleParaAdopcion
                          ? Icons.favorite_rounded
                          : Icons.info_outline_rounded,
                      color: AppColors.primary,
                      size: 16,
                    ),

                    const SizedBox(width: 7),

                    Text(
                      mascota.disponibleParaAdopcion
                          ? 'Buscando una familia'
                          : 'No disponible',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // MENSAJE INFERIOR
            const Positioned(
              left: 20,
              bottom: 21,
              right: 20,
              child: Row(
                children: [
                  Icon(Icons.pets_rounded, color: Colors.white, size: 19),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Mi próxima historia puede ser con vos.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// CARACTERISTICAS DE LA MASCOTA
// ==========================================

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
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.azulSuave,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: AppColors.azulPastel,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icono, color: AppColors.primary, size: 19),
          ),

          const SizedBox(height: 9),

          Text(
            titulo,
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),

          const SizedBox(height: 5),

          Text(
            valor,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// TITULOS DE SECCIONES
// ==========================================

class _TituloDetalle extends StatelessWidget {
  final IconData icono;
  final String titulo;

  const _TituloDetalle({required this.icono, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 37,
          height: 37,
          decoration: BoxDecoration(
            color: AppColors.azulPastel,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icono, color: AppColors.primary, size: 20),
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Text(
            titulo,
            style: GoogleFonts.quicksand(
              color: AppColors.ink,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// TARJETA DE SUPERFICIE REUTILIZABLE
// ==========================================

class _TarjetaSuperficie extends StatelessWidget {
  final Widget child;

  const _TarjetaSuperficie({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B164E86),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ==========================================
// LINEAS DE INFORMACION
// ==========================================

class _LineaInformacion extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;

  const _LineaInformacion({
    required this.icono,
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 37,
          height: 37,
          decoration: BoxDecoration(
            color: AppColors.azulSuave,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icono, color: AppColors.primary, size: 19),
        ),

        const SizedBox(width: 13),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                valor,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ==========================================
// MENSAJE INFERIOR
// ==========================================

class _MensajeDetalle extends StatelessWidget {
  const _MensajeDetalle();

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
          Icon(Icons.favorite_rounded, color: AppColors.primary, size: 24),
          SizedBox(width: 13),
          Expanded(
            child: Text(
              'Adoptar es mucho más que dar un hogar. '
              'Es comenzar una historia de amor.',
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

// ==========================================
// DATOS DEL FORMULARIO DE ADOPCION
// ==========================================

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

// ==========================================
// FORMULARIO DE ADOPCION
// ==========================================

class _FormularioAdopcionDialog extends StatefulWidget {
  final String nombreMascota;

  const _FormularioAdopcionDialog({required this.nombreMascota});

  @override
  State<_FormularioAdopcionDialog> createState() =>
      _FormularioAdopcionDialogState();
}

class _FormularioAdopcionDialogState extends State<_FormularioAdopcionDialog> {
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

  // ========================================
  // TITULO DE SECCION DEL FORMULARIO
  // ========================================

  Widget _tituloSeccion(IconData icono, String titulo) {
    return Padding(
      padding: const EdgeInsets.only(top: 15, bottom: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.azulPastel,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icono, color: AppColors.primary, size: 21),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Text(
              titulo,
              style: GoogleFonts.quicksand(
                color: AppColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // SELECTOR DE SI O NO
  // ========================================

  Widget _selectorSiNo({
    required String pregunta,
    required bool? valor,
    required ValueChanged<bool?> alCambiar,
  }) {
    return FormField<bool>(
      key: ValueKey(pregunta),
      initialValue: valor,
      validator: (valorCampo) {
        if (valorCampo == null) {
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
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 11),

            Wrap(
              spacing: 10,
              runSpacing: 9,
              children: [
                _OpcionSiNo(
                  texto: 'Sí',
                  seleccionado: campo.value == true,
                  onTap: () {
                    campo.didChange(true);
                    alCambiar(true);
                  },
                ),

                _OpcionSiNo(
                  texto: 'No',
                  seleccionado: campo.value == false,
                  onTap: () {
                    campo.didChange(false);
                    alCambiar(false);
                  },
                ),
              ],
            ),

            if (campo.hasError) ...[
              const SizedBox(height: 8),
              Text(
                campo.errorText!,
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ],
          ],
        );
      },
    );
  }

  // ========================================
  // VALIDAR Y DEVOLVER FORMULARIO
  // ========================================

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

  // ========================================
  // INTERFAZ DEL FORMULARIO
  // ========================================

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      titlePadding: const EdgeInsets.fromLTRB(22, 23, 22, 0),
      contentPadding: const EdgeInsets.fromLTRB(22, 15, 22, 5),
      actionsPadding: const EdgeInsets.fromLTRB(17, 12, 17, 18),
      scrollable: true,

      // ==================================
      // CABECERA DEL FORMULARIO
      // ==================================
      title: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.celeste, AppColors.primary],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Solicitud de adopción',
                  style: GoogleFonts.quicksand(
                    color: AppColors.ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  'Un nuevo comienzo',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),

      // ==================================
      // CONTENIDO DEL FORMULARIO
      // ==================================
      content: SizedBox(
        width: 480,

        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // INTRODUCCION
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.azulSuave,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '¡Qué emoción que quieras adoptar '
                  'a ${widget.nombreMascota}! '
                  'Contanos un poquito sobre vos '
                  'para que el refugio pueda conocerte.',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    height: 1.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ==================================
              // TU HOGAR
              // ==================================
              _tituloSeccion(Icons.home_outlined, 'Tu hogar'),

              DropdownButtonFormField<String>(
                initialValue: _tipoVivienda,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Tipo de vivienda',
                  prefixIcon: Icon(Icons.home_work_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'casa', child: Text('Casa')),
                  DropdownMenuItem(
                    value: 'departamento',
                    child: Text('Departamento'),
                  ),
                  DropdownMenuItem(value: 'otro', child: Text('Otro')),
                ],
                onChanged: (valor) {
                  setState(() {
                    _tipoVivienda = valor;
                  });
                },
                validator: (valor) =>
                    valor == null ? 'Seleccioná tu tipo de vivienda.' : null,
              ),

              const SizedBox(height: 22),

              _selectorSiNo(
                pregunta: '¿Tenés patio?',
                valor: _tienePatio,
                alCambiar: (valor) {
                  setState(() {
                    _tienePatio = valor;
                  });
                },
              ),

              const SizedBox(height: 13),

              // ==================================
              // DISPONIBILIDAD
              // ==================================
              _tituloSeccion(Icons.schedule_outlined, 'Tu disponibilidad'),

              DropdownButtonFormField<String>(
                initialValue: _tiempoDisponible,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Tiempo diario disponible',
                  prefixIcon: Icon(Icons.access_time_rounded),
                ),
                items: const [
                  DropdownMenuItem(value: '1-2', child: Text('1 a 2 horas')),
                  DropdownMenuItem(value: '3-5', child: Text('3 a 5 horas')),
                  DropdownMenuItem(value: '6+', child: Text('Más de 5 horas')),
                ],
                onChanged: (valor) {
                  setState(() {
                    _tiempoDisponible = valor;
                  });
                },
                validator: (valor) =>
                    valor == null ? 'Seleccioná una opción.' : null,
              ),

              const SizedBox(height: 12),

              // ==================================
              // CONVIVENCIA
              // ==================================
              _tituloSeccion(Icons.family_restroom_outlined, 'Convivencia'),

              _selectorSiNo(
                pregunta: '¿Conviven niños en tu hogar?',
                valor: _tieneHijos,
                alCambiar: (valor) {
                  setState(() {
                    _tieneHijos = valor;
                  });
                },
              ),

              const SizedBox(height: 23),

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
                const SizedBox(height: 16),

                TextFormField(
                  controller: _otrasMascotasController,
                  maxLength: 300,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: '¿Cuáles y cuántas?',
                    hintText: 'Ej.: 2 perros y 1 gato',
                    alignLabelWithHint: true,
                  ),
                  validator: (valor) {
                    if (_tieneOtrasMascotas == true &&
                        (valor == null || valor.trim().isEmpty)) {
                      return 'Describí tus otras mascotas.';
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 12),

              // ==================================
              // EXPERIENCIA
              // ==================================
              _tituloSeccion(Icons.volunteer_activism_outlined, 'Experiencia'),

              _selectorSiNo(
                pregunta: '¿Tuviste mascotas anteriormente?',
                valor: _experienciaMascotas,
                alCambiar: (valor) {
                  setState(() {
                    _experienciaMascotas = valor;
                  });
                },
              ),

              const SizedBox(height: 13),

              // ==================================
              // MOTIVO DE ADOPCION
              // ==================================
              _tituloSeccion(Icons.edit_note_outlined, 'Motivo de adopción'),

              TextFormField(
                controller: _mensajeController,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Mensaje para el refugio',
                  hintText:
                      'Contá por qué querés adoptar '
                      'y cómo cuidarías a la mascota...',
                  alignLabelWithHint: true,
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Escribí un mensaje para el refugio.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 9),

              // AVISO DE PRIVACIDAD
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: AppColors.azulSuave,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primary,
                      size: 19,
                    ),

                    SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        'Tus respuestas serán compartidas '
                        'con el refugio responsable '
                        'de esta mascota.',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // ==================================
      // ACCIONES DEL FORMULARIO
      // ==================================
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancelar'),
        ),

        FilledButton.icon(
          onPressed: _enviar,
          icon: const Icon(Icons.send_rounded, size: 18),
          label: const Text('Enviar solicitud'),
        ),
      ],
    );
  }
}

// ==========================================
// OPCIONES SI / NO
// ==========================================

class _OpcionSiNo extends StatelessWidget {
  final String texto;
  final bool seleccionado;
  final VoidCallback onTap;

  const _OpcionSiNo({
    required this.texto,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: seleccionado ? AppColors.azulPastel : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: seleccionado ? AppColors.primary : AppColors.border,
          width: seleccionado ? 1.6 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  seleccionado
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: seleccionado ? AppColors.primary : AppColors.muted,
                  size: 18,
                ),

                const SizedBox(width: 8),

                Text(
                  texto,
                  style: TextStyle(
                    color: seleccionado ? AppColors.primaryDark : AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
