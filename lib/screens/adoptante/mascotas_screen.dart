import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../models/mascota.dart';
import '../../services/mascota_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/adopta_widgets.dart';
import 'detalle_mascota_screen.dart';

// ==========================================
// CATALOGO DE MASCOTAS
// ==========================================

class MascotasScreen extends StatefulWidget {
  const MascotasScreen({super.key});

  @override
  State<MascotasScreen> createState() => _MascotasScreenState();
}

class _MascotasScreenState extends State<MascotasScreen> {
  late Future<List<Mascota>> _mascotasFuture;

  final TextEditingController _busquedaController = TextEditingController();

  String _busqueda = '';
  String _filtro = 'Todos';

  @override
  void initState() {
    super.initState();
    _cargarMascotas();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  // ========================================
  // CONSULTA DE MASCOTAS
  // ========================================

  void _cargarMascotas() {
    _mascotasFuture = MascotaService().obtenerMascotas();
  }

  Future<void> _recargarMascotas() async {
    setState(_cargarMascotas);

    try {
      await _mascotasFuture;
    } catch (_) {
      // FutureBuilder mostrará el error.
    }
  }

  // ========================================
  // BUSQUEDA Y FILTROS
  // ========================================

  void _actualizarBusqueda(String valor) {
    setState(() {
      _busqueda = valor.trim().toLowerCase();
    });
  }

  void _seleccionarFiltro(String filtro) {
    setState(() {
      _filtro = filtro;
    });
  }

  void _limpiarFiltros() {
    _busquedaController.clear();

    setState(() {
      _busqueda = '';
      _filtro = 'Todos';
    });
  }

  // ========================================
  // NAVEGACION AL DETALLE
  // ========================================

  void _abrirMascota(Mascota mascota) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetalleMascotaScreen(mascota: mascota)),
    );
  }

  // ========================================
  // INTERFAZ PRINCIPAL
  // ========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text('Explorar mascotas'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        scrolledUnderElevation: 0,
      ),

      body: Column(
        children: [
          // ENCABEZADO Y FILTROS
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFEAF7FF), AppColors.background],
              ),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 13, 20, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TITULO DEL CATALOGO
                      const PageHeading(
                        eyebrow: 'ENCONTRÁ TU COMPAÑERO',
                        title: 'Amor a primera patita.',
                        subtitle:
                            'Conocé a quienes están '
                            'esperando una familia '
                            'y encontrá a tu nuevo '
                            'mejor amigo.',
                      ),

                      const SizedBox(height: 23),

                      // BUSCADOR
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(19),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0D164E86),
                              blurRadius: 17,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _busquedaController,
                          onChanged: _actualizarBusqueda,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: 'Buscar por nombre o raza...',
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: AppColors.primary,
                              size: 23,
                            ),
                            suffixIcon: _busquedaController.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Limpiar búsqueda',
                                    onPressed: () {
                                      _busquedaController.clear();
                                      _actualizarBusqueda('');
                                    },
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: AppColors.muted,
                                    ),
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 23),

                      // TITULO DE FILTROS
                      Row(
                        children: [
                          const Icon(
                            Icons.tune_rounded,
                            color: AppColors.primary,
                            size: 19,
                          ),

                          const SizedBox(width: 8),

                          Text(
                            'Filtrar mascotas',
                            style: GoogleFonts.quicksand(
                              color: AppColors.ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          const Spacer(),

                          if (_filtro != 'Todos' || _busqueda.isNotEmpty)
                            TextButton(
                              onPressed: _limpiarFiltros,
                              child: const Text(
                                'Limpiar',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // FILTROS DE ESPECIE
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FiltroMascota(
                              texto: 'Todos',
                              icono: '🐾',
                              seleccionado: _filtro == 'Todos',
                              onTap: () {
                                _seleccionarFiltro('Todos');
                              },
                            ),

                            const SizedBox(width: 9),

                            _FiltroMascota(
                              texto: 'Perros',
                              icono: '🐶',
                              seleccionado: _filtro == 'Perro',
                              onTap: () {
                                _seleccionarFiltro('Perro');
                              },
                            ),

                            const SizedBox(width: 9),

                            _FiltroMascota(
                              texto: 'Gatos',
                              icono: '🐱',
                              seleccionado: _filtro == 'Gato',
                              onTap: () {
                                _seleccionarFiltro('Gato');
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // LISTADO DE MASCOTAS
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _recargarMascotas,
              child: FutureBuilder<List<Mascota>>(
                future: _mascotasFuture,
                builder: (context, snapshot) {
                  // ==================================
                  // ESTADO DE CARGA
                  // ==================================

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _CatalogoCargando();
                  }

                  // ==================================
                  // ESTADO DE ERROR
                  // ==================================

                  if (snapshot.hasError) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        AppEmptyState(
                          icon: Icons.wifi_off_rounded,
                          title: 'No pudimos cargar las mascotas',
                          message:
                              'Revisá tu conexión a Internet '
                              'e intentá nuevamente.',
                          actionLabel: 'Reintentar',
                          onAction: _recargarMascotas,
                        ),
                      ],
                    );
                  }

                  // ==================================
                  // FILTRAR MASCOTAS
                  // ==================================

                  final mascotas = (snapshot.data ?? []).where((mascota) {
                    if (!mascota.disponibleParaAdopcion) {
                      return false;
                    }

                    final especie = mascota.especie.toLowerCase();

                    final cumpleFiltro =
                        _filtro == 'Todos' || especie == _filtro.toLowerCase();

                    final textoBusqueda =
                        '${mascota.nombre} '
                                '${mascota.raza} '
                                '${mascota.especie}'
                            .toLowerCase();

                    return cumpleFiltro && textoBusqueda.contains(_busqueda);
                  }).toList();

                  // ==================================
                  // ESTADO VACIO
                  // ==================================

                  if (mascotas.isEmpty) {
                    final hayFiltros =
                        _busqueda.isNotEmpty || _filtro != 'Todos';

                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        AppEmptyState(
                          icon: Icons.pets_outlined,
                          title: hayFiltros
                              ? 'No encontramos mascotas'
                              : 'Pronto habrá nuevos amigos',
                          message: hayFiltros
                              ? 'Probá con otro nombre '
                                    'o cambiá los filtros '
                                    'para descubrir más mascotas.'
                              : 'Todavía no hay mascotas '
                                    'disponibles para adopción. '
                                    'Volvé a visitarnos pronto.',
                          actionLabel: hayFiltros
                              ? 'Limpiar filtros'
                              : 'Actualizar',
                          onAction: hayFiltros
                              ? _limpiarFiltros
                              : _recargarMascotas,
                        ),
                      ],
                    );
                  }

                  // ==================================
                  // MOSTRAR RESULTADOS
                  // ==================================

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),

                    itemCount: mascotas.length + 1,

                    itemBuilder: (context, index) {
                      // CONTADOR DE RESULTADOS
                      if (index == 0) {
                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 600),

                            child: Padding(
                              padding: const EdgeInsets.only(
                                bottom: 19,
                                top: 5,
                              ),

                              child: _ResumenResultados(
                                cantidad: mascotas.length,
                              ),
                            ),
                          ),
                        );
                      }

                      // TARJETA DE MASCOTA
                      final mascota = mascotas[index - 1];

                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),

                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 17),

                            child: PetCard(
                              mascota: mascota,
                              onTap: () {
                                _abrirMascota(mascota);
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// FILTRO DE MASCOTAS
// ==========================================

class _FiltroMascota extends StatelessWidget {
  final String texto;
  final String icono;
  final bool seleccionado;
  final VoidCallback onTap;

  const _FiltroMascota({
    required this.texto,
    required this.icono,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: seleccionado,
      label: 'Mostrar $texto',

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,

        decoration: BoxDecoration(
          color: seleccionado ? AppColors.primary : Colors.white,

          borderRadius: BorderRadius.circular(16),

          border: Border.all(
            color: seleccionado ? AppColors.primary : AppColors.border,
          ),

          boxShadow: seleccionado
              ? const [
                  BoxShadow(
                    color: Color(0x2256B8F2),
                    blurRadius: 12,
                    offset: Offset(0, 5),
                  ),
                ]
              : null,
        ),

        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),

          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),

            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),

              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(icono, style: const TextStyle(fontSize: 17)),

                  const SizedBox(width: 8),

                  Text(
                    texto,
                    style: GoogleFonts.quicksand(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: seleccionado ? Colors.white : AppColors.ink,
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

// ==========================================
// RESUMEN DE RESULTADOS
// ==========================================

class _ResumenResultados extends StatelessWidget {
  final int cantidad;

  const _ResumenResultados({required this.cantidad});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 37,
          height: 37,
          decoration: BoxDecoration(
            color: AppColors.azulPastel,
            borderRadius: BorderRadius.circular(12),
          ),

          child: const Icon(
            Icons.pets_rounded,
            color: AppColors.primary,
            size: 19,
          ),
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$cantidad ${cantidad == 1 ? 'amigo disponible' : 'amigos disponibles'}',
                style: GoogleFonts.quicksand(
                  color: AppColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 3),

              const Text(
                'Cada uno tiene una historia especial.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ==========================================
// CARGA CON SKELETONIZER
// ==========================================

class _CatalogoCargando extends StatelessWidget {
  const _CatalogoCargando();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,

      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),

        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),

        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),

              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 18),
                    child: Text(
                      'Varias mascotas disponibles',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  _TarjetaMascotaCargando(),

                  SizedBox(height: 17),

                  _TarjetaMascotaCargando(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// TARJETA TEMPORAL DE CARGA
// ==========================================

class _TarjetaMascotaCargando extends StatelessWidget {
  const _TarjetaMascotaCargando();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: AppColors.border),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // FOTOGRAFIA TEMPORAL
          const Skeleton.leaf(
            child: SizedBox(
              height: 195,
              width: double.infinity,

              child: ColoredBox(color: AppColors.azulPastel),
            ),
          ),

          // INFORMACION TEMPORAL
          Padding(
            padding: const EdgeInsets.all(19),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nombre de mascota',
                  style: GoogleFonts.quicksand(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Especie y raza de la mascota',
                  style: TextStyle(fontSize: 13),
                ),

                const SizedBox(height: 18),

                const Wrap(
                  spacing: 16,
                  runSpacing: 10,
                  children: [Text('Edad'), Text('Tamaño'), Text('Sexo')],
                ),

                const SizedBox(height: 19),

                const Text(
                  'Conoceme mejor',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
