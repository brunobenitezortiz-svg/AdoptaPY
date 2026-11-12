import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

// ==========================================
// DOCUMENTOS LEGALES DE ADOPTAPY
// ==========================================

class DocumentosLegales {
  // ========================================
  // TERMINOS DE USO
  // ========================================

  static const String terminos = '''
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
''';

  // ========================================
  // POLITICA DE PRIVACIDAD
  // ========================================

  static const String privacidad = '''
POLÍTICA DE PRIVACIDAD — ADOPTA MASCOTAS

1. Información recopilada

La aplicación solicita nombre, correo electrónico, contraseña y tipo de usuario durante el registro tradicional.

Cuando se utiliza Google, la aplicación recibe información básica de la cuenta, como nombre y correo electrónico, sin solicitar una contraseña.

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
''';

  // ========================================
  // ESTILO DE LOS PARRAFOS LEGALES
  // ========================================

  static Widget _construirParrafo(String contenido) {
    final texto = contenido.trim();

    final esTituloPrincipal =
        texto.startsWith('TÉRMINOS DE USO') ||
        texto.startsWith('POLÍTICA DE PRIVACIDAD');

    final esTituloSeccion = RegExp(r'^\d+\.\s').hasMatch(texto);

    if (esTituloPrincipal) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          texto,
          style: GoogleFonts.quicksand(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            height: 1.5,
          ),
        ),
      );
    }

    if (esTituloSeccion) {
      return Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 2),
        child: Text(
          texto,
          style: GoogleFonts.quicksand(
            color: AppColors.ink,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            height: 1.45,
          ),
        ),
      );
    }

    return Text(
      texto,
      style: GoogleFonts.quicksand(
        color: AppColors.muted,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.75,
      ),
    );
  }

  // ========================================
  // VENTANA DE DOCUMENTOS LEGALES
  // ========================================

  static void mostrar(
    BuildContext context, {
    required String titulo,
    required String contenido,
  }) {
    final esPrivacidad = titulo == 'Política de privacidad';

    final parrafos = contenido.trim().split(RegExp(r'\n\s*\n'));

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final alturaPantalla = MediaQuery.sizeOf(dialogContext).height;

        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,

          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 20,
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: const BorderSide(color: AppColors.border),
          ),

          titlePadding: const EdgeInsets.fromLTRB(22, 23, 22, 0),

          contentPadding: const EdgeInsets.fromLTRB(22, 18, 22, 6),

          actionsPadding: const EdgeInsets.fromLTRB(22, 13, 22, 20),

          // ==================================
          // ENCABEZADO
          // ==================================
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,

                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.celeste, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),

                child: Icon(
                  esPrivacidad
                      ? Icons.shield_outlined
                      : Icons.description_outlined,
                  color: Colors.white,
                  size: 25,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: GoogleFonts.quicksand(
                        color: AppColors.ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      'Información de AdoptaPY',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                tooltip: 'Cerrar documento',
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                icon: const Icon(Icons.close_rounded, color: AppColors.muted),
              ),
            ],
          ),

          // ==================================
          // CONTENIDO DEL DOCUMENTO
          // ==================================
          content: SizedBox(
            width: 490,

            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: alturaPantalla * 0.57),

              child: SingleChildScrollView(
                child: SelectionArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ETIQUETA INFORMATIVA
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(15),

                        decoration: BoxDecoration(
                          color: AppColors.azulSuave,
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(color: AppColors.border),
                        ),

                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              esPrivacidad
                                  ? Icons.lock_outline_rounded
                                  : Icons.info_outline_rounded,
                              color: AppColors.primary,
                              size: 21,
                            ),

                            const SizedBox(width: 11),

                            Expanded(
                              child: Text(
                                esPrivacidad
                                    ? 'Conocé cómo se utiliza '
                                          'y protege la información '
                                          'dentro de AdoptaPY.'
                                    : 'Conocé las condiciones '
                                          'y responsabilidades '
                                          'de uso de AdoptaPY.',
                                style: const TextStyle(
                                  color: AppColors.ink,
                                  fontSize: 12,
                                  height: 1.55,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 23),

                      // DOCUMENTO COMPLETO
                      for (final parrafo in parrafos) ...[
                        _construirParrafo(parrafo),
                        const SizedBox(height: 13),
                      ],

                      const SizedBox(height: 2),

                      // MENSAJE INFERIOR
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),

                        decoration: BoxDecoration(
                          color: AppColors.azulSuave,
                          borderRadius: BorderRadius.circular(16),
                        ),

                        child: const Row(
                          children: [
                            Icon(
                              Icons.favorite_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),

                            SizedBox(width: 11),

                            Expanded(
                              child: Text(
                                'AdoptaPY · Un hogar '
                                'para cada huellita.',
                                style: TextStyle(
                                  color: AppColors.primaryDark,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
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

          // ==================================
          // BOTON DE CIERRE
          // ==================================
          actions: [
            SizedBox(
              width: double.infinity,
              height: 49,

              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },

                icon: const Icon(Icons.check_rounded, size: 20),

                label: const Text(
                  'Entendido',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ========================================
  // MOSTRAR TERMINOS DE USO
  // ========================================

  static void mostrarTerminos(BuildContext context) {
    mostrar(context, titulo: 'Términos de uso', contenido: terminos);
  }

  // ========================================
  // MOSTRAR POLITICA DE PRIVACIDAD
  // ========================================

  static void mostrarPrivacidad(BuildContext context) {
    mostrar(context, titulo: 'Política de privacidad', contenido: privacidad);
  }
}
