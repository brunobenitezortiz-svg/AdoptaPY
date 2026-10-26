
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/auth_service.dart';
import '../../services/usuario_service.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmarPasswordController =
      TextEditingController();

  String _rolSeleccionado = 'adoptante';

  bool _ocultarPassword = true;
  bool _ocultarConfirmacion = true;
  bool _aceptoTerminos = false;
  bool _registrando = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmarPasswordController.dispose();
    super.dispose();
  }

  void _mostrarDocumento({
    required String titulo,
    required String contenido,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(titulo),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Text(
                contenido,
                style: const TextStyle(height: 1.6),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _verTerminos() {
    _mostrarDocumento(
      titulo: 'Términos de uso',
      contenido: '''
TÉRMINOS DE USO — ADOPTA MASCOTAS

1. Objetivo de la aplicación

Adopta Mascotas es una aplicación académica que facilita el contacto entre personas interesadas en adoptar mascotas y refugios que publican animales disponibles para adopción.

2. Registro de usuarios

Para utilizar las funciones de la aplicación es necesario crear una cuenta y proporcionar información verídica.

3. Responsabilidades de los adoptantes

Los adoptantes deben utilizar la plataforma de manera responsable y proporcionar información honesta en sus solicitudes.

4. Responsabilidades de los refugios

Los refugios son responsables de la información que publican sobre las mascotas y de gestionar las solicitudes de adopción.

5. Publicaciones

Las publicaciones de mascotas tienen una vigencia de siete días. Los refugios pueden renovarlas cuando corresponda.

6. Proceso de adopción

Enviar una solicitud no garantiza que la adopción sea aprobada. El refugio correspondiente decide si acepta o rechaza la solicitud.

7. Uso adecuado

No se permite utilizar la aplicación para publicar información falsa, realizar actividades fraudulentas o perjudicar a otros usuarios.

8. Alcance académico

Esta aplicación se desarrolla con fines educativos. Su funcionamiento no constituye una garantía sobre los procesos de adopción realizados fuera de la plataforma.
''',
    );
  }

  void _verPrivacidad() {
    _mostrarDocumento(
      titulo: 'Política de privacidad',
      contenido: '''
POLÍTICA DE PRIVACIDAD — ADOPTA MASCOTAS

1. Información recopilada

La aplicación solicita nombre, correo electrónico, contraseña y tipo de usuario durante el registro.

También puede almacenar publicaciones de mascotas, favoritos y solicitudes de adopción relacionadas con la cuenta.

2. Almacenamiento

La autenticación se gestiona mediante Firebase Authentication y los datos de la aplicación se almacenan mediante Cloud Firestore.

3. Contraseñas

Las contraseñas se utilizan para la autenticación mediante Firebase Authentication y no se guardan como texto en los documentos de usuarios de Firestore.

4. Finalidad de los datos

La información se utiliza para identificar usuarios, administrar publicaciones de mascotas y gestionar solicitudes de adopción.

5. Acceso a la información

La aplicación utiliza reglas de seguridad de Firebase para controlar las operaciones permitidas a cada tipo de usuario.

6. Aceptación

Al registrarse, el usuario confirma que ha leído y acepta los términos de uso y esta política de privacidad.

La aplicación registra esta aceptación y su fecha.

7. Proyecto académico

Adopta Mascotas es un proyecto desarrollado con fines educativos.
''',
    );
  }

  Future<void> _registrarse() async {
    if (_registrando) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_aceptoTerminos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debés aceptar los términos y la política de privacidad.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _registrando = true;
    });

    // El mismo correo normalizado se utiliza en ambos servicios.
    final emailNormalizado = _emailController.text.trim().toLowerCase();

    try {
      final credencial = await AuthService().registrarUsuario(
        email: emailNormalizado,
        password: _passwordController.text,
      );

      final usuario = credencial.user;

      if (usuario == null) {
        throw Exception('No se pudo obtener el usuario creado.');
      }

      final usuarioActual = FirebaseAuth.instance.currentUser;

      debugPrint('UID del usuario creado: ${usuario.uid}');
      debugPrint('UID del usuario autenticado: ${usuarioActual?.uid}');
      debugPrint('Email autenticado: ${usuarioActual?.email}');
      debugPrint('Email enviado a Firestore: $emailNormalizado');

      await UsuarioService().crearUsuario(
        uid: usuario.uid,
        nombre: _nombreController.text.trim(),
        email: emailNormalizado,
        rol: _rolSeleccionado,
        aceptoTerminos: _aceptoTerminos,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cuenta creada correctamente.'),
        ),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      debugPrint('ERROR DE FIREBASE AUTH: ${e.code} - ${e.message}');

      String mensaje = 'No se pudo crear la cuenta.';

      if (e.code == 'email-already-in-use') {
        mensaje = 'Ese correo ya está registrado.';
      } else if (e.code == 'invalid-email') {
        mensaje = 'El correo electrónico no es válido.';
      } else if (e.code == 'weak-password') {
        mensaje = 'La contraseña es demasiado débil.';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje)),
      );
    } catch (e) {
      debugPrint('ERROR AL REGISTRAR USUARIO: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          duration: const Duration(seconds: 10),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _registrando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta'),
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
                const Icon(
                  Icons.pets,
                  size: 75,
                ),
                const SizedBox(height: 15),
                const Text(
                  'Crear una cuenta',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Elegí qué tipo de usuario sos',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 25),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment<String>(
                      value: 'adoptante',
                      label: Text('Adoptante'),
                      icon: Icon(Icons.person),
                    ),
                    ButtonSegment<String>(
                      value: 'refugio',
                      label: Text('Refugio'),
                      icon: Icon(Icons.home),
                    ),
                  ],
                  selected: {_rolSeleccionado},
                  onSelectionChanged: _registrando
                      ? null
                      : (Set<String> nuevoRol) {
                          setState(() {
                            _rolSeleccionado = nuevoRol.first;
                          });
                        },
                ),
                const SizedBox(height: 25),
                TextFormField(
                  controller: _nombreController,
                  enabled: !_registrando,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresá tu nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _emailController,
                  enabled: !_registrando,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresá tu correo electrónico';
                    }
                    if (!value.contains('@')) {
                      return 'Ingresá un correo válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _passwordController,
                  enabled: !_registrando,
                  obscureText: _ocultarPassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: _registrando
                          ? null
                          : () {
                              setState(() {
                                _ocultarPassword = !_ocultarPassword;
                              });
                            },
                      icon: Icon(
                        _ocultarPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresá una contraseña';
                    }
                    if (value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _confirmarPasswordController,
                  enabled: !_registrando,
                  obscureText: _ocultarConfirmacion,
                  decoration: InputDecoration(
                    labelText: 'Confirmar contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: _registrando
                          ? null
                          : () {
                              setState(() {
                                _ocultarConfirmacion =
                                    !_ocultarConfirmacion;
                              });
                            },
                      icon: Icon(
                        _ocultarConfirmacion
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirmá tu contraseña';
                    }
                    if (value != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
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
                        onChanged: _registrando
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
                            onPressed: _verTerminos,
                            icon: const Icon(
                              Icons.description_outlined,
                              size: 18,
                            ),
                            label: const Text('Ver términos'),
                          ),
                          TextButton.icon(
                            onPressed: _verPrivacidad,
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
                    onPressed: _registrando ? null : _registrarse,
                    child: _registrando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Crear cuenta',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _registrando
                      ? null
                      : () {
                          Navigator.pop(context);
                        },
                  child: const Text('Ya tengo una cuenta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
