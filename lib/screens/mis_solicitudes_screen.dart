import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/solicitud.dart';
import '../models/mascota.dart';
import '../services/solicitud_service.dart';
import '../services/mascota_service.dart';

class MisSolicitudesScreen extends StatefulWidget {
const MisSolicitudesScreen({super.key});

@override
State<MisSolicitudesScreen> createState() =>
_MisSolicitudesScreenState();
}

class _MisSolicitudesScreenState extends State<MisSolicitudesScreen> {
final SolicitudService _solicitudService = SolicitudService();
final MascotaService _mascotaService = MascotaService();

late Future<List<Solicitud>> _futuroSolicitudes;

@override
void initState() {
super.initState();
_cargarSolicitudes();
}

void _cargarSolicitudes() {
final usuario = FirebaseAuth.instance.currentUser;

if (usuario == null) {
  _futuroSolicitudes = Future.value([]);
  return;
}

_futuroSolicitudes =
    _solicitudService.obtenerSolicitudesDelAdoptante(usuario.uid);

}

Future<void> _actualizar() async {
setState(() {
_cargarSolicitudes();
});

await _futuroSolicitudes;

}

Color _colorEstado(String estado) {
switch (estado.toLowerCase()) {
case 'aceptada':
return Colors.green;
case 'rechazada':
return Colors.red;
case 'cancelada':
return Colors.grey;
default:
return Colors.orange;
}
}

String _textoEstado(String estado) {
switch (estado.toLowerCase()) {
case 'aceptada':
return 'Aceptada';
case 'rechazada':
return 'Rechazada';
case 'cancelada':
return 'Cancelada';
default:
return 'Pendiente';
}
}

Future<void> _cancelarSolicitud(Solicitud solicitud) async {
final confirmar = await showDialog<bool>(
context: context,
builder: (contexto) => AlertDialog(
title: const Text('Cancelar solicitud'),
content: const Text(
'¿Estás seguro de que querés cancelar esta solicitud?',
),
actions: [
TextButton(
onPressed: () => Navigator.pop(contexto, false),
child: const Text('Volver'),
),
ElevatedButton(
onPressed: () => Navigator.pop(contexto, true),
child: const Text('Cancelar solicitud'),
),
],
),
);

if (confirmar != true || !mounted) return;

try {
  await _solicitudService.cancelarSolicitud(solicitud.id);

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Solicitud cancelada correctamente.'),
    ),
  );

  await _actualizar();
} catch (e) {
  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('No se pudo cancelar la solicitud.'),
    ),
  );
}

}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('Mis solicitudes'),
),
body: RefreshIndicator(
onRefresh: _actualizar,
child: FutureBuilder<List<Solicitud>>(
future: _futuroSolicitudes,
builder: (contexto, snapshot) {
if (snapshot.connectionState == ConnectionState.waiting) {
return const Center(
child: CircularProgressIndicator(),
);
}

        if (snapshot.hasError) {
          return ListView(
            children: const [
              SizedBox(height: 150),
              Center(
                child: Text(
                  'No se pudieron cargar las solicitudes.',
                ),
              ),
            ],
          );
        }

        final solicitudes = snapshot.data ?? [];

        solicitudes.sort((a, b) {
          final fechaA = a.fechaSolicitud;
          final fechaB = b.fechaSolicitud;

          if (fechaA == null && fechaB == null) return 0;
          if (fechaA == null) return 1;
          if (fechaB == null) return -1;

          return fechaB.compareTo(fechaA);
        });

        if (solicitudes.isEmpty) {
          return ListView(
            children: const [
              SizedBox(height: 150),
              Icon(
                Icons.assignment_outlined,
                size: 70,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Center(
                child: Text(
                  'Todavía no enviaste solicitudes de adopción.',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: solicitudes.length,
          itemBuilder: (contexto, indice) {
            final solicitud = solicitudes[indice];

            return FutureBuilder<Mascota?>(
              future: _mascotaService.obtenerMascotaPorId(
                solicitud.mascotaId,
              ),
              builder: (contexto, mascotaSnapshot) {
                final mascota = mascotaSnapshot.data;

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mascotaSnapshot.connectionState ==
                                  ConnectionState.waiting
                              ? 'Cargando mascota...'
                              : mascota?.nombre ?? 'Mascota no disponible',
                          style: Theme.of(contexto)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Text('Estado: '),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: _colorEstado(solicitud.estado)
                                    .withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: Text(
                                _textoEstado(solicitud.estado),
                                style: TextStyle(
                                  color: _colorEstado(solicitud.estado),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Tu mensaje al refugio:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          solicitud.mensaje.isEmpty
                              ? 'Sin mensaje'
                              : solicitud.mensaje,
                        ),
                        if (solicitud.estado == 'pendiente') ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () =>
                                  _cancelarSolicitud(solicitud),
                              icon: const Icon(Icons.cancel_outlined),
                              label: const Text('Cancelar solicitud'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    ),
  ),
);

}
}
