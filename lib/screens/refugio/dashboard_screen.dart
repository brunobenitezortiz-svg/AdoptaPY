import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/adopta_widgets.dart';

import '../auth/login_screen.dart';
import '../solicitudes_refugio_screen.dart';
import 'mascotas_screen.dart';
import 'publicar_mascota_screen.dart';

// ==========================================
// PANEL PRINCIPAL DEL REFUGIO
// ==========================================

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _cerrandoSesion = false;

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
        scrolledUnderElevation: 0,
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

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),

            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),

              padding: const EdgeInsets.fromLTRB(20, 17, 20, 42),

              children: [
                // ==================================
                // ENCABEZADO PRINCIPAL
                // ==================================

                const PageHeading(
                  eyebrow: 'PANEL DEL REFUGIO',
                  title: 'Cada rescate merece una oportunidad.',
                  subtitle:
                      'Gestioná tus publicaciones, '
                      'conocé a los adoptantes '
                      'y ayudá a encontrar nuevos hogares.',
                ),

                const SizedBox(height: 27),

                // ==================================
                // BANNER DE PUBLICACION
                // ==================================
                _BannerRefugio(
                      onPublicar: () {
                        _abrir(const PublicarMascotaScreen());
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

                const SizedBox(height: 34),

                // ==================================
                // HERRAMIENTAS DEL REFUGIO
                // ==================================
                const SectionHeading(
                  title: 'Tu espacio de gestión',
                  subtitle:
                      'Todo lo que necesitás para '
                      'administrar tu refugio.',
                ),

                const SizedBox(height: 18),

                // MIS PUBLICACIONES
                ActionTile(
                  icon: Icons.pets_rounded,
                  tint: AppColors.primary,
                  title: 'Mis publicaciones',
                  subtitle:
                      'Administrá, editá y renová '
                      'las publicaciones de mascotas.',
                  onTap: () {
                    _abrir(const MascotasScreen());
                  },
                ),

                const SizedBox(height: 13),

                // SOLICITUDES RECIBIDAS
                ActionTile(
                  icon: Icons.assignment_turned_in_outlined,
                  tint: const Color(0xFF329DD5),
                  title: 'Solicitudes recibidas',
                  subtitle:
                      'Revisá las solicitudes '
                      'y respondé a los adoptantes.',
                  onTap: () {
                    _abrir(const SolicitudesRefugioScreen());
                  },
                ),

                const SizedBox(height: 33),

                // ==================================
                // CONSEJO PARA EL REFUGIO
                // ==================================
                const SectionHeading(
                  title: 'Un pequeño consejo',
                  subtitle: 'Hacé que cada publicación destaque.',
                ),

                const SizedBox(height: 17),

                const _ConsejoRefugio(),

                const SizedBox(height: 28),

                // ==================================
                // MENSAJE FINAL
                // ==================================
                const _MensajeRefugio(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// BANNER PRINCIPAL DEL REFUGIO
// ==========================================

class _BannerRefugio extends StatelessWidget {
  final VoidCallback onPublicar;

  const _BannerRefugio({required this.onPublicar});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF70C9F5), Color(0xFF378FD5), Color(0xFF1C64B1)],
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
              top: -70,
              child: Container(
                width: 215,
                height: 215,
                decoration: const BoxDecoration(
                  color: Color(0x20FFFFFF),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // CIRCULO DECORATIVO INFERIOR
            Positioned(
              right: 25,
              bottom: -100,
              child: Container(
                width: 190,
                height: 190,
                decoration: const BoxDecoration(
                  color: Color(0x16FFFFFF),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // HUELLA DECORATIVA
            const Positioned(
              right: -12,
              bottom: 3,
              child: IgnorePointer(
                child: Icon(
                  Icons.pets_rounded,
                  size: 145,
                  color: Color(0x27FFFFFF),
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
                          Icons.volunteer_activism_rounded,
                          color: Colors.white,
                          size: 15,
                        ),

                        SizedBox(width: 7),

                        Text(
                          'CADA HOGAR CUENTA',
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

                  // TITULO PRINCIPAL
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 290),

                    child: Text(
                      'Ayudá a una mascota a encontrar su familia.',
                      style: GoogleFonts.quicksand(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.18,
                        letterSpacing: -0.7,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // DESCRIPCION
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 265),

                    child: const Text(
                      'Compartí su historia '
                      'y conectá con personas '
                      'que quieren adoptar.',
                      style: TextStyle(
                        color: Color(0xFFF0FAFF),
                        fontSize: 13,
                        height: 1.55,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 23),

                  // BOTON PARA PUBLICAR
                  FilledButton.icon(
                    onPressed: onPublicar,

                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      minimumSize: const Size(0, 49),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 19,
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),

                    icon: const Icon(
                      Icons.add_circle_outline_rounded,
                      size: 20,
                    ),

                    label: const Text(
                      'Publicar mascota',
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
// TARJETA DE CONSEJO
// ==========================================

class _ConsejoRefugio extends StatelessWidget {
  const _ConsejoRefugio();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: AppColors.border),

        boxShadow: const [
          BoxShadow(
            color: Color(0x0B164E86),
            blurRadius: 17,
            offset: Offset(0, 5),
          ),
        ],
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ICONO
          Container(
            width: 48,
            height: 48,

            decoration: BoxDecoration(
              color: AppColors.azulPastel,
              borderRadius: BorderRadius.circular(16),
            ),

            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: AppColors.primary,
              size: 25,
            ),
          ),

          const SizedBox(width: 15),

          // CONTENIDO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Una buena historia marca la diferencia',
                  style: GoogleFonts.quicksand(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 9),

                const Text(
                  'Una fotografía clara y una descripción '
                  'detallada ayudan a que los adoptantes '
                  'conozcan mejor a cada mascota.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    height: 1.55,
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
// MENSAJE INFERIOR
// ==========================================

class _MensajeRefugio extends StatelessWidget {
  const _MensajeRefugio();

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
          Icon(Icons.favorite_rounded, color: AppColors.primary, size: 23),

          SizedBox(width: 13),

          Expanded(
            child: Text(
              'Gracias por ser parte de cada '
              'historia de rescate y adopción. '
              'Tu trabajo hace la diferencia.',
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
