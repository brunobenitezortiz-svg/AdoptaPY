import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

import 'favoritos_screen.dart';
import 'mascotas_screen.dart';
import '../mis_solicitudes_screen.dart';

class HomeScreen extends StatelessWidget {
const HomeScreen({super.key});

Future<void> _cerrarSesion(BuildContext context) async {
await AuthService().cerrarSesion();

if (!context.mounted) return;

Navigator.popUntil(
  context,
  (route) => route.isFirst,
);

}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('Adopta Mascotas'),
actions: [
IconButton(
onPressed: () => _cerrarSesion(context),
icon: const Icon(Icons.logout),
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
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MascotasScreen(),
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
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FavoritosScreen(),
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
          onPressed: () {
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
