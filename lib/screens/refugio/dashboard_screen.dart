
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

import 'publicar_mascota_screen.dart';
import 'mascotas_screen.dart';
import '../solicitudes_refugio_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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
        title: const Text('Panel del Refugio'),
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
              Icons.home_work_outlined,
              size: 90,
            ),
            const SizedBox(height: 20),
            const Text(
              'Panel del Refugio',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Administrá las mascotas disponibles para adopción.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 40),

            // Publicar mascota
            ElevatedButton.icon(
              onPressed: _cerrandoSesion
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const PublicarMascotaScreen(),
                        ),
                      );
                    },
              icon: const Icon(Icons.add),
              label: const Text('Publicar mascota'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Ver mis mascotas
            OutlinedButton.icon(
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
              icon: const Icon(Icons.pets),
              label: const Text('Ver mis mascotas'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Solicitudes recibidas
            OutlinedButton.icon(
              onPressed: _cerrandoSesion
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const SolicitudesRefugioScreen(),
                        ),
                      );
                    },
              icon: const Icon(Icons.assignment_outlined),
              label: const Text('Solicitudes recibidas'),
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
