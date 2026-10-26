
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const AdoptaMascotasApp());
}

class AdoptaMascotasApp extends StatelessWidget {
  const AdoptaMascotasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Adopta Mascotas',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
        ),
        useMaterial3: true,
      ),
      home: const PantallaInicial(),
    );
  }
}

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

      // Si no se pueden leer las preferencias,
      // mostramos la bienvenida normalmente.
      setState(() {
        _bienvenidaVista = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_bienvenidaVista == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_bienvenidaVista!) {
      return const LoginScreen();
    }

    return const InicioScreen();
  }
}

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
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo guardar la preferencia. Intentá nuevamente.',
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
    final colores = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 480,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                      color: colores.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.pets,
                      size: 76,
                      color: colores.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '¡Bienvenido a Adopta Mascotas!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colores.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Conectamos mascotas que necesitan un hogar '
                    'con personas dispuestas a brindarles amor y cuidado.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const _TarjetaBienvenida(
                    icono: Icons.favorite_outline,
                    titulo: '¿Querés adoptar?',
                    descripcion:
                        'Explorá mascotas disponibles, guardá tus '
                        'favoritas y enviá solicitudes de adopción '
                        'a los refugios.',
                  ),
                  const SizedBox(height: 14),
                  const _TarjetaBienvenida(
                    icono: Icons.home_outlined,
                    titulo: '¿Representás a un refugio?',
                    descripcion:
                        'Publicá mascotas en adopción, administrá '
                        'tus publicaciones y respondé las '
                        'solicitudes de los adoptantes.',
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colores.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: colores.primary,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Para utilizar Adopta Mascotas necesitás '
                            'tener una cuenta. Podés iniciar sesión '
                            'o registrarte como adoptante o refugio.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _continuando ? null : _comenzar,
                      icon: _continuando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.arrow_forward),
                      label: Text(
                        _continuando ? 'Cargando...' : 'Comenzar',
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 17,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TarjetaBienvenida extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String descripcion;

  const _TarjetaBienvenida({
    required this.icono,
    required this.titulo,
    required this.descripcion,
  });

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colores.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: colores.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colores.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icono,
                color: colores.onPrimaryContainer,
                size: 27,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    descripcion,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
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
