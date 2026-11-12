import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/mascota.dart';
import '../../theme/app_theme.dart';
import '../../widgets/adopta_widgets.dart';
import '../../services/auth_service.dart';
import '../../services/mascota_service.dart';

// ==========================================
// PUBLICAR Y EDITAR MASCOTAS
// ==========================================

class PublicarMascotaScreen extends StatefulWidget {
  final Mascota? mascota;

  const PublicarMascotaScreen({super.key, this.mascota});

  @override
  State<PublicarMascotaScreen> createState() => _PublicarMascotaScreenState();
}

class _PublicarMascotaScreenState extends State<PublicarMascotaScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _razaController = TextEditingController();
  final _edadController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _imagenUrlController = TextEditingController();

  String _especie = 'Perro';
  String _sexo = 'Macho';
  String _tamano = 'Mediano';

  String _urlVistaPrevia = '';

  bool _guardando = false;

  bool get _modoEdicion => widget.mascota != null;

  @override
  void initState() {
    super.initState();

    final mascota = widget.mascota;

    if (mascota != null) {
      _nombreController.text = mascota.nombre;
      _razaController.text = mascota.raza;
      _edadController.text = mascota.edad;
      _descripcionController.text = mascota.descripcion;
      _imagenUrlController.text = mascota.imagenUrl;

      _especie = mascota.especie;
      _sexo = mascota.sexo;
      _tamano = mascota.tamano;

      _urlVistaPrevia = mascota.imagenUrl;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _razaController.dispose();
    _edadController.dispose();
    _descripcionController.dispose();
    _imagenUrlController.dispose();

    super.dispose();
  }

  // ========================================
  // GUARDAR MASCOTA EN FIREBASE
  // ========================================

  Future<void> _guardarMascota() async {
    if (_guardando) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final usuario = AuthService().usuarioActual;

    if (usuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay una sesión iniciada.')),
      );
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      if (_modoEdicion) {
        // ACTUALIZAR UNA MASCOTA EXISTENTE
        await MascotaService().actualizarMascota(widget.mascota!.id, {
          'nombre': _nombreController.text.trim(),
          'especie': _especie,
          'raza': _razaController.text.trim(),
          'edad': _edadController.text.trim(),
          'sexo': _sexo,
          'tamano': _tamano,
          'descripcion': _descripcionController.text.trim(),
          'imagenUrl': _imagenUrlController.text.trim(),
        });
      } else {
        // CREAR UNA PUBLICACION POR SIETE DIAS
        final fechaPublicacion = DateTime.now();

        final fechaVencimiento = fechaPublicacion.add(const Duration(days: 7));

        final mascota = Mascota(
          id: '',
          nombre: _nombreController.text.trim(),
          especie: _especie,
          raza: _razaController.text.trim(),
          edad: _edadController.text.trim(),
          sexo: _sexo,
          tamano: _tamano,
          descripcion: _descripcionController.text.trim(),
          imagenUrl: _imagenUrlController.text.trim(),
          estado: 'disponible',
          refugioId: usuario.uid,
          fechaPublicacion: fechaPublicacion,
          fechaVencimiento: fechaVencimiento,
        );

        await MascotaService().crearMascota(mascota);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _modoEdicion
                ? 'Mascota actualizada correctamente.'
                : 'Mascota publicada correctamente.',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _modoEdicion
                ? 'No se pudo actualizar la mascota.'
                : 'No se pudo publicar la mascota.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  // ========================================
  // VALIDACION DE EDAD
  // ========================================

  String? _validarEdad(String? value) {
    final edad = value?.trim().toLowerCase() ?? '';

    if (edad.isEmpty) {
      return 'Ingresá la edad';
    }

    final patron = RegExp(
      r'^(\d+)\s*(años?|meses?|semanas?|días?)$|^(\d+)\s*años?\s+y\s+(\d+)\s*meses?$',
    );

    final coincidencia = patron.firstMatch(edad);

    if (coincidencia == null) {
      return 'Ingresá una edad válida. Ej.: 2 años o 6 meses';
    }

    if (coincidencia.group(1) != null) {
      final cantidad = int.tryParse(coincidencia.group(1)!);

      if (cantidad == null || cantidad <= 0) {
        return 'La edad debe ser mayor que cero';
      }
    } else {
      final anios = int.tryParse(coincidencia.group(3)!);

      final meses = int.tryParse(coincidencia.group(4)!);

      if (anios == null ||
          meses == null ||
          (anios == 0 && meses == 0) ||
          meses >= 12) {
        return 'Ingresá una edad válida. Ej.: 1 año y 6 meses';
      }
    }

    return null;
  }

  // ========================================
  // VALIDACION DE URL DE IMAGEN
  // ========================================

  String? _validarImagenUrl(String? value) {
    final url = value?.trim() ?? '';

    // La imagen es opcional.
    if (url.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(url);

    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty ||
        !uri.host.contains('.')) {
      return 'Ingresá una URL válida que comience con https://';
    }

    return null;
  }

  // ========================================
  // VISTA PREVIA DE FOTOGRAFIA
  // ========================================

  void _mostrarVistaPrevia() {
    final url = _imagenUrlController.text.trim();

    if (url.isEmpty) {
      setState(() {
        _urlVistaPrevia = '';
      });
      return;
    }

    final error = _validarImagenUrl(url);

    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    setState(() {
      _urlVistaPrevia = url;
    });
  }

  // ========================================
  // INTERFAZ PRINCIPAL
  // ========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        scrolledUnderElevation: 0,
        title: Text(_modoEdicion ? 'Editar mascota' : 'Publicar mascota'),
      ),

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
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 40),

              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),

                child: Form(
                  key: _formKey,

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ==================================
                      // ENCABEZADO
                      // ==================================

                      PageHeading(
                        eyebrow: _modoEdicion
                            ? 'ACTUALIZAR FICHA'
                            : 'NUEVA PUBLICACIÓN',
                        title: _modoEdicion
                            ? 'Editá su historia.'
                            : 'Contanos sobre tu mascota.',
                        subtitle:
                            'Un perfil completo ayuda '
                            'a encontrar a la familia '
                            'correcta.',
                      ),

                      const SizedBox(height: 24),

                      // ==================================
                      // BANNER PRINCIPAL
                      // ==================================
                      _BannerFormularioMascota(modoEdicion: _modoEdicion)
                          .animate()
                          .fadeIn(duration: 450.ms)
                          .slideY(begin: 0.05, end: 0, duration: 450.ms),

                      const SizedBox(height: 22),

                      // ==================================
                      // CONSEJO
                      // ==================================
                      const _ConsejoPublicacion(),

                      const SizedBox(height: 28),

                      // ==================================
                      // DATOS GENERALES
                      // ==================================
                      _SeccionFormulario(
                        icono: Icons.pets_rounded,
                        titulo: 'Información principal',
                        subtitulo:
                            'Empecemos por conocer a '
                            'nuestro nuevo amigo.',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _EtiquetaCampo(texto: 'Nombre de la mascota'),

                            const SizedBox(height: 9),

                            TextFormField(
                              controller: _nombreController,
                              enabled: !_guardando,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                hintText: '¿Cómo se llama?',
                                prefixIcon: Icon(Icons.pets_outlined),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Ingresá el nombre de la mascota';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 20),

                            const _EtiquetaCampo(texto: 'Especie'),

                            const SizedBox(height: 9),

                            DropdownButtonFormField<String>(
                              initialValue: _especie,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.category_outlined),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Perro',
                                  child: Text('🐶  Perro'),
                                ),
                                DropdownMenuItem(
                                  value: 'Gato',
                                  child: Text('🐱  Gato'),
                                ),
                              ],
                              onChanged: _guardando
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        setState(() {
                                          _especie = value;
                                        });
                                      }
                                    },
                            ),

                            const SizedBox(height: 20),

                            const _EtiquetaCampo(texto: 'Raza'),

                            const SizedBox(height: 9),

                            TextFormField(
                              controller: _razaController,
                              enabled: !_guardando,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                hintText: 'Ej.: Mestizo, Labrador...',
                                prefixIcon: Icon(Icons.info_outline_rounded),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Ingresá la raza';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ==================================
                      // CARACTERISTICAS DE LA MASCOTA
                      // ==================================
                      _SeccionFormulario(
                        icono: Icons.auto_awesome_rounded,
                        titulo: 'Sus características',
                        subtitulo:
                            'Estos datos ayudan a las '
                            'familias a conocerla mejor.',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _EtiquetaCampo(texto: 'Edad'),

                            const SizedBox(height: 9),

                            TextFormField(
                              controller: _edadController,
                              enabled: !_guardando,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                hintText: 'Ej.: 2 años o 6 meses',
                                prefixIcon: Icon(Icons.cake_outlined),
                              ),
                              validator: _validarEdad,
                            ),

                            const SizedBox(height: 10),

                            const Text(
                              'También podés escribir '
                              '"1 año y 6 meses".',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 11,
                                height: 1.5,
                              ),
                            ),

                            const SizedBox(height: 20),

                            const _EtiquetaCampo(texto: 'Sexo'),

                            const SizedBox(height: 9),

                            DropdownButtonFormField<String>(
                              initialValue: _sexo,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.wc_outlined),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Macho',
                                  child: Text('Macho'),
                                ),
                                DropdownMenuItem(
                                  value: 'Hembra',
                                  child: Text('Hembra'),
                                ),
                              ],
                              onChanged: _guardando
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        setState(() {
                                          _sexo = value;
                                        });
                                      }
                                    },
                            ),

                            const SizedBox(height: 20),

                            const _EtiquetaCampo(texto: 'Tamaño'),

                            const SizedBox(height: 9),

                            DropdownButtonFormField<String>(
                              initialValue: _tamano,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.straighten_rounded),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Pequeño',
                                  child: Text('Pequeño'),
                                ),
                                DropdownMenuItem(
                                  value: 'Mediano',
                                  child: Text('Mediano'),
                                ),
                                DropdownMenuItem(
                                  value: 'Grande',
                                  child: Text('Grande'),
                                ),
                              ],
                              onChanged: _guardando
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        setState(() {
                                          _tamano = value;
                                        });
                                      }
                                    },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ==================================
                      // HISTORIA Y PERSONALIDAD
                      // ==================================
                      _SeccionFormulario(
                        icono: Icons.favorite_outline_rounded,
                        titulo: 'Su historia',
                        subtitulo:
                            'Contanos qué hace especial '
                            'a esta mascota.',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _EtiquetaCampo(texto: 'Descripción'),

                            const SizedBox(height: 9),

                            TextFormField(
                              controller: _descripcionController,
                              enabled: !_guardando,
                              maxLines: 5,
                              minLines: 4,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                hintText:
                                    'Contanos sobre su personalidad, '
                                    'sus costumbres y qué tipo '
                                    'de hogar necesita...',
                                alignLabelWithHint: true,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Ingresá una descripción';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 13),

                            const _MensajeInformativo(
                              icono: Icons.lightbulb_outline,
                              mensaje:
                                  'Una descripción sincera '
                                  'y detallada puede ayudar '
                                  'a encontrar el hogar ideal.',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ==================================
                      // FOTOGRAFIA DE LA MASCOTA
                      // ==================================
                      _SeccionFormulario(
                        icono: Icons.image_outlined,
                        titulo: 'Su mejor fotografía',
                        subtitulo:
                            'Una buena imagen puede '
                            'marcar la diferencia.',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _EtiquetaCampo(
                              texto: 'URL de imagen (opcional)',
                            ),

                            const SizedBox(height: 9),

                            TextFormField(
                              controller: _imagenUrlController,
                              enabled: !_guardando,
                              keyboardType: TextInputType.url,
                              textInputAction: TextInputAction.done,
                              autocorrect: false,
                              decoration: const InputDecoration(
                                hintText: 'https://ejemplo.com/imagen.jpg',
                                prefixIcon: Icon(Icons.link_rounded),
                              ),
                              validator: _validarImagenUrl,
                              onChanged: (_) {
                                if (_urlVistaPrevia.isNotEmpty) {
                                  setState(() {
                                    _urlVistaPrevia = '';
                                  });
                                }
                              },
                            ),

                            const SizedBox(height: 12),

                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: _guardando
                                    ? null
                                    : _mostrarVistaPrevia,
                                icon: const Icon(
                                  Icons.visibility_outlined,
                                  size: 18,
                                ),
                                label: const Text('Ver vista previa'),
                              ),
                            ),

                            const SizedBox(height: 13),

                            // VISTA PREVIA
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: _urlVistaPrevia.isNotEmpty
                                  ? ClipRRect(
                                      key: ValueKey(_urlVistaPrevia),
                                      borderRadius: BorderRadius.circular(20),
                                      child: PetPhoto(
                                        imageUrl: _urlVistaPrevia,
                                        width: double.infinity,
                                        height: 210,
                                        radius: BorderRadius.circular(20),
                                      ),
                                    )
                                  : const _FotoSinVistaPrevia(
                                      key: ValueKey('sin-vista-previa'),
                                    ),
                            ),

                            const SizedBox(height: 12),

                            const Text(
                              'La fotografía es opcional, '
                              'pero te recomendamos '
                              'agregar una imagen clara '
                              'y bien iluminada.',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                                height: 1.55,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 27),

                      // ==================================
                      // INFORMACION DE VIGENCIA
                      // ==================================
                      if (!_modoEdicion) ...[
                        const _MensajeInformativo(
                          icono: Icons.calendar_today_outlined,
                          mensaje:
                              'Tu publicación estará '
                              'vigente durante 7 días. '
                              'Después podrás renovarla '
                              'desde Mis publicaciones.',
                        ),

                        const SizedBox(height: 22),
                      ],

                      // ==================================
                      // BOTON GUARDAR
                      // ==================================
                      SizedBox(
                        height: 58,
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _guardando ? null : _guardarMascota,
                          icon: _guardando
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  _modoEdicion
                                      ? Icons.save_outlined
                                      : Icons.add_circle_outline_rounded,
                                  size: 21,
                                ),
                          label: Text(
                            _guardando
                                ? 'Guardando...'
                                : _modoEdicion
                                ? 'Guardar cambios'
                                : 'Publicar mascota',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite_rounded,
                            color: AppColors.celeste,
                            size: 15,
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Cada mascota merece '
                              'una historia feliz.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),
                    ],
                  ),
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
// BANNER SUPERIOR DEL FORMULARIO
// ==========================================

class _BannerFormularioMascota extends StatelessWidget {
  final bool modoEdicion;

  const _BannerFormularioMascota({required this.modoEdicion});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF70C9F5), Color(0xFF378ED5), Color(0xFF1C64B1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2756B8F2),
            blurRadius: 23,
            offset: Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned(
            top: -50,
            right: -35,
            child: Icon(
              Icons.pets_rounded,
              size: 170,
              color: Color(0x24FFFFFF),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x35FFFFFF),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        modoEdicion
                            ? Icons.edit_outlined
                            : Icons.favorite_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        modoEdicion
                            ? 'ACTUALIZANDO UNA HISTORIA'
                            : 'UNA NUEVA OPORTUNIDAD',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 19),
                Text(
                  modoEdicion
                      ? 'Cada detalle\nhace la diferencia.'
                      : 'Una publicación,\nun nuevo comienzo.',
                  style: GoogleFonts.quicksand(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    height: 1.18,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Las grandes historias '
                  'empiezan con una oportunidad.',
                  style: TextStyle(
                    color: Color(0xFFF0FAFF),
                    fontSize: 12,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
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

// ==========================================
// SECCION REUTILIZABLE DEL FORMULARIO
// ==========================================

class _SeccionFormulario extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final Widget child;

  const _SeccionFormulario({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D164E86),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: AppColors.azulPastel,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icono, color: AppColors.primary, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: GoogleFonts.quicksand(
                        color: AppColors.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitulo,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 23),
          child,
        ],
      ),
    );
  }
}

// ==========================================
// ETIQUETA DE CAMPO
// ==========================================

class _EtiquetaCampo extends StatelessWidget {
  final String texto;

  const _EtiquetaCampo({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: GoogleFonts.quicksand(
        color: AppColors.ink,
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

// ==========================================
// CONSEJO SUPERIOR
// ==========================================

class _ConsejoPublicacion extends StatelessWidget {
  const _ConsejoPublicacion();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.azulSuave,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.tips_and_updates_outlined,
            color: AppColors.primary,
            size: 23,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Usá una foto clara y describí '
              'su personalidad para conectar '
              'con posibles adoptantes.',
              style: TextStyle(
                color: AppColors.primaryDark,
                fontSize: 12,
                height: 1.55,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// MENSAJE INFORMATIVO
// ==========================================

class _MensajeInformativo extends StatelessWidget {
  final IconData icono;
  final String mensaje;

  const _MensajeInformativo({required this.icono, required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.azulSuave,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: AppColors.primary, size: 19),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              mensaje,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// VISTA PREVIA SIN IMAGEN
// ==========================================

class _FotoSinVistaPrevia extends StatelessWidget {
  const _FotoSinVistaPrevia({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 178,
      decoration: BoxDecoration(
        color: AppColors.azulSuave,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            color: AppColors.celeste,
            size: 42,
          ),
          SizedBox(height: 12),
          Text(
            'Vista previa de la fotografía',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Ingresá una URL y tocá "Ver vista previa".',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
