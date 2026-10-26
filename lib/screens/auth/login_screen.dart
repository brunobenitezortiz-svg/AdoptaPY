
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/auth_service.dart';
import '../../services/usuario_service.dart';
import '../adoptante/home_screen.dart';
import '../refugio/dashboard_screen.dart';
import 'registro_screen.dart';
import 'registro_google_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _ocultarPassword = true;
  bool _iniciandoGoogle = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final credencial = await AuthService().iniciarSesion(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final usuario = credencial.user;

      if (usuario == null) {
        throw Exception('No se pudo obtener el usuario.');
      }

      final documento =
          await UsuarioService().obtenerUsuario(usuario.uid);

      if (!documento.exists) {
        throw Exception('No se encontraron los datos del usuario.');
      }

      final datos = documento.data();
      final rol = datos?['rol'];

      if (rol == null) {
        throw Exception('El usuario no tiene un rol asignado.');
      }

      if (!mounted) return;

      if (rol == 'adoptante') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      } else if (rol == 'refugio') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DashboardScreen(),
          ),
        );
      } else {
        await AuthService().cerrarSesion();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El usuario tiene un rol no válido.'),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String mensaje = 'No se pudo iniciar sesión.';

      if (e.code == 'user-not-found') {
        mensaje = 'No existe una cuenta con ese correo.';
      } else if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        mensaje = 'El correo o la contraseña son incorrectos.';
      } else if (e.code == 'invalid-email') {
        mensaje = 'El correo electrónico no es válido.';
      } else if (e.code == 'user-disabled') {
        mensaje = 'Esta cuenta está deshabilitada.';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudieron obtener los datos del usuario.',
          ),
        ),
      );
    }
  }

  Future<void> _iniciarSesionConGoogle() async {
    if (_iniciandoGoogle) return;

    setState(() {
      _iniciandoGoogle = true;
    });

    try {
      final credencial =
          await AuthService().iniciarSesionConGoogle();

      final usuario = credencial.user;

      if (usuario == null) {
        throw Exception('No se pudo obtener la cuenta de Google.');
      }

      final documento =
          await UsuarioService().obtenerUsuario(usuario.uid);

      if (!mounted) return;

      if (!documento.exists) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const RegistroGoogleScreen(),
          ),
        );
        return;
      }

      final rol = documento.data()?['rol'];

      if (rol == 'adoptante') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const HomeScreen(),
          ),
          (route) => false,
        );
      } else if (rol == 'refugio') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const DashboardScreen(),
          ),
          (route) => false,
        );
      } else {
        await AuthService().cerrarSesion();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'La cuenta tiene un rol no válido.',
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request') {
        return;
      }

      String mensaje = 'No se pudo iniciar sesión con Google.';

      if (e.code == 'account-exists-with-different-credential') {
        mensaje =
            'Ya existe una cuenta con este correo. '
            'Iniciá sesión con tu método habitual.';
      } else if (e.code == 'popup-blocked') {
        mensaje =
            'El navegador bloqueó la ventana de Google. '
            'Permití las ventanas emergentes.';
      } else if (e.code == 'unauthorized-domain') {
        mensaje =
            'Este dominio no está autorizado en Firebase.';
      } else if (e.code == 'network-request-failed') {
        mensaje = 'Verificá tu conexión a Internet.';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      debugPrint('Error de Google Authentication: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ocurrió un error al iniciar sesión con Google.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _iniciandoGoogle = false;
        });
      }
    }
  }

  Future<void> _recuperarPassword() async {
    final correoController = TextEditingController(
      text: _emailController.text.trim(),
    );

    bool enviando = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, actualizarDialogo) {
            return AlertDialog(
              title: const Text('Recuperar contraseña'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ingresá el correo electrónico asociado a tu '
                    'cuenta. Te enviaremos un enlace para '
                    'restablecer tu contraseña.',
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: correoController,
                    enabled: !enviando,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: enviando
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                        },
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: enviando
                      ? null
                      : () async {
                          final correo =
                              correoController.text.trim();

                          final formatoCorreo = RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          );

                          if (!formatoCorreo.hasMatch(correo)) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Ingresá un correo electrónico válido.',
                                ),
                              ),
                            );
                            return;
                          }

                          actualizarDialogo(() {
                            enviando = true;
                          });

                          try {
                            await FirebaseAuth.instance
                                .sendPasswordResetEmail(
                              email: correo,
                            );

                            if (!dialogContext.mounted) return;

                            Navigator.pop(dialogContext);

                            if (!mounted) return;

                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Si existe una cuenta asociada '
                                  'a ese correo, recibirás un '
                                  'enlace para recuperar tu contraseña.',
                                ),
                                duration: Duration(seconds: 6),
                              ),
                            );
                          } on FirebaseAuthException catch (e) {
                            if (!dialogContext.mounted) return;

                            String mensaje =
                                'No se pudo enviar el correo. '
                                'Intentá nuevamente.';

                            if (e.code == 'invalid-email') {
                              mensaje =
                                  'El correo electrónico no es válido.';
                            } else if (e.code ==
                                'too-many-requests') {
                              mensaje =
                                  'Demasiados intentos. '
                                  'Esperá unos minutos.';
                            } else if (e.code ==
                                'network-request-failed') {
                              mensaje =
                                  'Verificá tu conexión a Internet.';
                            }

                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(content: Text(mensaje)),
                            );

                            actualizarDialogo(() {
                              enviando = false;
                            });
                          } catch (e) {
                            if (!dialogContext.mounted) return;

                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Ocurrió un error al intentar '
                                  'recuperar la contraseña.',
                                ),
                              ),
                            );

                            actualizarDialogo(() {
                              enviando = false;
                            });
                          }
                        },
                  child: enviando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Enviar enlace'),
                ),
              ],
            );
          },
        );
      },
    );

    await Future<void>.delayed(
      const Duration(milliseconds: 300),
    );

    correoController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar sesión'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 30),
                const Icon(
                  Icons.pets,
                  size: 80,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Bienvenido a Adopta Mascotas',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Iniciá sesión para continuar',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 35),
                TextFormField(
                  controller: _emailController,
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
                  obscureText: _ocultarPassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () {
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
                      return 'Ingresá tu contraseña';
                    }

                    if (value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _recuperarPassword,
                    child: const Text(
                      '¿Olvidaste tu contraseña?',
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _iniciarSesion,
                    child: const Text(
                      'Iniciar sesión',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                OutlinedButton.icon(
                  onPressed: _iniciandoGoogle
                      ? null
                      : _iniciarSesionConGoogle,
                  icon: _iniciandoGoogle
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.login),
                  label: Text(
                    _iniciandoGoogle
                        ? 'Conectando con Google...'
                        : 'Continuar con Google',
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('¿No tenés una cuenta?'),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const RegistroScreen(),
                          ),
                        );
                      },
                      child: const Text('Registrate'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
