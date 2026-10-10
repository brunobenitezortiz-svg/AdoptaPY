import 'package:flutter/material.dart';

import '../../models/mascota.dart';
import '../../services/mascota_service.dart';
import 'detalle_mascota_screen.dart';

class MascotasScreen extends StatefulWidget {
  const MascotasScreen({super.key});

  @override
  State<MascotasScreen> createState() => _MascotasScreenState();
}

class _MascotasScreenState extends State<MascotasScreen> {
  late Future<List<Mascota>> _mascotasFuture;

  @override
  void initState() {
    super.initState();
    _cargarMascotas();
  }

  void _cargarMascotas() {
    _mascotasFuture = MascotaService().obtenerMascotas();
  }

  Future<void> _recargarMascotas() async {
    setState(() {
      _cargarMascotas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mascotas disponibles'),
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

          final mascotas = (snapshot.data ?? [])
              .where((mascota) => mascota.estado == 'disponible')
              .toList();

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
                      'No hay mascotas disponibles en este momento.',
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

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 200,
                        width: double.infinity,
                        child: mascota.imagenUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius:
                                    const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: Image.network(
                                  mascota.imagenUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(
                                        Icons.pets,
                                        size: 80,
                                      ),
                                    );
                                  },
                                ),
                              )
                            : const Center(
                                child: Icon(
                                  Icons.pets,
                                  size: 80,
                                ),
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              mascota.nombre,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${mascota.especie} · ${mascota.raza}',
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${mascota.edad} · ${mascota.sexo} · ${mascota.tamano}',
                              style: const TextStyle(
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              mascota.descripcion,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DetalleMascotaScreen(
                                        mascota: mascota,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Ver detalles',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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