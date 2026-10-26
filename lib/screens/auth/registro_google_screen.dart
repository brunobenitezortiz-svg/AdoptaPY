
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/usuario_service.dart';
import '../adoptante/home_screen.dart';
import '../refugio/dashboard_screen.dart';
import 'documentos_legales.dart';

class RegistroGoogleScreen extends StatefulWidget {
  const RegistroGoogleScreen({super.key});

  @override
  State<RegistroGoogleScreen> createState() =>
      _RegistroGoogleScreenState();
}

class _RegistroGoogleScreenState extends State<RegistroGoogleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();

  String _rolSeleccionado = 'adoptante';
  bool _aceptoTerminos = false;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _nombreController.text =
        FirebaseAuth.instance.currentUser?.displayName ?? '';
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _completarRegistro() async {
    if (_guardando) return;

    if (!_formKey.currentState!.validate()) return;

    if (!_aceptoTerminos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debés aceptar los términos y la política de privacidad.',
          ),
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      final usuario = FirebaseAuth.instance.currentUser;

      if (usuario == null || usuario.email == null) {
        throw Exception('No se encontró una cuenta de Google válida.');
      }

      final servicio = UsuarioService();
      final documento = await servicio.obtenerUsuario(usuario.uid);

      if (documento.exists) {
        throw Exception(
          'Este usuario ya tiene un perfil registrado.',
        );
      }

      await servicio.crearUsuario(
        uid: usuario.uid,
        nombre: _nombreController.text.trim(),
        email: usuario.email!,
        rol: _rolSeleccionado,
        aceptoTerminos: _aceptoTerminos,
      );

      if (!mounted) return;

      final destino = _rolSeleccionado == 'adoptante'
          ? const HomeScreen()
          : const DashboardScreen();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => destino),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo completar el registro: $e'),
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Completar registro'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Icon(Icons.pets, size: 75),
                const SizedBox(height: 16),
                const Text(
                  'Bienvenido a AdoptaPY',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Completá tu perfil para continuar.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                TextFormField(
                  initialValue: usuario?.email ?? '',
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Correo de Google',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _nombreController,
                  enabled: !_guardando,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'Ingresá tu nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                const Text(
                  '¿Qué tipo de usuario sos?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'adoptante',
                      label: Text('Adoptante'),
                      icon: Icon(Icons.person),
                    ),
                    ButtonSegment(
                      value: 'refugio',
                      label: Text('Refugio'),
                      icon: Icon(Icons.home),
                    ),
                  ],
                  selected: {_rolSeleccionado},
                  onSelectionChanged: _guardando
                      ? null
                      : (seleccion) {
                          setState(() {
                            _rolSeleccionado = seleccion.first;
                          });
                        },
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outlineVariant,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity:
                            ListTileControlAffinity.leading,
                        value: _aceptoTerminos,
                        onChanged: _guardando
                            ? null
                            : (valor) {
                                setState(() {
                                  _aceptoTerminos = valor ?? false;
                                });
                              },
                        title: const Text(
                          'He leído y acepto los Términos de uso '
                          'y la Política de privacidad.',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              DocumentosLegales.mostrarTerminos(
                                context,
                              );
                            },
                            icon: const Icon(
                              Icons.description_outlined,
                              size: 18,
                            ),
                            label: const Text('Ver términos'),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              DocumentosLegales.mostrarPrivacidad(
                                context,
                              );
                            },
                            icon: const Icon(
                              Icons.privacy_tip_outlined,
                              size: 18,
                            ),
                            label: const Text('Ver privacidad'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                        _guardando ? null : _completarRegistro,
                    child: _guardando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Completar registro'),
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
