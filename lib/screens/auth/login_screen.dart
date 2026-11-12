import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/adopta_widgets.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/usuario_service.dart';
import '../adoptante/home_screen.dart';
import '../refugio/dashboard_screen.dart';
import 'registro_screen.dart';
import 'registro_google_screen.dart';

// ==========================================
// PANTALLA DE INICIO DE SESION
// ==========================================

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
  bool _iniciandoSesion = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ========================================
  // INICIO DE SESION CON CORREO
  // ========================================

  Future<void> _iniciarSesion() async {
    if (_iniciandoSesion || _iniciandoGoogle) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _iniciandoSesion = true;
    });

    try {
      final credencial = await AuthService().iniciarSesion(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final usuario = credencial.user;

      if (usuario == null) {
        throw Exception('No se pudo obtener el usuario.');
      }

      final documento = await UsuarioService().obtenerUsuario(usuario.uid);

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
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else if (rol == 'refugio') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      } else {
        await AuthService().cerrarSesion();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El usuario tiene un rol no válido.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      String mensaje = 'No se pudo iniciar sesión.';

      if (e.code == 'user-not-found') {
        mensaje = 'No existe una cuenta con ese correo.';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        mensaje = 'El correo o la contraseña son incorrectos.';
      } else if (e.code == 'invalid-email') {
        mensaje = 'El correo electrónico no es válido.';
      } else if (e.code == 'user-disabled') {
        mensaje = 'Esta cuenta está deshabilitada.';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensaje)));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudieron obtener los datos del usuario.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _iniciandoSesion = false;
        });
      }
    }
  }

  // ========================================
  // INICIO DE SESION CON GOOGLE
  // ========================================

  Future<void> _iniciarSesionConGoogle() async {
    if (_iniciandoGoogle || _iniciandoSesion) return;

    setState(() {
      _iniciandoGoogle = true;
    });

    try {
      final credencial = await AuthService().iniciarSesionConGoogle();

      final usuario = credencial.user;

      if (usuario == null) {
        throw Exception('No se pudo obtener la cuenta de Google.');
      }

      final documento = await UsuarioService().obtenerUsuario(usuario.uid);

      if (!mounted) return;

      if (!documento.exists) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const RegistroGoogleScreen()),
        );
        return;
      }

      final rol = documento.data()?['rol'];

      if (rol == 'adoptante') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else if (rol == 'refugio') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
        );
      } else {
        await AuthService().cerrarSesion();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La cuenta tiene un rol no válido.')),
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
        mensaje = 'Este dominio no está autorizado en Firebase.';
      } else if (e.code == 'network-request-failed') {
        mensaje = 'Verificá tu conexión a Internet.';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje), duration: const Duration(seconds: 6)),
      );
    } catch (e) {
      debugPrint('Error de Google Authentication: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ocurrió un error al iniciar sesión con Google.'),
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

  // ========================================
  // RECUPERACION DE CONTRASEÑA
  // ========================================

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
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 25, 24, 0),
              contentPadding: const EdgeInsets.fromLTRB(24, 17, 24, 8),
              actionsPadding: const EdgeInsets.fromLTRB(20, 6, 20, 20),

              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 55,
                    height: 55,
                    decoration: BoxDecoration(
                      color: AppColors.azulPastel,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    'Recuperar contraseña',
                    style: GoogleFonts.quicksand(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ingresá el correo electrónico asociado '
                      'a tu cuenta. Te enviaremos un enlace '
                      'para restablecer tu contraseña.',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 22),

                    TextField(
                      controller: correoController,
                      enabled: !enviando,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        hintText: 'ejemplo@correo.com',
                        prefixIcon: Icon(Icons.alternate_email_rounded),
                      ),
                    ),
                  ],
                ),
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
                          final correo = correoController.text.trim();

                          final formatoCorreo = RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          );

                          if (!formatoCorreo.hasMatch(correo)) {
                            ScaffoldMessenger.of(context).showSnackBar(
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
                            await FirebaseAuth.instance.sendPasswordResetEmail(
                              email: correo,
                            );

                            if (!dialogContext.mounted) return;

                            Navigator.pop(dialogContext);

                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
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
                              mensaje = 'El correo electrónico no es válido.';
                            } else if (e.code == 'too-many-requests') {
                              mensaje =
                                  'Demasiados intentos. '
                                  'Esperá unos minutos.';
                            } else if (e.code == 'network-request-failed') {
                              mensaje = 'Verificá tu conexión a Internet.';
                            }

                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text(mensaje)));

                            actualizarDialogo(() {
                              enviando = false;
                            });
                          } catch (e) {
                            if (!dialogContext.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
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
                            color: Colors.white,
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

    await Future<void>.delayed(const Duration(milliseconds: 300));

    correoController.dispose();
  }

  // ========================================
  // INTERFAZ DEL LOGIN
  // ========================================

  @override
  Widget build(BuildContext context) {
    final procesando = _iniciandoSesion || _iniciandoGoogle;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,

      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEAF7FF),
              AppColors.background,
              Color(0xFFFFFFFF),
            ],
          ),
        ),

        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 28),

              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // LOGOTIPO PRINCIPAL
                    const Center(child: BrandLogo()),

                    const SizedBox(height: 29),

                    // BANNER DE BIENVENIDA
                    const _LoginBanner()
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideY(
                          begin: 0.07,
                          end: 0,
                          duration: 500.ms,
                          curve: Curves.easeOutCubic,
                        ),

                    const SizedBox(height: 28),

                    // ENCABEZADO
                    Text(
                      '¡Qué bueno verte!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.quicksand(
                        color: AppColors.ink,
                        fontSize: 29,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Iniciá sesión para continuar '
                      'tu historia con AdoptaPY.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 26),

                    // TARJETA DEL FORMULARIO
                    Container(
                      padding: const EdgeInsets.all(22),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppColors.border),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x10164E86),
                            blurRadius: 24,
                            offset: Offset(0, 9),
                          ),
                        ],
                      ),

                      child: Form(
                        key: _formKey,

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ENCABEZADO DEL FORMULARIO
                            Row(
                              children: [
                                Container(
                                  width: 37,
                                  height: 37,
                                  decoration: BoxDecoration(
                                    color: AppColors.azulPastel,
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: const Icon(
                                    Icons.waving_hand_rounded,
                                    color: AppColors.primary,
                                    size: 21,
                                  ),
                                ),

                                const SizedBox(width: 11),

                                Expanded(
                                  child: Text(
                                    'Accedé a tu cuenta',
                                    style: GoogleFonts.quicksand(
                                      color: AppColors.ink,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // CORREO ELECTRONICO
                            Text(
                              'Correo electrónico',
                              style: GoogleFonts.quicksand(
                                color: AppColors.ink,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            const SizedBox(height: 9),

                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              autocorrect: false,
                              decoration: const InputDecoration(
                                hintText: 'ejemplo@correo.com',
                                prefixIcon: Icon(Icons.alternate_email_rounded),
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

                            const SizedBox(height: 21),

                            // CONTRASEÑA
                            Text(
                              'Contraseña',
                              style: GoogleFonts.quicksand(
                                color: AppColors.ink,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            const SizedBox(height: 9),

                            TextFormField(
                              controller: _passwordController,
                              obscureText: _ocultarPassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],

                              decoration: InputDecoration(
                                hintText: 'Ingresá tu contraseña',
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                ),
                                suffixIcon: IconButton(
                                  tooltip: _ocultarPassword
                                      ? 'Mostrar contraseña'
                                      : 'Ocultar contraseña',
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

                            const SizedBox(height: 8),

                            // RECUPERAR CONTRASEÑA
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: procesando
                                    ? null
                                    : _recuperarPassword,
                                child: const Text(
                                  '¿Olvidaste tu contraseña?',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),

                            const SizedBox(height: 13),

                            // BOTON INICIAR SESION
                            SizedBox(
                              width: double.infinity,
                              height: 56,

                              child: FilledButton(
                                onPressed: procesando ? null : _iniciarSesion,

                                child: _iniciandoSesion
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text('Iniciar sesión'),
                                          SizedBox(width: 10),
                                          Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 21,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // SEPARADOR
                    const Row(
                      children: [
                        Expanded(child: Divider(color: AppColors.border)),

                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15),
                          child: Text(
                            'O CONTINUÁ CON',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),

                        Expanded(child: Divider(color: AppColors.border)),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // BOTON GOOGLE
                    SizedBox(
                      width: double.infinity,
                      height: 56,

                      child: OutlinedButton(
                        onPressed: procesando ? null : _iniciarSesionConGoogle,

                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.ink,
                          side: const BorderSide(
                            color: AppColors.border,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(19),
                          ),
                        ),

                        child: _iniciandoGoogle
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 19,
                                    width: 19,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Flexible(
                                    child: Text('Conectando con Google...'),
                                  ),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _GoogleMonograma(),
                                  SizedBox(width: 12),
                                  Text(
                                    'Continuar con Google',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 27),

                    // REGISTRO DE USUARIOS
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 2,
                      children: [
                        const Text(
                          '¿Todavía no tenés una cuenta?',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                          ),
                        ),

                        TextButton(
                          onPressed: procesando
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const RegistroScreen(),
                                    ),
                                  );
                                },

                          child: const Text(
                            'Registrate',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 19),

                    // MENSAJE FINAL
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_rounded,
                          color: AppColors.celeste,
                          size: 15,
                        ),

                        SizedBox(width: 7),

                        Flexible(
                          child: Text(
                            'Cada huellita merece una oportunidad.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                  ],
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
// BANNER DECORATIVO DEL LOGIN
// ==========================================

class _LoginBanner extends StatelessWidget {
  const _LoginBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 172,

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF71CAF6), Color(0xFF398ED5), Color(0xFF246DB8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),

        boxShadow: const [
          BoxShadow(
            color: Color(0x2756B8F2),
            blurRadius: 23,
            offset: Offset(0, 10),
          ),
        ],
      ),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),

        child: Stack(
          children: [
            // CIRCULO SUPERIOR
            Positioned(
              right: -39,
              top: -75,
              child: Container(
                width: 205,
                height: 205,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x20FFFFFF),
                ),
              ),
            ),

            // CIRCULO INFERIOR
            Positioned(
              right: 30,
              bottom: -100,
              child: Container(
                width: 195,
                height: 195,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x16FFFFFF),
                ),
              ),
            ),

            // HUELLA DECORATIVA
            const Positioned(
              right: 7,
              bottom: 1,
              child: Icon(
                Icons.pets_rounded,
                size: 118,
                color: Color(0x28FFFFFF),
              ),
            ),

            // CONTENIDO
            Padding(
              padding: const EdgeInsets.all(23),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.favorite_rounded,
                          color: Colors.white,
                          size: 14,
                        ),

                        SizedBox(width: 7),

                        Text(
                          'UN AMIGO TE ESPERA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bienvenido a casa.',
                        style: GoogleFonts.quicksand(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        'Las mejores historias tienen huellitas.',
                        style: TextStyle(
                          color: Color(0xFFF0FAFF),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// SIMBOLO DEL BOTON GOOGLE
// ==========================================

class _GoogleMonograma extends StatelessWidget {
  const _GoogleMonograma();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 27,
      height: 27,

      alignment: Alignment.center,

      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
      ),

      child: Text(
        'G',
        style: GoogleFonts.roboto(
          color: const Color(0xFF4285F4),
          fontSize: 17,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
