
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

import 'favoritos_screen.dart';
import 'mascotas_screen.dart';
import '../mis_solicitudes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _cerrandoSesion = false;

  Future<void> _cerrarSesion() async {
    if (_cerrandoSesion) return;

    setState(() {
      _cerrandoSesion = true;
    });

    try {
      await AuthService().cerrarSesion();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo cerrar sesión. Intentá nuevamente.',
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adopta Mascotas'),
        actions: [
          IconButton(
            onPressed: _cerrandoSesion ? null : _cerrarSesion,
            icon: _cerrandoSesion
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),
            const Icon(
              Icons.pets,
              size: 90,
            ),
            const SizedBox(height: 20),
            const Text(
              '¡Bienvenido!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Encontrá un compañero que necesita un hogar.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 40),

            // Ver mascotas disponibles
            ElevatedButton.icon(
              onPressed: _cerrandoSesion
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const MascotasScreen(),
                        ),
                      );
                    },
              icon: const Icon(Icons.search),
              label: const Text('Ver mascotas disponibles'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Mis favoritos
            OutlinedButton.icon(
              onPressed: _cerrandoSesion
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const FavoritosScreen(),
                        ),
                      );
                    },
              icon: const Icon(Icons.favorite),
              label: const Text('Mis favoritos'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Mis solicitudes
            OutlinedButton.icon(
              onPressed: _cerrandoSesion
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const MisSolicitudesScreen(),
                        ),
                      );
                    },
              icon: const Icon(Icons.assignment_outlined),
              label: const Text('Mis solicitudes'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
