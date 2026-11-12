import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../models/mascota.dart';
import '../../services/auth_service.dart';
import '../../services/mascota_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/adopta_widgets.dart';

import '../auth/login_screen.dart';
import '../mis_solicitudes_screen.dart';
import 'detalle_mascota_screen.dart';
import 'favoritos_screen.dart';
import 'mascotas_screen.dart';

// ==========================================
// PANTALLA PRINCIPAL DEL ADOPTANTE
// ==========================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _cerrandoSesion = false;

  late Future<List<Mascota>> _mascotasFuture;

  @override
  void initState() {
    super.initState();

    _mascotasFuture = MascotaService().obtenerMascotas();
  }

  // ========================================
  // ACTUALIZAR MASCOTAS
  // ========================================

  Future<void> _actualizarMascotas() async {
    final nuevaConsulta = MascotaService().obtenerMascotas();

    setState(() {
      _mascotasFuture = nuevaConsulta;
    });

    try {
      await nuevaConsulta;
    } catch (_) {
      // FutureBuilder mostrará el estado de error.
    }
  }

  // ========================================
  // CERRAR SESION
  // ========================================

  Future<void> _cerrarSesion() async {
    if (_cerrandoSesion) return;

    setState(() {
      _cerrandoSesion = true;
    });

    try {
      await AuthService().cerrarSesion();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cerrar sesión. Intentá nuevamente.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _cerrandoSesion = false;
        });
      }
    }
  }

  // ========================================
  // NAVEGACION
  // ========================================

  void _abrir(Widget screen) {
    if (_cerrandoSesion) return;

    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  // ========================================
  // INTERFAZ PRINCIPAL
  // ========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        toolbarHeight: 70,

        title: const BrandLogo(compact: true),

        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _cerrandoSesion ? null : _cerrarSesion,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.azulSuave,
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.all(11),
            ),
            icon: _cerrandoSesion
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout_rounded, size: 22),
          ),

          const SizedBox(width: 17),
        ],
      ),

      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _actualizarMascotas,

        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 42),

          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // SALUDO
                    const _SaludoAdoptante(),

                    const SizedBox(height: 25),

                    // BANNER PRINCIPAL
                    _BannerPrincipal(
                          onExplorar: () {
                            _abrir(const MascotasScreen());
                          },
                        )
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideY(
                          begin: 0.06,
                          end: 0,
                          duration: 500.ms,
                          curve: Curves.easeOutCubic,
                        ),

                    const SizedBox(height: 33),

                    // SECCION DE ACCESOS
                    const SectionHeading(
                      title: 'Tu espacio',
                      subtitle: 'Todo lo que necesitás, a un toque.',
                    ),

                    const SizedBox(height: 17),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _AccesoRapido(
                            icono: Icons.favorite_rounded,
                            titulo: 'Mis favoritos',
                            descripcion: 'Tus mascotas favoritas',
                            color: const Color(0xFF4796D5),
                            onTap: () {
                              _abrir(const FavoritosScreen());
                            },
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: _AccesoRapido(
                            icono: Icons.mark_email_read_outlined,
                            titulo: 'Mis solicitudes',
                            descripcion: 'Seguí tus adopciones',
                            color: AppColors.primary,
                            onTap: () {
                              _abrir(const MisSolicitudesScreen());
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 34),

                    // SECCION DE MASCOTAS
                    SectionHeading(
                      title: 'Conocé a tus futuros amigos',
                      subtitle: 'Hay corazones esperando por vos.',
                      trailing: TextButton(
                        onPressed: () {
                          _abrir(const MascotasScreen());
                        },
                        child: const Text('Ver todas'),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // MASCOTAS OBTENIDAS DE FIREBASE
                    FutureBuilder<List<Mascota>>(
                      future: _mascotasFuture,

                      builder: (context, snapshot) {
                        // ESTADO DE CARGA
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const _MascotasCargando();
                        }

                        // ESTADO DE ERROR
                        if (snapshot.hasError) {
                          return AppEmptyState(
                            icon: Icons.cloud_off_rounded,
                            title: 'No pudimos cargar las mascotas',
                            message:
                                'Verificá tu conexión y volvé '
                                'a intentarlo.',
                            actionLabel: 'Reintentar',
                            onAction: () {
                              _actualizarMascotas();
                            },
                          );
                        }

                        // FILTRAR MASCOTAS DISPONIBLES
                        final mascotas = (snapshot.data ?? [])
                            .where((mascota) => mascota.disponibleParaAdopcion)
                            .take(3)
                            .toList();

                        // ESTADO VACIO
                        if (mascotas.isEmpty) {
                          return const AppEmptyState(
                            icon: Icons.pets_outlined,
                            title: 'Pronto habrá nuevos amigos',
                            message:
                                'Todavía no hay mascotas '
                                'disponibles. Volvé a visitar '
                                'esta sección próximamente.',
                          );
                        }

                        // MOSTRAR MASCOTAS
                        return Column(
                          children: [
                            for (final mascota in mascotas)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 15),
                                child: PetCard(
                                  mascota: mascota,
                                  onTap: () {
                                    _abrir(
                                      DetalleMascotaScreen(mascota: mascota),
                                    );
                                  },
                                ),
                              ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 18),

                    // MENSAJE FINAL
                    const _MensajeFinal(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// SALUDO DEL ADOPTANTE
// ==========================================

class _SaludoAdoptante extends StatelessWidget {
  const _SaludoAdoptante();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.azulPastel,
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.waving_hand_rounded,
                    color: AppColors.primary,
                    size: 15,
                  ),

                  SizedBox(width: 7),

                  Text(
                    'HOLA, QUÉ BUENO VERTE',
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Text(
          'Tu próximo gran amigo\nte está esperando.',
          style: GoogleFonts.quicksand(
            color: AppColors.ink,
            fontSize: 29,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.9,
            height: 1.18,
          ),
        ),

        const SizedBox(height: 10),

        const Text(
          'Descubrí nuevas historias y encontrá '
          'a quien va a llenar tu hogar de alegría.',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 14,
            height: 1.55,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ==========================================
// BANNER PRINCIPAL
// ==========================================

class _BannerPrincipal extends StatelessWidget {
  final VoidCallback onExplorar;

  const _BannerPrincipal({required this.onExplorar});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF70C9F5), Color(0xFF378ED5), Color(0xFF1C64B1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        borderRadius: BorderRadius.circular(30),

        boxShadow: const [
          BoxShadow(
            color: Color(0x2756B8F2),
            blurRadius: 25,
            offset: Offset(0, 11),
          ),
        ],
      ),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),

        child: Stack(
          children: [
            // CIRCULO DECORATIVO SUPERIOR
            Positioned(
              right: -65,
              top: -75,
              child: IgnorePointer(
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x22FFFFFF),
                  ),
                ),
              ),
            ),

            // CIRCULO DECORATIVO INFERIOR
            Positioned(
              right: 20,
              bottom: -100,
              child: IgnorePointer(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x16FFFFFF),
                  ),
                ),
              ),
            ),

            // HUELLA DECORATIVA
            const Positioned(
              right: -8,
              bottom: 4,
              child: IgnorePointer(
                child: Icon(
                  Icons.pets_rounded,
                  size: 154,
                  color: Color(0x2CFFFFFF),
                ),
              ),
            ),

            // CONTENIDO DEL BANNER
            Padding(
              padding: const EdgeInsets.all(24),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ETIQUETA SUPERIOR
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
                          'UN AMOR PARA TODA LA VIDA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // TITULO
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 275),
                    child: Text(
                      'Pequeñas patitas,\ngrandes historias.',
                      style: GoogleFonts.quicksand(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        height: 1.16,
                      ),
                    ),
                  ),

                  const SizedBox(height: 11),

                  // DESCRIPCION
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 245),
                    child: const Text(
                      'Conocé a las mascotas que '
                      'sueñan con encontrar un hogar.',
                      style: TextStyle(
                        color: Color(0xFFF0FAFF),
                        fontSize: 13,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 23),

                  // BOTON EXPLORAR
                  FilledButton.icon(
                    onPressed: onExplorar,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 19,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.search_rounded, size: 19),
                    label: const Text(
                      'Explorar mascotas',
                      style: TextStyle(
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
// ACCESOS RAPIDOS
// ==========================================

class _AccesoRapido extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String descripcion;
  final Color color;
  final VoidCallback onTap;

  const _AccesoRapido({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),

        boxShadow: const [
          BoxShadow(
            color: Color(0x0D164E86),
            blurRadius: 17,
            offset: Offset(0, 6),
          ),
        ],
      ),

      child: Material(
        color: Colors.transparent,

        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),

          child: Padding(
            padding: const EdgeInsets.all(15),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ICONO
                Container(
                  width: 49,
                  height: 49,

                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),

                  child: Icon(icono, color: color, size: 25),
                ),

                const SizedBox(height: 17),

                // TITULO
                Text(
                  titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.quicksand(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 6),

                // DESCRIPCION
                Text(
                  descripcion,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 16),

                // FLECHA
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.azulSuave,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
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

// ==========================================
// CARGA DE MASCOTAS CON SKELETONIZER
// ==========================================

class _MascotasCargando extends StatelessWidget {
  const _MascotasCargando();

  @override
  Widget build(BuildContext context) {
    return const Skeletonizer(
      enabled: true,
      child: Column(
        children: [
          _TarjetaMascotaCargando(),
          SizedBox(height: 15),
          _TarjetaMascotaCargando(),
        ],
      ),
    );
  }
}

// ==========================================
// TARJETA TEMPORAL PARA EL SKELETON
// ==========================================

class _TarjetaMascotaCargando extends StatelessWidget {
  const _TarjetaMascotaCargando();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: AppColors.border),
      ),

      clipBehavior: Clip.antiAlias,

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ESPACIO DE LA FOTOGRAFIA
          const Skeleton.leaf(
            child: SizedBox(
              width: double.infinity,
              height: 195,
              child: ColoredBox(color: AppColors.azulPastel),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(19),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nombre de la mascota',
                  style: GoogleFonts.quicksand(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 11),

                const Text(
                  'Especie y raza de la mascota',
                  style: TextStyle(fontSize: 13),
                ),

                const SizedBox(height: 17),

                const Row(
                  children: [
                    Text('Edad'),
                    SizedBox(width: 18),
                    Text('Tamaño'),
                    SizedBox(width: 18),
                    Text('Sexo'),
                  ],
                ),

                const SizedBox(height: 20),

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
// MENSAJE INFERIOR
// ==========================================

class _MensajeFinal extends StatelessWidget {
  const _MensajeFinal();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),

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
              'Cada adopción puede transformar '
              'dos vidas: la tuya y la de una mascota.',
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
