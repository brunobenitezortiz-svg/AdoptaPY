import 'package:flutter/material.dart';

import '../../models/favorito.dart';
import '../../models/mascota.dart';
import '../../services/auth_service.dart';
import '../../services/favorito_service.dart';
import '../../services/mascota_service.dart';
import 'detalle_mascota_screen.dart';

class FavoritosScreen extends StatefulWidget {
  const FavoritosScreen({super.key});

  @override
  State<FavoritosScreen> createState() => _FavoritosScreenState();
}

class _FavoritosScreenState extends State<FavoritosScreen> {
  late Future<List<Mascota>> _mascotasFuture;

  @override
  void initState() {
    super.initState();
    _cargarFavoritos();
  }

  void _cargarFavoritos() {
    _mascotasFuture = _obtenerMascotasFavoritas();
  }

  Future<List<Mascota>> _obtenerMascotasFavoritas() async {
    final usuario = AuthService().usuarioActual;

    if (usuario == null) {
      return [];
    }

    final favoritos = await FavoritoService().obtenerFavoritos(
      usuario.uid,
    );

    final List<Mascota> mascotas = [];

    for (final Favorito favorito in favoritos) {
      final mascota = await MascotaService().obtenerMascotaPorId(
        favorito.mascotaId,
      );

      if (mascota != null) {
        mascotas.add(mascota);
      }
    }

    return mascotas;
  }

  Future<void> _recargarFavoritos() async {
    setState(() {
      _cargarFavoritos();
    });

    await _mascotasFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis favoritos'),
      ),
      body: FutureBuilder<List<Mascota>>(
        future: _mascotasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No se pudieron cargar tus favoritos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _recargarFavoritos,
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
              onRefresh: _recargarFavoritos,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 150),
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Todavía no tenés mascotas favoritas.',
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
            onRefresh: _recargarFavoritos,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: mascotas.length,
              itemBuilder: (context, index) {
                final mascota = mascotas[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.all(12),
                    leading: SizedBox(
                      width: 80,
                      height: 80,
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(10),
                        child: mascota.imagenUrl.isNotEmpty
                            ? Image.network(
                                mascota.imagenUrl,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.pets,
                                    size: 45,
                                  );
                                },
                              )
                            : const Icon(
                                Icons.pets,
                                size: 45,
                              ),
                      ),
                    ),
                    title: Text(
                      mascota.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      '${mascota.especie} · ${mascota.raza}',
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: () {
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