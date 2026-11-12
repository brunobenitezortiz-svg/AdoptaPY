import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/adopta_widgets.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/usuario_service.dart';

// ==========================================
// PANTALLA DE REGISTRO
// ==========================================

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

  // ========================================
  // VISUALIZACION DE DOCUMENTOS LEGALES
  // ========================================

  void _mostrarDocumento({required String titulo, required String contenido}) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.azulPastel,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: AppColors.primary,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titulo,
                  style: GoogleFonts.quicksand(
                    color: AppColors.ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Text(
                contenido,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.ink,
                  height: 1.65,
                ),
              ),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  // ========================================
  // TERMINOS DE USO
  // ========================================

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

  // ========================================
  // POLITICA DE PRIVACIDAD
  // ========================================

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

  // ========================================
  // REGISTRO DE USUARIOS CON FIREBASE
  // ========================================

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
          backgroundColor: AppColors.error,
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
        const SnackBar(content: Text('Cuenta creada correctamente.')),
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

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensaje)));
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

  // ========================================
  // INTERFAZ DE REGISTRO
  // ========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Crear cuenta')),
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
              padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 23),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // LOGOTIPO
                      const Center(child: BrandLogo()),

                      const SizedBox(height: 25),

                      // BANNER
                      const _RegistroBanner()
                          .animate()
                          .fadeIn(duration: 450.ms)
                          .slideY(begin: 0.06, end: 0, duration: 450.ms),

                      const SizedBox(height: 25),

                      // TITULO
                      Text(
                        'Una nueva historia comienza acá.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.quicksand(
                          color: AppColors.ink,
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                          height: 1.18,
                          letterSpacing: -0.8,
                        ),
                      ),

                      const SizedBox(height: 11),

                      const Text(
                        'Sumate a nuestra comunidad '
                        'y ayudanos a cambiar vidas.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 14,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 27),

                      // SELECCION DE TIPO DE CUENTA
                      Text(
                        '¿Cómo querés participar?',
                        style: GoogleFonts.quicksand(
                          color: AppColors.ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 7),

                      const Text(
                        'Elegí el tipo de cuenta que mejor '
                        'se adapte a vos.',
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _RolOpcion(
                              icono: Icons.favorite_rounded,
                              titulo: 'Adoptante',
                              descripcion: 'Quiero adoptar',
                              seleccionado: _rolSeleccionado == 'adoptante',
                              habilitado: !_registrando,
                              onTap: () {
                                setState(() {
                                  _rolSeleccionado = 'adoptante';
                                });
                              },
                            ),
                          ),

                          const SizedBox(width: 11),

                          Expanded(
                            child: _RolOpcion(
                              icono: Icons.home_rounded,
                              titulo: 'Refugio',
                              descripcion: 'Quiero ayudar',
                              seleccionado: _rolSeleccionado == 'refugio',
                              habilitado: !_registrando,
                              onTap: () {
                                setState(() {
                                  _rolSeleccionado = 'refugio';
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 26),

                      // TARJETA DEL FORMULARIO
                      Container(
                        padding: const EdgeInsets.all(21),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(27),
                          border: Border.all(color: AppColors.border),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x10164E86),
                              blurRadius: 23,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // TITULO DEL FORMULARIO
                            Row(
                              children: [
                                Container(
                                  width: 39,
                                  height: 39,
                                  decoration: BoxDecoration(
                                    color: AppColors.azulPastel,
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: const Icon(
                                    Icons.person_add_alt_1_rounded,
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                                ),

                                const SizedBox(width: 11),

                                Expanded(
                                  child: Text(
                                    'Tus datos personales',
                                    style: GoogleFonts.quicksand(
                                      color: AppColors.ink,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 23),

                            // NOMBRE
                            _EtiquetaCampo(
                              texto: _rolSeleccionado == 'refugio'
                                  ? 'Nombre del refugio'
                                  : 'Nombre completo',
                            ),

                            const SizedBox(height: 8),

                            TextFormField(
                              controller: _nombreController,
                              enabled: !_registrando,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.name],
                              decoration: InputDecoration(
                                hintText: _rolSeleccionado == 'refugio'
                                    ? 'Nombre de tu refugio'
                                    : 'Tu nombre y apellido',
                                prefixIcon: Icon(
                                  _rolSeleccionado == 'refugio'
                                      ? Icons.home_outlined
                                      : Icons.person_outline_rounded,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Ingresá tu nombre';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 20),

                            // CORREO ELECTRONICO
                            const _EtiquetaCampo(texto: 'Correo electrónico'),

                            const SizedBox(height: 8),

                            TextFormField(
                              controller: _emailController,
                              enabled: !_registrando,
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

                            const SizedBox(height: 20),

                            // CONTRASEÑA
                            const _EtiquetaCampo(texto: 'Contraseña'),

                            const SizedBox(height: 8),

                            TextFormField(
                              controller: _passwordController,
                              enabled: !_registrando,
                              obscureText: _ocultarPassword,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.newPassword],
                              decoration: InputDecoration(
                                hintText: 'Mínimo 6 caracteres',
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                ),
                                suffixIcon: IconButton(
                                  tooltip: _ocultarPassword
                                      ? 'Mostrar contraseña'
                                      : 'Ocultar contraseña',
                                  onPressed: _registrando
                                      ? null
                                      : () {
                                          setState(() {
                                            _ocultarPassword =
                                                !_ocultarPassword;
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

                            const SizedBox(height: 20),

                            // CONFIRMAR CONTRASEÑA
                            const _EtiquetaCampo(texto: 'Confirmar contraseña'),

                            const SizedBox(height: 8),

                            TextFormField(
                              controller: _confirmarPasswordController,
                              enabled: !_registrando,
                              obscureText: _ocultarConfirmacion,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.newPassword],
                              decoration: InputDecoration(
                                hintText: 'Repetí tu contraseña',
                                prefixIcon: const Icon(
                                  Icons.verified_user_outlined,
                                ),
                                suffixIcon: IconButton(
                                  tooltip: _ocultarConfirmacion
                                      ? 'Mostrar contraseña'
                                      : 'Ocultar contraseña',
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
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      // TERMINOS Y PRIVACIDAD
                      Container(
                        padding: const EdgeInsets.all(17),
                        decoration: BoxDecoration(
                          color: AppColors.azulSuave,
                          borderRadius: BorderRadius.circular(23),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.shield_outlined,
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                                ),

                                const SizedBox(width: 11),

                                Expanded(
                                  child: Text(
                                    'Tu privacidad importa',
                                    style: GoogleFonts.quicksand(
                                      color: AppColors.ink,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              activeColor: AppColors.primary,
                              checkColor: Colors.white,
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
                                style: TextStyle(
                                  color: AppColors.ink,
                                  fontSize: 13,
                                  height: 1.45,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            const SizedBox(height: 3),

                            Wrap(
                              spacing: 8,
                              runSpacing: 5,
                              children: [
                                TextButton.icon(
                                  onPressed: _verTerminos,
                                  icon: const Icon(
                                    Icons.description_outlined,
                                    size: 17,
                                  ),
                                  label: const Text(
                                    'Ver términos',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),

                                TextButton.icon(
                                  onPressed: _verPrivacidad,
                                  icon: const Icon(
                                    Icons.privacy_tip_outlined,
                                    size: 17,
                                  ),
                                  label: const Text(
                                    'Ver privacidad',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      // BOTON CREAR CUENTA
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: FilledButton(
                          onPressed: _registrando ? null : _registrarse,
                          child: _registrando
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Crear mi cuenta'),
                                    SizedBox(width: 10),
                                    Icon(Icons.arrow_forward_rounded, size: 21),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // VOLVER AL LOGIN
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 3,
                        children: [
                          const Text(
                            '¿Ya tenés una cuenta?',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                            ),
                          ),

                          TextButton(
                            onPressed: _registrando
                                ? null
                                : () {
                                    Navigator.pop(context);
                                  },
                            child: const Text(
                              'Iniciá sesión',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      // MENSAJE INFERIOR
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
                              'Juntos podemos cambiar muchas vidas.',
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
// BANNER SUPERIOR DEL REGISTRO
// ==========================================

class _RegistroBanner extends StatelessWidget {
  const _RegistroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 157,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF70C9F5), Color(0xFF3F9CDD), Color(0xFF246CB7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(29),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2756B8F2),
            blurRadius: 22,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(29),
        child: Stack(
          children: [
            Positioned(
              top: -55,
              right: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x20FFFFFF),
                ),
              ),
            ),

            Positioned(
              right: 10,
              bottom: -3,
              child: const Icon(
                Icons.pets_rounded,
                size: 117,
                color: Color(0x28FFFFFF),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x33FFFFFF),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.favorite_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                        SizedBox(width: 7),
                        Text(
                          'BIENVENIDO A ADOPTAPY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cada huellita cuenta.',
                        style: GoogleFonts.quicksand(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Tu historia con ellos empieza hoy.',
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
// OPCIONES DE ROL
// ==========================================

class _RolOpcion extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String descripcion;
  final bool seleccionado;
  final bool habilitado;
  final VoidCallback onTap;

  const _RolOpcion({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.seleccionado,
    required this.habilitado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: seleccionado ? AppColors.azulSuave : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: seleccionado ? AppColors.primary : AppColors.border,
          width: seleccionado ? 1.8 : 1,
        ),
        boxShadow: seleccionado
            ? const [
                BoxShadow(
                  color: Color(0x1256B8F2),
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: habilitado ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 17),
            child: Column(
              children: [
                Container(
                  width: 49,
                  height: 49,
                  decoration: BoxDecoration(
                    color: seleccionado
                        ? AppColors.azulPastel
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icono,
                    size: 25,
                    color: seleccionado ? AppColors.primary : AppColors.muted,
                  ),
                ),

                const SizedBox(height: 11),

                Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  descripcion,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),

                const SizedBox(height: 11),

                Icon(
                  seleccionado
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 21,
                  color: seleccionado ? AppColors.primary : AppColors.border,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// ETIQUETA DE CAMPOS
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
