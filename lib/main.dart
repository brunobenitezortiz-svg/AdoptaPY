import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'theme/app_theme.dart';

// ==========================================
// INICIALIZACION DE LA APLICACION
// ==========================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const AdoptaMascotasApp());
}

// ==========================================
// APLICACION PRINCIPAL
// ==========================================

class AdoptaMascotasApp extends StatelessWidget {
  const AdoptaMascotasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AdoptaPY',
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      home: const PantallaInicial(),
    );
  }
}

// ==========================================
// VERIFICACION DE BIENVENIDA
// ==========================================

class PantallaInicial extends StatefulWidget {
  const PantallaInicial({super.key});

  @override
  State<PantallaInicial> createState() => _PantallaInicialState();
}

class _PantallaInicialState extends State<PantallaInicial> {
  bool? _bienvenidaVista;

  @override
  void initState() {
    super.initState();
    _verificarBienvenida();
  }

  Future<void> _verificarBienvenida() async {
    try {
      final preferencias = await SharedPreferences.getInstance();

      final vista = preferencias.getBool('bienvenida_vista') ?? false;

      if (!mounted) return;

      setState(() {
        _bienvenidaVista = vista;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _bienvenidaVista = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_bienvenidaVista == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_bienvenidaVista!) {
      return const LoginScreen();
    }

    return const InicioScreen();
  }
}

// ==========================================
// PANTALLA DE BIENVENIDA
// ==========================================

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  bool _continuando = false;

  Future<void> _comenzar() async {
    if (_continuando) return;

    setState(() {
      _continuando = true;
    });

    try {
      final preferencias = await SharedPreferences.getInstance();

      await preferencias.setBool('bienvenida_vista', true);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo guardar la preferencia. '
            'Intentá nuevamente.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _continuando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF7FF), AppColors.background, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // LOGOTIPO
                    const _MarcaAdopta()
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: -0.1, end: 0, duration: 500.ms),

                    const SizedBox(height: 28),

                    // TARJETA PRINCIPAL
                    const _HeroBienvenida()
                        .animate()
                        .fadeIn(duration: 550.ms)
                        .slideY(begin: 0.08, end: 0, duration: 550.ms),

                    const SizedBox(height: 28),

                    // TITULO PRINCIPAL
                    Text(
                      'Un amor de cuatro patas '
                      'te está esperando.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.quicksand(
                        fontSize: 29,
                        fontWeight: FontWeight.w800,
                        height: 1.16,
                        letterSpacing: -0.8,
                        color: AppColors.ink,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // DESCRIPCION
                    const Text(
                      'Encontrá a tu compañero ideal '
                      'y regalale la oportunidad de '
                      'tener un hogar lleno de amor.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                        color: AppColors.muted,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // TITULO DE OPCIONES
                    const _TituloSeccion(),

                    const SizedBox(height: 16),

                    // TARJETA ADOPTANTE
                    const _TarjetaBienvenida(
                          icono: Icons.favorite_rounded,
                          titulo: 'Quiero adoptar',
                          descripcion:
                              'Conocé mascotas, guardá '
                              'tus favoritas y encontrá '
                              'a tu nuevo mejor amigo.',
                          fondoIcono: Color(0xFFE5F3FF),
                          colorIcono: AppColors.primary,
                        )
                        .animate()
                        .fadeIn(delay: 150.ms, duration: 450.ms)
                        .slideY(begin: 0.06, end: 0),

                    const SizedBox(height: 12),

                    // TARJETA REFUGIO
                    const _TarjetaBienvenida(
                          icono: Icons.home_rounded,
                          titulo: 'Soy un refugio',
                          descripcion:
                              'Publicá mascotas, gestioná '
                              'solicitudes y ayudalas '
                              'a encontrar una familia.',
                          fondoIcono: Color(0xFFDDF7FF),
                          colorIcono: Color(0xFF168CB8),
                        )
                        .animate()
                        .fadeIn(delay: 250.ms, duration: 450.ms)
                        .slideY(begin: 0.06, end: 0),

                    const SizedBox(height: 24),

                    // BOTON COMENZAR
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: FilledButton(
                        onPressed: _continuando ? null : _comenzar,
                        child: _continuando
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Comenzar'),
                                  SizedBox(width: 10),
                                  Icon(Icons.arrow_forward_rounded, size: 21),
                                ],
                              ),
                      ),
                    ).animate().fadeIn(delay: 350.ms, duration: 450.ms),

                    const SizedBox(height: 16),

                    // MENSAJE INFERIOR
                    const Text(
                      'Creá una cuenta o iniciá sesión '
                      'para comenzar tu experiencia.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// LOGOTIPO ADOPTAPY
// ==========================================

class _MarcaAdopta extends StatelessWidget {
  const _MarcaAdopta();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 49,
          height: 49,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.celeste, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(17),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2856B8F2),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.pets_rounded, color: Colors.white, size: 27),
        ),

        const SizedBox(width: 12),

        Text.rich(
          TextSpan(
            children: const [
              TextSpan(
                text: 'Adopta',
                style: TextStyle(color: AppColors.ink),
              ),
              TextSpan(
                text: 'PY',
                style: TextStyle(color: AppColors.primary),
              ),
            ],
          ),
          style: GoogleFonts.quicksand(
            fontSize: 27,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
      ],
    );
  }
}

// ==========================================
// TARJETA PRINCIPAL ILUSTRADA
// ==========================================

class _HeroBienvenida extends StatelessWidget {
  const _HeroBienvenida();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 218,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF65C7F7), Color(0xFF318ED7), Color(0xFF2169BA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3056B8F2),
            blurRadius: 25,
            offset: Offset(0, 12),
          ),
        ],
      ),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            // CIRCULO DECORATIVO SUPERIOR
            Positioned(
              top: -65,
              right: -45,
              child: Container(
                width: 195,
                height: 195,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x20FFFFFF),
                ),
              ),
            ),

            // CIRCULO DECORATIVO INFERIOR
            Positioned(
              bottom: -85,
              right: 42,
              child: Container(
                width: 175,
                height: 175,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x15FFFFFF),
                ),
              ),
            ),

            // HUELLA DECORATIVA
            const Positioned(
              bottom: 10,
              right: 8,
              child: Icon(
                Icons.pets_rounded,
                size: 132,
                color: Color(0x32FFFFFF),
              ),
            ),

            // CONTENIDO PRINCIPAL
            Padding(
              padding: const EdgeInsets.all(26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x33FFFFFF),
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
                          'CADA HUELLITA IMPORTA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pequeñas patitas,\n'
                        'grandes historias.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          height: 1.16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),

                      SizedBox(height: 9),

                      Text(
                        'Un hogar lo cambia todo.',
                        style: TextStyle(
                          color: Color(0xFFF0FAFF),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
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
// TITULO DE SECCION
// ==========================================

class _TituloSeccion extends StatelessWidget {
  const _TituloSeccion();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 19),

        SizedBox(width: 9),

        Expanded(
          child: Text(
            '¿Cómo querés comenzar?',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// TARJETAS INFORMATIVAS
// ==========================================

class _TarjetaBienvenida extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String descripcion;
  final Color fondoIcono;
  final Color colorIcono;

  const _TarjetaBienvenida({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.fondoIcono,
    required this.colorIcono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B164E86),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ICONO
          Container(
            width: 49,
            height: 49,
            decoration: BoxDecoration(
              color: fondoIcono,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icono, color: colorIcono, size: 25),
          ),

          const SizedBox(width: 15),

          // CONTENIDO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  descripcion,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
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
