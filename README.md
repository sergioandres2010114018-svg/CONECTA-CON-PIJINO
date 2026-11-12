# APP-Conecta con Pijiño

> *“El corazón de Pijiño en cada atarraya”*

Aplicación móvil Android (Flutter + Firebase) que da a conocer la historia, la cultura, la gastronomía,
las fiestas, los sitios turísticos y el medio ambiente de **Pijiño del Carmen (Magdalena)**.

**Creado por Grupo de Estudiantes Conecta con Pijiño, del Proyecto Senatic e IEDT Pijiño del Carmen.**

---

## Funcionalidades

| Módulo | Qué hace |
|---|---|
| Login y registro | Registro con nombre, correo, celular, tipo de usuario y aceptación de tratamiento de datos (Ley 1581/2012). Inicio de sesión y recuperación de contraseña. Cada usuario queda guardado en la colección `usuarios`. |
| Inicio | Saludo, accesos a las 9 secciones, lugares destacados y próximos eventos. |
| Secciones | Historia · Cultura y tradiciones · Gastronomía · Sitios turísticos · Fiestas y eventos · Medio ambiente. Cada publicación muestra si está **verificada** o **por validar**. |
| Explorar | Búsqueda (sin importar tildes) y filtro por categoría. |
| Galería | Fotos y videos guardados en la base de datos. Los usuarios comparten desde el celular (Firebase Storage) o con enlace (YouTube). Los aportes quedan **en revisión** hasta que un administrador los aprueba. |
| Mapa | Mapa interactivo OpenStreetMap con los lugares que tienen coordenadas (no requiere clave de API). Botón “Cómo llegar”. |
| Directorio | Comercios y entidades con botón de llamada y WhatsApp. Los comerciantes pueden solicitar su registro. |
| Contacto y participación | Sugerencias, aportes, correcciones, registro de negocios y solicitudes sobre datos personales. |
| Perfil | Editar datos, favoritos, tamaño de texto y modo oscuro (accesibilidad). |
| Administración | Aprobar fotos/videos, ver usuarios registrados y asignar administradores, leer mensajes, crear/editar/eliminar publicaciones y cargar el contenido inicial. |
| Acerca de | Misión, visión, valores, equipo, organigrama y créditos. |

## Estructura de la base de datos (Cloud Firestore)

```
usuarios/{uid}      nombre, email, telefono, tipoUsuario, rol ('usuario'|'admin'), favoritos[], creadoEn, ultimoIngreso
contenidos/{id}     categoria, titulo, resumen, cuerpo, imagenUrl, videoUrl, lugar, fecha, lat, lng, orden, validado, fuente
galeria/{id}        tipo ('foto'|'video'), url, titulo, descripcion, autorUid, autorNombre, aprobado, rutaStorage, creadoEn
negocios/{id}       nombre, tipo, descripcion, telefono, direccion
mensajes/{id}       uid, nombre, email, tipo, mensaje, leido, creadoEn
```

Archivos en **Firebase Storage**: `galeria/{uid}/...` (aportes) y `contenidos/...` (imágenes de publicaciones).

## Estructura del código

```
lib/
  main.dart                 Arranque, Firebase, tema, sesión
  config.dart               Nombre, créditos, administradores, categorías
  theme.dart                Colores de la identidad (naranja, café, arena, negro)
  firebase_options.dart     Datos de conexión a Firebase  <-- configurar
  models/models.dart        Usuario, Contenido, MediaItem, Negocio, Mensaje
  services/                 auth, base de datos, storage, contenido inicial, preferencias
  screens/                  login, registro, inicio, secciones, detalle, explorar, galería,
                            visor, subir, mapa, directorio, contacto, perfil, favoritos,
                            administración, editar contenido, acerca de
  widgets/                  tarjetas, imágenes, créditos
firebase/firestore.rules    Reglas de seguridad de la base de datos
firebase/storage.rules      Reglas de seguridad de fotos y videos
scripts/setup_android.sh    Ajustes de Android (permisos, nombre, minSdk)
.github/workflows/          Compilación automática del APK
```

---

## 1. Configurar Firebase (una sola vez)

1. Entre a <https://console.firebase.google.com> y cree el proyecto **conecta-pijino**.
2. **Authentication** → *Comenzar* → habilite **Correo electrónico/contraseña**.
3. **Firestore Database** → *Crear base de datos* (ubicación `southamerica-east1` o `us-central1`) → modo producción.
   En la pestaña **Reglas** pegue el contenido de `firebase/firestore.rules` y publique.
4. **Storage** → *Comenzar*. En **Reglas** pegue `firebase/storage.rules` y publique.
   > Nota: desde 2024 Google exige activar el plan **Blaze** (pago por uso) para crear buckets de Storage.
   > El plan incluye una cuota gratuita (5 GB) suficiente para el prototipo; configure una alerta de presupuesto de $1 USD.
   > Si no desea activarlo, la app funciona igual y la galería puede alimentarse con **enlaces** (YouTube, etc.).
5. Agregue una **app Android** con el paquete `co.edu.iedtpijino.conecta_pijino`.
6. Conecte el código con Firebase, de una de estas dos formas:
   - **Automática:** en la carpeta del proyecto ejecute
     ```bash
     dart pub global activate flutterfire_cli
     flutterfire configure --project=<id-de-su-proyecto> --platforms=android
     ```
   - **Manual:** abra `lib/firebase_options.dart` y reemplace `TU_API_KEY`, `TU_APP_ID`, `TU_SENDER_ID`
     y `TU_PROJECT_ID` con los valores de *Configuración del proyecto → Tus apps → Android*
     (están dentro del archivo `google-services.json`: `current_key`, `mobilesdk_app_id`, `project_number`, `project_id`).
7. **Administradores:** el correo del instructor ya está como administrador en `lib/config.dart`,
   `firebase/firestore.rules` y `firebase/storage.rules`. Para agregar más, súmelos en los tres archivos,
   o desde la app: *Perfil → Panel de administración → Usuarios → Hacer administrador*.
8. Registre en la app la cuenta del administrador y, en *Inicio*, pulse **Cargar contenido inicial**.
   Si la base de datos ya tenía contenido de una versión anterior, use *Perfil → Panel de administración → Datos →
   Restaurar contenido inicial* para traer los textos y fotos nuevos (las publicaciones creadas a mano no se borran).

## 2. Obtener el APK

### Opción A — GitHub (sin instalar nada)

**Qué subir:** el contenido de la carpeta `conecta-pijino` tal como viene:

```
.github/workflows/build-apk.yml   ← compila el APK automáticamente
assets/                           ← logo, fotos, escudo, bandera, emblema, organigrama e ícono
firebase/                         ← reglas de seguridad para la consola de Firebase
lib/                              ← todo el código de la app
scripts/                          ← ajustes de Android
test/
analysis_options.yaml
pubspec.yaml
README.md
.gitignore
```

> **Ojo con `.github`:** las carpetas que empiezan por punto están ocultas en Windows y Mac, y a veces no se suben al arrastrarlas
> a la página de GitHub. Si después de subir no ves la carpeta `.github` en el repositorio, créala a mano:
> *Add file → Create new file*, escribe como nombre `.github/workflows/build-apk.yml` y pega el contenido de ese archivo.
>
> **Si ya tienes el repositorio:** sube los archivos nuevos encima (GitHub reemplaza los que tengan el mismo nombre).

1. Cree un repositorio en GitHub y suba esta carpeta (rama `main`).
2. GitHub compila solo: pestaña **Actions → Construir APK**. Al terminar (≈10 min), descargue
   `conecta-con-pijino-apk` en la sección **Artifacts**. Dentro está `conecta-con-pijino.apk`.
3. Copie el APK al celular y ábralo (permita “instalar apps de origen desconocido”).

### Opción B — En su computador
Requisitos: Flutter estable 3.35 o superior, Android Studio con SDK de Android, Java 17.
```bash
flutter create --platforms=android --org co.edu.iedtpijino .
bash scripts/setup_android.sh          # en Windows use Git Bash
flutter pub get
dart run flutter_launcher_icons
flutter run                             # probar en el celular/emulador
flutter build apk --release             # APK en build/app/outputs/flutter-apk/app-release.apk
```

> El APK de este flujo queda firmado con la llave de depuración: sirve para instalar y sustentar.
> Para publicar en Google Play, cree una llave de firma (ver documentación de Flutter “Build and release an Android app”).

## 3. Contenido

El contenido inicial (`lib/services/seed_data.dart`) trae **52 publicaciones** en 7 secciones (historia, cultura,
personajes, gastronomía, sitios turísticos, fiestas y eventos, medio ambiente), 6 videos públicos de YouTube y un
directorio con los sitios web y redes oficiales. Cada publicación muestra su fuente y un botón **Ver fuente**.

- **Verificado:** dato respaldado por un documento oficial (Agencia Nacional de Tierras 2024, plan municipal 2000, DANE)
  o por al menos dos fuentes independientes.
- **Por validar:** dato con una sola fuente publicada; el equipo de contenidos debe confirmarlo con la comunidad
  (los textos indican **PENDIENTE** donde falta información), como lo exige el proyecto. Todo se edita desde el panel de administración
sin recompilar la app. Las fotos y videos reales del municipio se suben desde **Galería → Compartir**.

---

Institución Educativa Técnica Departamental Pijiño del Carmen · SENA – Centro Acuícola y Agroindustrial de Gaira ·
Técnico en Programación de Aplicaciones para Dispositivos Móviles · Grupo 3321831
