
import 'package:flutter/material.dart';

import '../../models/mascota.dart';
import '../../services/auth_service.dart';
import '../../services/mascota_service.dart';

class PublicarMascotaScreen extends StatefulWidget {
  final Mascota? mascota;

  const PublicarMascotaScreen({
    super.key,
    this.mascota,
  });

  @override
  State<PublicarMascotaScreen> createState() =>
      _PublicarMascotaScreenState();
}

class _PublicarMascotaScreenState
    extends State<PublicarMascotaScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _razaController = TextEditingController();
  final _edadController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _imagenUrlController = TextEditingController();

  String _especie = 'Perro';
  String _sexo = 'Macho';
  String _tamano = 'Mediano';

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

  Future<void> _guardarMascota() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final usuario = AuthService().usuarioActual;

    if (usuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay una sesión iniciada.'),
        ),
      );
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      if (_modoEdicion) {
        await MascotaService().actualizarMascota(
          widget.mascota!.id,
          {
            'nombre': _nombreController.text.trim(),
            'especie': _especie,
            'raza': _razaController.text.trim(),
            'edad': _edadController.text.trim(),
            'sexo': _sexo,
            'tamano': _tamano,
            'descripcion': _descripcionController.text.trim(),
            'imagenUrl': _imagenUrlController.text.trim(),
          },
        );
      } else {
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
          fechaPublicacion: DateTime.now(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _modoEdicion ? 'Editar mascota' : 'Publicar mascota',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.pets,
                  size: 80,
                ),
                const SizedBox(height: 20),
                Text(
                  _modoEdicion
                      ? 'Editar datos de la mascota'
                      : 'Datos de la mascota',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),

                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    prefixIcon: Icon(Icons.pets),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresá el nombre de la mascota';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                DropdownButtonFormField<String>(
                  initialValue: _especie,
                  decoration: const InputDecoration(
                    labelText: 'Especie',
                    prefixIcon: Icon(Icons.category_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Perro',
                      child: Text('Perro'),
                    ),
                    DropdownMenuItem(
                      value: 'Gato',
                      child: Text('Gato'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _especie = value;
                      });
                    }
                  },
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller: _razaController,
                  decoration: const InputDecoration(
                    labelText: 'Raza',
                    prefixIcon: Icon(Icons.info_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresá la raza';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller: _edadController,
                  decoration: const InputDecoration(
                    labelText: 'Edad',
                    hintText: 'Ej.: 2 años, 6 meses o 1 año y 6 meses',
                    prefixIcon: Icon(Icons.cake_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: _validarEdad,
                ),

                const SizedBox(height: 18),

                DropdownButtonFormField<String>(
                  initialValue: _sexo,
                  decoration: const InputDecoration(
                    labelText: 'Sexo',
                    prefixIcon: Icon(Icons.wc_outlined),
                    border: OutlineInputBorder(),
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
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _sexo = value;
                      });
                    }
                  },
                ),

                const SizedBox(height: 18),

                DropdownButtonFormField<String>(
                  initialValue: _tamano,
                  decoration: const InputDecoration(
                    labelText: 'Tamaño',
                    prefixIcon: Icon(Icons.straighten),
                    border: OutlineInputBorder(),
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
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _tamano = value;
                      });
                    }
                  },
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller: _descripcionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    hintText: 'Contanos un poco sobre la mascota...',
                    prefixIcon: Icon(Icons.description_outlined),
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresá una descripción';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller: _imagenUrlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'URL de imagen',
                    hintText: 'https://ejemplo.com/imagen.jpg',
                    prefixIcon: Icon(Icons.image_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: _validarImagenUrl,
                ),

                const SizedBox(height: 30),

                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _guardando ? null : _guardarMascota,
                    child: _guardando
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(),
                          )
                        : Text(
                            _modoEdicion
                                ? 'Guardar cambios'
                                : 'Publicar mascota',
                            style: const TextStyle(
                              fontSize: 16,
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
    );
  }
}