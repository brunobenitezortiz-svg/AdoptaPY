
const fs = require("node:fs");
const path = require("node:path");

const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require("@firebase/rules-unit-testing");

const {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  collection,
  getDocs,
  query,
  where,
  serverTimestamp,
} = require("firebase/firestore");

const PROJECT_ID = "adopta-mascotas-3fc97";
const RULES_PATH = path.resolve(__dirname, "..", "firestore.rules");

let testEnv;

async function main() {
  const rules = fs.readFileSync(RULES_PATH, "utf8");

  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules },
  });

  await testEnv.clearFirestore();

  // Datos iniciales creados sin aplicar reglas.
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    const usuarios = [
      ["adoptante1", "Adoptante de prueba", "adoptante@example.com", "adoptante"],
      ["adoptante2", "Segundo adoptante", "adoptante2@example.com", "adoptante"],
      ["refugio1", "Refugio de prueba", "refugio@example.com", "refugio"],
      ["refugio2", "Segundo refugio", "refugio2@example.com", "refugio"],
    ];

    for (const [uid, nombre, email, rol] of usuarios) {
      await setDoc(doc(db, "users", uid), {
        nombre,
        email,
        rol,
        fechaRegistro: serverTimestamp(),
      });
    }

    const mascotas = [
      ["perro1", "Toby", "refugio1"],
      ["perro2", "Luna", "refugio2"],
      ["perroSeguridad", "Mascota de seguridad", "refugio1"],
    ];

    for (const [id, nombre, refugioId] of mascotas) {
      await setDoc(doc(db, "mascotas", id), {
        nombre,
        especie: "Perro",
        raza: "Mestizo",
        edad: "2 años",
        sexo: "Macho",
        tamano: "Mediano",
        descripcion: "Mascota de prueba",
        imagenUrl: "",
        estado: "disponible",
        refugioId,
        fechaPublicacion: serverTimestamp(),
      });
    }

    await setDoc(doc(db, "favoritos", "fav1"), {
      usuarioId: "adoptante1",
      mascotaId: "perro1",
      fecha: serverTimestamp(),
    });

    for (const id of ["sol1", "sol2", "sol3"]) {
      await setDoc(doc(db, "solicitudes", id), {
        mascotaId: "perro1",
        adoptanteId: "adoptante1",
        refugioId: "refugio1",
        estado: "pendiente",
        mensaje: `Solicitud de prueba ${id}`,
        fechaSolicitud: serverTimestamp(),
      });
    }

    // Solicitud aislada para probar la seguridad de la adopción.
    await setDoc(doc(db, "solicitudes", "solSeguridad"), {
      mascotaId: "perroSeguridad",
      adoptanteId: "adoptante1",
      refugioId: "refugio1",
      estado: "pendiente",
      mensaje: "Solicitud para probar seguridad",
      fechaSolicitud: serverTimestamp(),
    });
  });

  const crearContexto = (uid, email) =>
    testEnv.authenticatedContext(uid, { email }).firestore();

  const adoptante = crearContexto(
    "adoptante1",
    "adoptante@example.com"
  );

  const otroAdoptante = crearContexto(
    "adoptante2",
    "adoptante2@example.com"
  );

  const refugio = crearContexto(
    "refugio1",
    "refugio@example.com"
  );

  const otroRefugio = crearContexto(
    "refugio2",
    "refugio2@example.com"
  );

  const resultados = [];

  async function probar(nombre, operacion, debePermitir) {
    try {
      if (debePermitir) {
        await assertSucceeds(operacion());
      } else {
        await assertFails(operacion());
      }

      resultados.push(`OK: ${nombre}`);
    } catch (error) {
      resultados.push(`FALLO: ${nombre} — ${error.message}`);
    }
  }

  function datosMascota(refugioId) {
    return {
      nombre: "Nueva mascota",
      especie: "Perro",
      raza: "Mestizo",
      edad: "1 año",
      sexo: "Hembra",
      tamano: "Pequeño",
      descripcion: "Mascota publicada durante una prueba",
      imagenUrl: "",
      estado: "disponible",
      refugioId,
      fechaPublicacion: serverTimestamp(),
    };
  }

  // 1. Lectura y permisos de mascotas.

  await probar(
    "Adoptante puede leer mascotas",
    () => getDoc(doc(adoptante, "mascotas", "perro1")),
    true
  );

  await probar(
    "Adoptante no puede editar mascota del refugio",
    () =>
      updateDoc(doc(adoptante, "mascotas", "perro1"), {
        nombre: "Alterado",
      }),
    false
  );

  await probar(
    "Refugio puede modificar su propia mascota",
    () =>
      updateDoc(doc(refugio, "mascotas", "perro1"), {
        nombre: "Toby actualizado",
      }),
    true
  );

  await probar(
    "Refugio no puede modificar mascota ajena",
    () =>
      updateDoc(doc(refugio, "mascotas", "perro2"), {
        nombre: "Alterado",
      }),
    false
  );

  await probar(
    "Segundo refugio no puede modificar mascota del primer refugio",
    () =>
      updateDoc(doc(otroRefugio, "mascotas", "perro1"), {
        nombre: "Alterado",
      }),
    false
  );

  await probar(
    "Adoptante no puede publicar mascotas",
    () =>
      setDoc(
        doc(adoptante, "mascotas", "perro3"),
        datosMascota("adoptante1")
      ),
    false
  );

  await probar(
    "Refugio puede publicar una mascota propia",
    () =>
      setDoc(
        doc(refugio, "mascotas", "perro4"),
        datosMascota("refugio1")
      ),
    true
  );

  await probar(
    "Refugio no puede publicar una mascota a nombre de otro refugio",
    () =>
      setDoc(
        doc(refugio, "mascotas", "perro5"),
        datosMascota("refugio2")
      ),
    false
  );

 
  // 2. Creación y protección de perfiles.

  function datosUsuario(nombre, email, rol, aceptoTerminos = true) {
    return {
      nombre,
      email,
      rol,
      fechaRegistro: serverTimestamp(),
      aceptoTerminos,
      fechaAceptacion: serverTimestamp(),
    };
  }

  await probar(
    "Usuario autenticado puede crear su propio perfil aceptando los términos",
    () =>
      setDoc(
        doc(
          crearContexto("nuevoAdoptante", "nuevo@example.com"),
          "users",
          "nuevoAdoptante"
        ),
        datosUsuario(
          "Nuevo adoptante",
          "nuevo@example.com",
          "adoptante"
        )
      ),
    true
  );

  await probar(
    "Usuario no puede crear el perfil de otra persona",
    () =>
      setDoc(
        doc(adoptante, "users", "perfilAjeno"),
        datosUsuario(
          "Perfil ajeno",
          "ajeno@example.com",
          "adoptante"
        )
      ),
    false
  );

  await probar(
    "Usuario no puede registrarse con un rol no permitido",
    () =>
      setDoc(
        doc(
          crearContexto("usuarioInvalido", "invalido@example.com"),
          "users",
          "usuarioInvalido"
        ),
        datosUsuario(
          "Usuario inválido",
          "invalido@example.com",
          "administrador"
        )
      ),
    false
  );

  await probar(
    "Refugio no puede cambiar el rol de otro usuario",
    () =>
      updateDoc(doc(refugio, "users", "adoptante1"), {
        rol: "refugio",
      }),
    false
  );

  // Nuevas pruebas de aceptación de términos y privacidad.

  await probar(
    "Usuario no puede registrarse sin aceptar los términos",
    () =>
      setDoc(
        doc(
          crearContexto("sinAceptar", "sinaceptar@example.com"),
          "users",
          "sinAceptar"
        ),
        datosUsuario(
          "Usuario sin aceptación",
          "sinaceptar@example.com",
          "adoptante",
          false
        )
      ),
    false
  );

  await probar(
    "Usuario no puede registrarse sin registrar la aceptación",
    () =>
      setDoc(
        doc(
          crearContexto("sinCampos", "sincampos@example.com"),
          "users",
          "sinCampos"
        ),
        {
          nombre: "Usuario sin campos",
          email: "sincampos@example.com",
          rol: "adoptante",
          fechaRegistro: serverTimestamp(),
        }
      ),
    false
  );

  await probar(
    "Usuario no puede registrar una fecha de aceptación arbitraria",
    () =>
      setDoc(
        doc(
          crearContexto("fechaInvalida", "fecha@example.com"),
          "users",
          "fechaInvalida"
        ),
        {
          ...datosUsuario(
            "Usuario fecha inválida",
            "fecha@example.com",
            "adoptante"
          ),
          fechaAceptacion: new Date("2020-01-01T00:00:00Z"),
        }
      ),
    false
  );


  // 3. Favoritos.

  await probar(
    "Adoptante puede leer sus favoritos",
    () =>
      getDocs(
        query(
          collection(adoptante, "favoritos"),
          where("usuarioId", "==", "adoptante1")
        )
      ),
    true
  );

  await probar(
    "Otro adoptante puede consultar sus favoritos sin recibir los ajenos",
    () =>
      getDocs(
        query(
          collection(otroAdoptante, "favoritos"),
          where("usuarioId", "==", "adoptante2")
        )
      ),
    true
  );

  await probar(
    "Consulta sin filtro de favoritos es rechazada",
    () => getDocs(collection(otroAdoptante, "favoritos")),
    false
  );

  await probar(
    "Adoptante puede agregar un favorito propio",
    () =>
      setDoc(doc(adoptante, "favoritos", "favNuevo"), {
        usuarioId: "adoptante1",
        mascotaId: "perro1",
        fecha: serverTimestamp(),
      }),
    true
  );

  await probar(
    "Adoptante no puede crear un favorito a nombre de otro usuario",
    () =>
      setDoc(doc(adoptante, "favoritos", "favAjeno"), {
        usuarioId: "adoptante2",
        mascotaId: "perro1",
        fecha: serverTimestamp(),
      }),
    false
  );

  await probar(
    "Adoptante puede eliminar su propio favorito",
    () => deleteDoc(doc(adoptante, "favoritos", "fav1")),
    true
  );

  // 4. Solicitudes de adopción.

  await probar(
    "Adoptante puede cancelar su solicitud pendiente",
    () =>
      updateDoc(doc(adoptante, "solicitudes", "sol1"), {
        estado: "cancelada",
      }),
    true
  );

  await probar(
    "Adoptante no puede aceptar una solicitud",
    () =>
      updateDoc(doc(adoptante, "solicitudes", "sol2"), {
        estado: "aceptada",
      }),
    false
  );

  await probar(
    "Refugio puede rechazar una solicitud recibida",
    () =>
      updateDoc(doc(refugio, "solicitudes", "sol3"), {
        estado: "rechazada",
      }),
    true
  );

  await probar(
    "Adoptante puede crear una solicitud para una mascota disponible",
    () =>
      setDoc(doc(adoptante, "solicitudes", "solNueva"), {
        mascotaId: "perro1",
        adoptanteId: "adoptante1",
        refugioId: "refugio1",
        estado: "pendiente",
        mensaje: "Quiero adoptar a Toby",
        fechaSolicitud: serverTimestamp(),
      }),
    true
  );

  await probar(
    "Adoptante no puede enviar una solicitud a nombre de otro usuario",
    () =>
      setDoc(doc(adoptante, "solicitudes", "solAjena"), {
        mascotaId: "perro1",
        adoptanteId: "adoptante2",
        refugioId: "refugio1",
        estado: "pendiente",
        mensaje: "Solicitud no autorizada",
        fechaSolicitud: serverTimestamp(),
      }),
    false
  );

  await probar(
    "Adoptante no puede solicitar una mascota inexistente",
    () =>
      setDoc(doc(adoptante, "solicitudes", "solInexistente"), {
        mascotaId: "noExiste",
        adoptanteId: "adoptante1",
        refugioId: "refugio1",
        estado: "pendiente",
        mensaje: "Prueba",
        fechaSolicitud: serverTimestamp(),
      }),
    false
  );

  await probar(
    "Refugio no puede crear solicitudes en nombre de adoptantes",
    () =>
      setDoc(doc(refugio, "solicitudes", "solDelRefugio"), {
        mascotaId: "perro1",
        adoptanteId: "adoptante1",
        refugioId: "refugio1",
        estado: "pendiente",
        mensaje: "Prueba no autorizada",
        fechaSolicitud: serverTimestamp(),
      }),
    false
  );

  // 5. Seguridad del proceso de adopción.

  await probar(
    "Refugio no puede marcar una mascota como adoptada sin aceptar una solicitud",
    () =>
      updateDoc(doc(refugio, "mascotas", "perroSeguridad"), {
        estado: "adoptado",
      }),
    false
  );

  await probar(
    "Refugio no puede aceptar una solicitud sin completar la adopción de la mascota",
    () =>
      updateDoc(doc(refugio, "solicitudes", "solSeguridad"), {
        estado: "aceptada",
      }),
    false
  );

  
  // 6. Vigencia de publicaciones y renovaciones.

  const ahora = new Date();
  const unDia = 24 * 60 * 60 * 1000;

  const fechaReciente = new Date(
    ahora.getTime() - unDia
  );

  const fechaVencimientoReciente = new Date(
    fechaReciente.getTime() + 7 * unDia
  );

  const fechaAntigua = new Date(
    ahora.getTime() - 10 * unDia
  );

  const fechaVencimientoAntigua = new Date(
    fechaAntigua.getTime() + 7 * unDia
  );

  // Crear publicaciones de prueba sin aplicar reglas.
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    await setDoc(doc(db, "mascotas", "perroVigente"), {
      ...datosMascota("refugio1"),
      fechaPublicacion: fechaReciente,
      fechaVencimiento: fechaVencimientoReciente,
    });

    await setDoc(doc(db, "mascotas", "perroVencido"), {
      ...datosMascota("refugio1"),
      fechaPublicacion: fechaAntigua,
      fechaVencimiento: fechaVencimientoAntigua,
    });
  });

  function datosSolicitud(mascotaId) {
    return {
      mascotaId,
      adoptanteId: "adoptante1",
      refugioId: "refugio1",
      estado: "pendiente",
      mensaje: "Solicitud de prueba de vencimiento",
      fechaSolicitud: serverTimestamp(),
    };
  }

  await probar(
    "Adoptante puede solicitar una mascota vigente",
    () => setDoc(
      doc(adoptante, "solicitudes", "solVigente"),
      datosSolicitud("perroVigente")
    ),
    true
  );

  await probar(
    "Adoptante no puede solicitar una mascota vencida",
    () => setDoc(
      doc(adoptante, "solicitudes", "solVencida"),
      datosSolicitud("perroVencido")
    ),
    false
  );

  await probar(
    "Refugio puede editar una mascota vigente sin modificar fechas",
    () => updateDoc(
      doc(refugio, "mascotas", "perroVigente"),
      { nombre: "Mascota vigente editada" }
    ),
    true
  );

  await probar(
    "Refugio no puede modificar arbitrariamente el vencimiento",
    () => updateDoc(
      doc(refugio, "mascotas", "perroVigente"),
      {
        fechaVencimiento: new Date(
          ahora.getTime() + 30 * unDia
        ),
      }
    ),
    false
  );

  await probar(
    "Otro refugio no puede renovar una publicación ajena",
    () => updateDoc(
      doc(otroRefugio, "mascotas", "perroVencido"),
      {
        fechaPublicacion: serverTimestamp(),
        fechaVencimiento: new Date(
          ahora.getTime() + 7 * unDia
        ),
      }
    ),
    false
  );

  await probar(
    "Refugio no puede renovar con una duración arbitraria",
    () => updateDoc(
      doc(refugio, "mascotas", "perroVencido"),
      {
        fechaPublicacion: serverTimestamp(),
        fechaVencimiento: new Date(
          ahora.getTime() + 30 * unDia
        ),
      }
    ),
    false
  );

  
  // 7. Prueba positiva de renovación.

  await probar(
    "Refugio puede renovar su propia publicación vencida",
    () => updateDoc(
      doc(refugio, "mascotas", "perroVencido"),
      {
        fechaVencimiento: new Date(
          Date.now() + 7 * 24 * 60 * 60 * 1000
        ),
      }
    ),
    true
  );

 
  // 8. Publicaciones nuevas con vencimiento.

  await probar(
    "Refugio puede publicar una mascota con vigencia de 7 dias",
    () => {
      const fecha = new Date();

      return setDoc(
        doc(refugio, "mascotas", "perroNuevoVigente"),
        {
          ...datosMascota("refugio1"),
          fechaPublicacion: fecha,
          fechaVencimiento: new Date(
            fecha.getTime() + 7 * 24 * 60 * 60 * 1000
          ),
        }
      );
    },
    true
  );

  await probar(
    "Refugio no puede publicar una mascota con vigencia de 30 dias",
    () => {
      const fecha = new Date();

      return setDoc(
        doc(refugio, "mascotas", "perroNuevoInvalido"),
        {
          ...datosMascota("refugio1"),
          fechaPublicacion: fecha,
          fechaVencimiento: new Date(
            fecha.getTime() + 30 * 24 * 60 * 60 * 1000
          ),
        }
      );
    },
    false
  );

  // Resumen.

  console.log("\n--- RESULTADOS ---");
  console.log(resultados.join("\n"));

  const fallos = resultados.filter((resultado) =>
    resultado.startsWith("FALLO:")
  );

  console.log(`\nPruebas correctas: ${resultados.length - fallos.length}`);
  console.log(`Pruebas fallidas: ${fallos.length}`);

  if (fallos.length > 0) {
    process.exitCode = 1;
  }
}

main()
  .catch((error) => {
    console.error("Error al ejecutar las pruebas:", error);
    process.exitCode = 1;
  })
  .finally(async () => {
    if (testEnv) {
      await testEnv.cleanup();
    }
  });