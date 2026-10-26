
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/mascota.dart';
import '../../services/auth_service.dart';
import '../../services/mascota_service.dart';
import 'publicar_mascota_screen.dart';

class MascotasScreen extends StatefulWidget {
  const MascotasScreen({super.key});

  @override
  State<MascotasScreen> createState() => _MascotasScreenState();
}

class _MascotasScreenState extends State<MascotasScreen> {
  late Future<List<Mascota>> _mascotasFuture;

  final Set<String> _renovandoMascotas = {};

  @override
  void initState() {
    super.initState();
    _cargarMascotas();
  }

  void _cargarMascotas() {
    final usuario = AuthService().usuarioActual;

    if (usuario == null) {
      _mascotasFuture = Future.value([]);
      return;
    }

    _mascotasFuture = MascotaService().obtenerMascotasDelRefugio(
      usuario.uid,
    );
  }

  Future<void> _recargarMascotas() async {
    setState(() {
      _cargarMascotas();
    });

    await _mascotasFuture;
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) {
      return 'No disponible';
    }

    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString();

    return '$dia/$mes/$anio';
  }

  Future<void> _renovarMascota(Mascota mascota) async {
    if (mascota.estado != 'disponible' || !mascota.estaVencida) {
      return;
    }

    if (_renovandoMascotas.contains(mascota.id)) {
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Renovar publicación'),
          content: Text(
            '¿Querés renovar la publicación de ${mascota.nombre} '
            'por otros 7 días?\n\n'
            'La fecha original de publicación se conservará.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Renovar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true || !mounted) {
      return;
    }

    setState(() {
      _renovandoMascotas.add(mascota.id);
    });

    try {
      final nuevaFecha = DateTime.now().add(
        const Duration(days: 7),
      );

      await FirebaseFirestore.instance
          .collection('mascotas')
          .doc(mascota.id)
          .update({
        'fechaVencimiento': Timestamp.fromDate(nuevaFecha),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'La publicación de ${mascota.nombre} '
            'se renovó por 7 días.',
          ),
        ),
      );

      await _recargarMascotas();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo renovar la publicación. '
            'Intentá nuevamente.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _renovandoMascotas.remove(mascota.id);
        });
      }
    }
  }

  Future<void> _eliminarMascota(Mascota mascota) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar mascota'),
          content: Text(
            '¿Querés eliminar a ${mascota.nombre}?\n\n'
            'Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    try {
      await MascotaService().eliminarMascota(mascota.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${mascota.nombre} fue eliminada correctamente.',
          ),
        ),
      );

      await _recargarMascotas();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo eliminar la mascota.',
          ),
        ),
      );
    }
  }

  Future<void> _editarMascota(Mascota mascota) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PublicarMascotaScreen(
          mascota: mascota,
        ),
      ),
    );

    if (!mounted) return;

    await _recargarMascotas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis mascotas'),
      ),
      body: FutureBuilder<List<Mascota>>(
        future: _mascotasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No se pudieron cargar las mascotas.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _recargarMascotas,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final mascotas = snapshot.data ?? [];

          if (mascotas.isEmpty) {
            return RefreshIndicator(
              onRefresh: _recargarMascotas,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 150),
                  Icon(
                    Icons.pets_outlined,
                    size: 80,
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Todavía no publicaste ninguna mascota.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _recargarMascotas,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: mascotas.length,
              itemBuilder: (context, index) {
                final mascota = mascotas[index];

                final vencida = mascota.estaVencida;
                final disponible = mascota.estado == 'disponible';
                final puedeRenovar = disponible && vencida;

                final renovando = _renovandoMascotas.contains(
                  mascota.id,
                );

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                              ),
                              child: mascota.imagenUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      child: Image.network(
                                        mascota.imagenUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return const Icon(
                                            Icons.pets,
                                            size: 40,
                                          );
                                        },
                                      ),
                                    )
                                  : const Icon(
                                      Icons.pets,
                                      size: 40,
                                    ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          mascota.nombre,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          _editarMascota(mascota);
                                        },
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                        ),
                                        tooltip: 'Editar mascota',
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          _eliminarMascota(mascota);
                                        },
                                        icon: const Icon(
                                          Icons.delete_outline,
                                        ),
                                        tooltip: 'Eliminar mascota',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${mascota.especie} · ${mascota.raza}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${mascota.edad} · ${mascota.sexo} · ${mascota.tamano}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Chip(
                                    label: Text(
                                      disponible && vencida
                                          ? 'Publicación vencida'
                                          : mascota.estado,
                                    ),
                                    avatar: Icon(
                                      Icons.circle,
                                      size: 10,
                                      color: disponible && vencida
                                          ? Colors.orange
                                          : disponible
                                              ? Colors.green
                                              : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 17,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Publicado: ${_formatearFecha(mascota.fechaPublicacion)}',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              vencida
                                  ? Icons.event_busy_outlined
                                  : Icons.event_available_outlined,
                              size: 17,
                              color: vencida
                                  ? Colors.orange
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Vencimiento: ${_formatearFecha(mascota.vencimiento)}',
                              ),
                            ),
                          ],
                        ),
                        if (puedeRenovar) ...[
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: renovando
                                  ? null
                                  : () {
                                      _renovarMascota(mascota);
                                    },
                              icon: renovando
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.refresh),
                              label: Text(
                                renovando
                                    ? 'Renovando...'
                                    : 'Renovar por 7 días',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
