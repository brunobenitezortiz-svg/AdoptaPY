
import 'package:flutter/material.dart';

class DocumentosLegales {
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

  static void mostrar(
    BuildContext context, {
    required String titulo,
    required String contenido,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
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
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  static void mostrarTerminos(BuildContext context) {
    mostrar(
      context,
      titulo: 'Términos de uso',
      contenido: terminos,
    );
  }

  static void mostrarPrivacidad(BuildContext context) {
    mostrar(
      context,
      titulo: 'Política de privacidad',
      contenido: privacidad,
    );
  }
}
