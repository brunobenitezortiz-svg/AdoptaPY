import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../models/favorito.dart';
import '../../models/mascota.dart';
import '../../services/auth_service.dart';
import '../../services/favorito_service.dart';
import '../../services/mascota_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/adopta_widgets.dart';

import 'detalle_mascota_screen.dart';

// ==========================================
// PANTALLA DE FAVORITOS
// ==========================================

class FavoritosScreen extends StatefulWidget {
  const FavoritosScreen({super.key});

  @override
  State<FavoritosScreen> createState() => _FavoritosScreenState();
}

class _FavoritosScreenState extends State<FavoritosScreen> {
  late Future<List<Mascota>> _mascotasFuture;

  @override
  void initState() {
    super.initState();
    _cargarFavoritos();
  }

  // ========================================
  // CARGAR FAVORITOS
  // ========================================

  void _cargarFavoritos() {
    _mascotasFuture = _obtenerMascotasFavoritas();
  }

  Future<List<Mascota>> _obtenerMascotasFavoritas() async {
    final usuario = AuthService().usuarioActual;

    if (usuario == null) {
      return [];
    }

    final favoritos = await FavoritoService().obtenerFavoritos(usuario.uid);

    final List<Mascota> mascotas = [];

    for (final Favorito favorito in favoritos) {
      final mascota = await MascotaService().obtenerMascotaPorId(
        favorito.mascotaId,
      );

      if (mascota != null) {
        mascotas.add(mascota);
      }
    }

    return mascotas;
  }

  // ========================================
  // ACTUALIZAR FAVORITOS
  // ========================================

  Future<void> _recargarFavoritos() async {
    setState(_cargarFavoritos);

    try {
      await _mascotasFuture;
    } catch (_) {
      // FutureBuilder mostrará el error.
    }
  }

  // ========================================
  // ABRIR DETALLE DE MASCOTA
  // ========================================

  Future<void> _abrirDetalle(Mascota mascota) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetalleMascotaScreen(mascota: mascota)),
    );

    // Actualizamos por si el usuario quitó
    // la mascota de sus favoritos.
    if (mounted) {
      await _recargarFavoritos();
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
        title: const Text('Mis favoritos'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        scrolledUnderElevation: 0,
      ),

      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _recargarFavoritos,

        child: FutureBuilder<List<Mascota>>(
          future: _mascotasFuture,

          builder: (context, snapshot) {
            final cargando =
                snapshot.connectionState == ConnectionState.waiting;

            final mascotas = snapshot.data ?? [];

            final hayError = snapshot.hasError;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),

                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),

                  padding: const EdgeInsets.fromLTRB(20, 15, 20, 38),

                  children: [
                    // ENCABEZADO
                    const PageHeading(
                      eyebrow: 'TUS ELEGIDOS',
                      title: 'Los que te enamoraron.',
                      subtitle:
                          'Un lugar especial para guardar '
                          'a las mascotas que conquistaron '
                          'tu corazón.',
                    ),

                    const SizedBox(height: 26),

                    // BANNER DE FAVORITOS
                    _BannerFavoritos(
                          cantidad: mascotas.length,
                          cargando: cargando,
                          hayError: hayError,
                        )
                        .animate()
                        .fadeIn(duration: 450.ms)
                        .slideY(
                          begin: 0.05,
                          end: 0,
                          duration: 450.ms,
                          curve: Curves.easeOutCubic,
                        ),

                    const SizedBox(height: 32),

                    // TITULO DE LA SECCION
                    const SectionHeading(
                      title: 'Tu lista especial',
                      subtitle: 'Mascotas que te gustaría conocer mejor.',
                    ),

                    const SizedBox(height: 19),

                    // ==================================
                    // ESTADO DE CARGA
                    // ==================================
                    if (cargando)
                      const _FavoritosCargando()
                    // ==================================
                    // ESTADO DE ERROR
                    // ==================================
                    else if (hayError)
                      AppEmptyState(
                        icon: Icons.wifi_off_rounded,
                        title: 'No pudimos cargar tus favoritos',
                        message:
                            'Parece que hubo un problema '
                            'de conexión. Intentá nuevamente '
                            'para ver tus mascotas favoritas.',
                        actionLabel: 'Reintentar',
                        onAction: _recargarFavoritos,
                      )
                    // ==================================
                    // ESTADO VACIO
                    // ==================================
                    else if (mascotas.isEmpty)
                      const _FavoritosVacios()
                    // ==================================
                    // MOSTRAR FAVORITOS
                    // ==================================
                    else ...[
                      for (final mascota in mascotas)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),

                          child: PetCard(
                            mascota: mascota,
                            onTap: () {
                              _abrirDetalle(mascota);
                            },
                          ),
                        ),

                      const SizedBox(height: 8),

                      const _MensajeFavoritos(),
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
// BANNER SUPERIOR DE FAVORITOS
// ==========================================

class _BannerFavoritos extends StatelessWidget {
  final int cantidad;
  final bool cargando;
  final bool hayError;

  const _BannerFavoritos({
    required this.cantidad,
    required this.cargando,
    required this.hayError,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF71C9F5), Color(0xFF398FD5), Color(0xFF2069B6)],
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

      child: ClipRRect(
        borderRadius: BorderRadius.circular(29),

        child: Stack(
          children: [
            // CIRCULO DECORATIVO SUPERIOR
            Positioned(
              right: -50,
              top: -65,
              child: Container(
                width: 175,
                height: 175,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x24FFFFFF),
                ),
              ),
            ),

            // CIRCULO DECORATIVO INFERIOR
            Positioned(
              right: 32,
              bottom: -100,
              child: Container(
                width: 185,
                height: 185,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x16FFFFFF),
                ),
              ),
            ),

            // CORAZON DE FONDO
            const Positioned(
              right: -12,
              bottom: -20,
              child: Icon(
                Icons.favorite_rounded,
                size: 155,
                color: Color(0x18FFFFFF),
              ),
            ),

            // CONTENIDO PRINCIPAL
            Padding(
              padding: const EdgeInsets.all(23),

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
                          'TU RINCÓN ESPECIAL',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // INFORMACION Y CONTADOR
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pequeños amores,\ngrandes conexiones.',
                              style: GoogleFonts.quicksand(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                                letterSpacing: -0.6,
                              ),
                            ),

                            const SizedBox(height: 10),

                            const Text(
                              'Cada favorito puede ser '
                              'el comienzo de una historia.',
                              style: TextStyle(
                                color: Color(0xFFF0FAFF),
                                fontSize: 12,
                                height: 1.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 13),

                      // CONTADOR
                      Container(
                        width: 77,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 13,
                        ),

                        decoration: BoxDecoration(
                          color: const Color(0x35FFFFFF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0x35FFFFFF)),
                        ),

                        child: Column(
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),

                              child: Text(
                                cargando || hayError ? '—' : '$cantidad',
                                key: ValueKey(
                                  cargando || hayError ? 'sin-datos' : cantidad,
                                ),
                                style: GoogleFonts.quicksand(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),

                            const Text(
                              'FAVORITOS',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
// ESTADO DE CARGA CON SKELETONIZER
// ==========================================

class _FavoritosCargando extends StatelessWidget {
  const _FavoritosCargando();

  @override
  Widget build(BuildContext context) {
    return const Skeletonizer(
      enabled: true,

      child: Column(
        children: [
          _TarjetaFavoritoCargando(),
          SizedBox(height: 16),
          _TarjetaFavoritoCargando(),
        ],
      ),
    );
  }
}

// ==========================================
// TARJETA TEMPORAL DE CARGA
// ==========================================

class _TarjetaFavoritoCargando extends StatelessWidget {
  const _TarjetaFavoritoCargando();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: AppColors.border),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FOTOGRAFIA TEMPORAL
          const Skeleton.leaf(
            child: SizedBox(
              width: double.infinity,
              height: 195,

              child: ColoredBox(color: AppColors.azulPastel),
            ),
          ),

          // INFORMACION TEMPORAL
          Padding(
            padding: const EdgeInsets.all(19),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nombre de mascota',
                  style: GoogleFonts.quicksand(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Especie y raza de la mascota',
                  style: TextStyle(fontSize: 13),
                ),

                const SizedBox(height: 18),

                const Wrap(
                  spacing: 16,
                  runSpacing: 10,
                  children: [Text('Edad'), Text('Tamaño'), Text('Sexo')],
                ),

                const SizedBox(height: 18),

                const Text(
                  'Conoceme mejor',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
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
// ESTADO SIN FAVORITOS
// ==========================================

class _FavoritosVacios extends StatelessWidget {
  const _FavoritosVacios();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppEmptyState(
          icon: Icons.favorite_border_rounded,
          title: 'Todavía no hay favoritos',
          message:
              'Cuando una mascota te robe el corazón, '
              'tocá el ícono de corazón para guardarla acá.',
        ),

        const SizedBox(height: 8),

        Container(
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
                  'Explorá el catálogo y guardá '
                  'las mascotas que más te gusten.',
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
        ),
      ],
    );
  }
}

// ==========================================
// MENSAJE INFERIOR
// ==========================================

class _MensajeFavoritos extends StatelessWidget {
  const _MensajeFavoritos();

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
              'No hay nada más lindo que encontrar '
              'a alguien a quien darle un hogar.',
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
