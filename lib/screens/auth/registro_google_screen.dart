import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/adopta_widgets.dart';
import '../../theme/app_theme.dart';
import '../../services/usuario_service.dart';
import '../adoptante/home_screen.dart';
import '../refugio/dashboard_screen.dart';
import 'documentos_legales.dart';

// ==========================================
// REGISTRO CON GOOGLE
// ==========================================

class RegistroGoogleScreen extends StatefulWidget {
  const RegistroGoogleScreen({super.key});

  @override
  State<RegistroGoogleScreen> createState() => _RegistroGoogleScreenState();
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

  // ========================================
  // COMPLETAR REGISTRO CON FIREBASE
  // ========================================

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

    setState(() {
      _guardando = true;
    });

    try {
      final usuario = FirebaseAuth.instance.currentUser;

      if (usuario == null || usuario.email == null) {
        throw Exception('No se encontró una cuenta de Google válida.');
      }

      final servicio = UsuarioService();

      final documento = await servicio.obtenerUsuario(usuario.uid);

      if (documento.exists) {
        throw Exception('Este usuario ya tiene un perfil registrado.');
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
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  // ========================================
  // INTERFAZ PRINCIPAL
  // ========================================

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(title: const Text('Completar registro')),

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

                      // BANNER DE BIENVENIDA
                      const _BannerRegistroGoogle()
                          .animate()
                          .fadeIn(duration: 450.ms)
                          .slideY(
                            begin: 0.06,
                            end: 0,
                            duration: 450.ms,
                            curve: Curves.easeOutCubic,
                          ),

                      const SizedBox(height: 26),

                      // TITULO PRINCIPAL
                      Text(
                        '¡Ya casi sos parte de la familia!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.quicksand(
                          color: AppColors.ink,
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          letterSpacing: -0.8,
                        ),
                      ),

                      const SizedBox(height: 11),

                      const Text(
                        'Tu cuenta de Google está conectada. '
                        'Solo necesitamos algunos datos '
                        'para comenzar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 14,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 27),

                      // TARJETA DE DATOS
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
                            // TITULO DE LA TARJETA
                            Row(
                              children: [
                                Container(
                                  width: 41,
                                  height: 41,
                                  decoration: BoxDecoration(
                                    color: AppColors.azulPastel,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.verified_user_rounded,
                                    color: AppColors.primary,
                                    size: 23,
                                  ),
                                ),

                                const SizedBox(width: 12),

                                Expanded(
                                  child: Text(
                                    'Tu información',
                                    style: GoogleFonts.quicksand(
                                      color: AppColors.ink,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 23),

                            // CORREO DE GOOGLE
                            const _EtiquetaRegistroGoogle(
                              texto: 'Correo de Google',
                            ),

                            const SizedBox(height: 9),

                            TextFormField(
                              initialValue: usuario?.email ?? '',
                              readOnly: true,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.alternate_email_rounded),
                                suffixIcon: Icon(
                                  Icons.verified_rounded,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),

                            const SizedBox(height: 9),

                            const Row(
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 15,
                                  color: AppColors.success,
                                ),

                                SizedBox(width: 7),

                                Expanded(
                                  child: Text(
                                    'Cuenta conectada con Google',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 23),

                            // NOMBRE
                            const _EtiquetaRegistroGoogle(
                              texto: 'Nombre completo',
                            ),

                            const SizedBox(height: 9),

                            TextFormField(
                              controller: _nombreController,
                              enabled: !_guardando,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.name],
                              decoration: const InputDecoration(
                                hintText: 'Tu nombre y apellido',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),

                              validator: (valor) {
                                if (valor == null || valor.trim().isEmpty) {
                                  return 'Ingresá tu nombre';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 10),

                            const Text(
                              'Este nombre aparecerá en tu perfil '
                              'de AdoptaPY.',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // SELECCION DE ROL
                      Text(
                        '¿Cómo querés participar?',
                        style: GoogleFonts.quicksand(
                          color: AppColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Elegí el tipo de cuenta que mejor '
                        'se adapte a vos.',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),

                      const SizedBox(height: 17),

                      Row(
                        children: [
                          // ADOPTANTE
                          Expanded(
                            child: _OpcionRolGoogle(
                              icono: Icons.favorite_rounded,
                              titulo: 'Adoptante',
                              descripcion: 'Quiero adoptar',
                              seleccionado: _rolSeleccionado == 'adoptante',
                              habilitado: !_guardando,
                              onTap: () {
                                setState(() {
                                  _rolSeleccionado = 'adoptante';
                                });
                              },
                            ),
                          ),

                          const SizedBox(width: 11),

                          // REFUGIO
                          Expanded(
                            child: _OpcionRolGoogle(
                              icono: Icons.home_rounded,
                              titulo: 'Refugio',
                              descripcion: 'Quiero ayudar',
                              seleccionado: _rolSeleccionado == 'refugio',
                              habilitado: !_guardando,
                              onTap: () {
                                setState(() {
                                  _rolSeleccionado = 'refugio';
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

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

                            const SizedBox(height: 11),

                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              activeColor: AppColors.primary,
                              checkColor: Colors.white,
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
                                style: TextStyle(
                                  color: AppColors.ink,
                                  fontSize: 13,
                                  height: 1.45,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            const SizedBox(height: 5),

                            Wrap(
                              spacing: 8,
                              runSpacing: 5,
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    DocumentosLegales.mostrarTerminos(context);
                                  },
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
                                  onPressed: () {
                                    DocumentosLegales.mostrarPrivacidad(
                                      context,
                                    );
                                  },
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

                      const SizedBox(height: 27),

                      // BOTON COMPLETAR REGISTRO
                      SizedBox(
                        width: double.infinity,
                        height: 58,

                        child: FilledButton(
                          onPressed: _guardando ? null : _completarRegistro,

                          child: _guardando
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
                                    Text('Completar mi registro'),
                                    SizedBox(width: 9),
                                    Icon(Icons.arrow_forward_rounded, size: 20),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 19),

                      // MENSAJE INFERIOR
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

                      const SizedBox(height: 18),
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
// BANNER DECORATIVO DE REGISTRO GOOGLE
// ==========================================

class _BannerRegistroGoogle extends StatelessWidget {
  const _BannerRegistroGoogle();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 167,

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF70C9F5), Color(0xFF3F9CDD), Color(0xFF246CB7)],
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
            // CIRCULO DECORATIVO
            Positioned(
              top: -65,
              right: -45,
              child: Container(
                width: 190,
                height: 190,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x20FFFFFF),
                ),
              ),
            ),

            // HUELLA
            const Positioned(
              right: 9,
              bottom: -5,
              child: Icon(
                Icons.pets_rounded,
                size: 120,
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
                      color: const Color(0x33FFFFFF),
                      borderRadius: BorderRadius.circular(100),
                    ),

                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          color: Colors.white,
                          size: 14,
                        ),

                        SizedBox(width: 7),

                        Text(
                          'UN PASO MÁS',
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
                        '¡Bienvenido a la familia!',
                        style: GoogleFonts.quicksand(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),

                      const SizedBox(height: 7),

                      const Text(
                        'Grandes historias comienzan con amor.',
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
// TARJETAS DE SELECCION DE ROL
// ==========================================

class _OpcionRolGoogle extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String descripcion;
  final bool seleccionado;
  final bool habilitado;
  final VoidCallback onTap;

  const _OpcionRolGoogle({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.seleccionado,
    required this.habilitado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: seleccionado,

      child: AnimatedContainer(
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
                  // ICONO
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

                  // TITULO
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

                  // DESCRIPCION
                  Text(
                    descripcion,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),

                  const SizedBox(height: 11),

                  // INDICADOR DE SELECCION
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
      ),
    );
  }
}

// ==========================================
// ETIQUETAS DE LOS CAMPOS
// ==========================================

class _EtiquetaRegistroGoogle extends StatelessWidget {
  final String texto;

  const _EtiquetaRegistroGoogle({required this.texto});

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
