# IncidApp — Gestión de Incidencias y Servicios Comunitarios

Aplicación móvil para reportar, dar seguimiento y gestionar **incidencias** (estructurales, eléctricas, mantenimiento, limpieza, seguridad, convivencia) y **solicitudes de servicios comunitarios** dentro de una institución educativa.

**Trabajo Colaborativo Contextualizado (TCC) — Desarrollo de APPs 2026-2**

- **Integrantes:** Isaías Gonzales Torres, Samuel Portillo, Marisol Teheran Carvajal y Daniela Judith Villalba de Hoyos
- **Versión:** 1.0 (entrega final)
- **Universidad:** Universidad de Cartagena, Centro Tutorial Cereté · Ingeniería de Software
- **Tutor:** Domingo Galeano
- **Servidor publicado:** https://incidapp-app.onrender.com
- **Descargar el APK:** https://drive.google.com/file/d/1OfmFFaitKr0kFIvjKdzdms5DXKfNkA7F/view?usp=sharing

---

## 1. ¿Qué hace la aplicación?

Tiene dos tipos de usuario y cada uno ve solo lo que le corresponde.

| Función | Usuario general | Admin |
|---|---|---|
| Registrarse e iniciar sesión | ✅ | ✅ |
| Reportar incidencias (categoría, ubicación, descripción, prioridad) | ✅ | ✅ |
| Ver el estado de sus propios reportes y filtrarlos | ✅ | ✅ |
| Cancelar un reporte mientras esté pendiente | ✅ | ✅ |
| Solicitar servicios comunitarios (con fecha programada) | ✅ | ✅ |
| Recibir notificaciones de cambio de estado | ✅ | ✅ |
| Ver **todas** las incidencias (las más urgentes primero) | ❌ | ✅ |
| Cambiar estado y prioridad de una incidencia y responder al usuario | ❌ | ✅ |
| Gestionar solicitudes de servicios (aprobar, completar, rechazar) | ❌ | ✅ |
| Panel de control con estadísticas y tiempos de respuesta | ❌ | ✅ |
| Crear, editar y eliminar categorías | ❌ | ✅ |
| Administrar usuarios (cambiar rol, eliminar) | ❌ | ✅ |

**Reportes confidenciales:** las categorías marcadas con *visibilidad restringida* (por ejemplo, Convivencia) solo pueden verlas la administración y quien las reportó.

---

## 2. Arquitectura

```
┌──────────────────────┐   HTTPS / JSON    ┌────────────────────────┐   Mongoose   ┌───────────────────┐
│  App móvil (Flutter) │ ────────────────► │  API REST (Node.js +   │ ───────────► │  MongoDB Atlas    │
│  Android             │ ◄──────────────── │  Express)              │ ◄─────────── │  (base de datos)  │
│  Token JWT guardado  │   Authorization:  │  Middleware: JWT + rol │              │                   │
└──────────────────────┘   Bearer <token>  └────────────────────────┘              └───────────────────┘
```

- **Frontend:** Flutter (Dart) con Material Design 3.
- **Backend:** Node.js + Express. API REST que valida el token y el rol en cada petición.
- **Base de datos:** MongoDB Atlas (nube), accedida con Mongoose.
- **Autenticación:** JSON Web Tokens (JWT, válidos 7 días). Las contraseñas se guardan encriptadas con bcrypt.

**Seguridad:** el rol del usuario se consulta en la base de datos en cada petición (un cambio de rol aplica al instante y una cuenta eliminada pierde el acceso); se validan los datos de entrada; el Admin no puede eliminarse ni quitarse su propio rol.

---

## 3. Estructura del proyecto (por módulos)

```
incidapp_prototipo/
├── README.md
├── .gitignore
├── backend/
│   ├── server.js                  Punto de entrada: conecta a MongoDB y registra las rutas
│   ├── seed.js                    Carga las categorías iniciales (npm run seed)
│   ├── pruebas_seguridad.js       19 pruebas automáticas de seguridad (npm test)
│   ├── middleware/auth.js         Verificación de token y de rol (soloAdmin)
│   ├── models/                    Usuario, Categoria, Incidencia, Servicio, Notificacion
│   ├── routes/                    auth, usuarios, categorias, incidencias, servicios, notificaciones
│   └── utils/notificar.js         Crea las notificaciones de cambio de estado
└── flutter_app/
    └── lib/
        ├── main.dart              Arranque de la app y sesión recordada
        ├── models/                Clases de datos (Incidencia, Servicio, Usuario, ...)
        ├── services/api_service.dart   Comunicación con el backend
        ├── screens/               Login, registro, menú, incidencias, servicios, panel, usuarios, ...
        └── utils/                 Textos, colores y componentes reutilizables
```

---

## 4. Base de datos (MongoDB)

| Colección | Campos principales |
|---|---|
| **usuarios** | nombre, correo (único), contrasena (encriptada), rol (`admin` / `general`), fechaRegistro |
| **categorias** | nombre (único), descripcion, requiereVisibilidadRestringida |
| **incidencias** | titulo, descripcion, categoria (→ categorias), ubicacion, estado (`pendiente` / `en_proceso` / `resuelta`), prioridad (`baja` / `media` / `alta`), usuario (→ usuarios), fechaCreacion, fechaRespuesta, fechaResolucion, observacionAdmin |
| **servicios** | tipoServicio, descripcion, fechaProgramada, estado (`pendiente` / `en_proceso` / `completado` / `rechazado`), usuario (→ usuarios), fechaSolicitud, observacionAdmin |
| **notificaciones** | usuario (→ usuarios), mensaje, tipo (`incidencia` / `servicio`), referencia, leida, fecha |

Los tiempos de respuesta se calculan con `fechaCreacion`, `fechaRespuesta` (primera vez que la incidencia sale de *pendiente*) y `fechaResolucion`.

---

## 5. API REST

Todas las rutas (menos registro y login) requieren el encabezado `Authorization: Bearer <token>`.

| Método y ruta | Quién | Descripción |
|---|---|---|
| `POST /api/auth/register` | Público | Crea una cuenta (rol general) |
| `POST /api/auth/login` | Público | Inicia sesión y devuelve el token |
| `GET /api/usuarios/me` | Autenticado | Perfil del usuario actual |
| `GET /api/usuarios` | Admin | Lista de usuarios |
| `PUT /api/usuarios/:id` | Admin | Cambia nombre o rol |
| `DELETE /api/usuarios/:id` | Admin | Elimina un usuario y sus datos |
| `GET /api/categorias` | Autenticado | Lista de categorías |
| `POST` / `PUT` / `DELETE /api/categorias[/:id]` | Admin | Crear, editar, eliminar |
| `POST /api/incidencias` | Autenticado | Registra una incidencia |
| `GET /api/incidencias?estado=` | Autenticado | Admin: todas · General: solo las suyas |
| `GET /api/incidencias/:id` | Admin o dueño | Detalle |
| `PUT /api/incidencias/:id` | Admin | Cambia estado, prioridad y respuesta |
| `DELETE /api/incidencias/:id` | Admin, o el dueño si está pendiente | Elimina / cancela |
| `GET /api/incidencias/estadisticas/resumen` | Admin | Datos del panel de control |
| `POST /api/servicios` | Autenticado | Solicita un servicio |
| `GET /api/servicios?estado=` | Autenticado | Admin: todas · General: solo las suyas |
| `PUT /api/servicios/:id` | Admin | Cambia estado y respuesta |
| `DELETE /api/servicios/:id` | Admin, o el dueño si está pendiente | Elimina / cancela |
| `GET /api/notificaciones` · `/contador` | Autenticado | Notificaciones del usuario |
| `PUT /api/notificaciones/leer-todas` · `/:id/leida` | Autenticado | Marca como leídas |

---

## 6. Instalación y configuración

### Requisitos
- Node.js 18 o superior
- Flutter SDK y Android Studio (SDK de Android y un emulador o un celular)
- Una cuenta gratuita de MongoDB Atlas

### 6.1 Backend
1. Entrar a la carpeta e instalar dependencias:
   ```
   cd backend
   npm install
   ```
2. Copiar `.env.example` como `.env` y completar:
   ```
   MONGO_URI=mongodb+srv://USUARIO:CONTRASENA@TU-CLUSTER.mongodb.net/incidapp
   JWT_SECRET=una_clave_larga_y_secreta
   PORT=3000
   ```
   En MongoDB Atlas, en *Network Access*, debe estar permitido el acceso (por ejemplo `0.0.0.0/0`).
3. Cargar las categorías iniciales (solo la primera vez):
   ```
   npm run seed
   ```
4. Iniciar el servidor:
   ```
   npm start
   ```
   Debe mostrar `Conectado a MongoDB`.

### 6.2 Aplicación móvil (modo desarrollo, en el emulador)
```
cd flutter_app
flutter pub get
flutter run
```
Por defecto la app se conecta a `http://10.0.2.2:3000/api` (el computador, visto desde el emulador Android). Con un backend publicado en internet:
```
flutter run --dart-define=API_URL=https://TU-BACKEND.onrender.com/api
```

### 6.3 Generar el APK
```
cd flutter_app
flutter build apk --release --dart-define=API_URL=https://TU-BACKEND.onrender.com/api
```
El archivo queda en `flutter_app/build/app/outputs/flutter-apk/app-release.apk`.

### 6.4 Instalar el APK en un celular Android
1. Copiar el `.apk` al celular (cable USB, Drive o WhatsApp).
2. Abrirlo desde el celular y permitir *instalar apps de origen desconocido* cuando lo pida.
3. Abrir **IncidApp** e iniciar sesión.

> El backend gratuito se duerme tras 15 minutos sin uso: la primera vez que se abre la app puede tardar hasta un minuto en responder. Las siguientes veces es inmediato.

---

## 7. Uso rápido

1. **Registrarse** desde la pantalla de inicio. Toda cuenta nueva es de rol *general*.
2. **Volver Admin a una cuenta:** en MongoDB Atlas (*Browse Collections → usuarios*) cambiar el campo `rol` a `"admin"`. A partir de ahí, un Admin puede cambiar roles desde la app (*Usuarios*).
3. **Reportar:** *Reportar incidencia* → llenar el formulario → *Registrar incidencia*.
4. **Seguimiento:** *Mis incidencias* → tocar una para ver su detalle y la respuesta de la administración.
5. **Admin:** *Todas las incidencias* → abrir una → cambiar estado, prioridad y escribir la respuesta → *Guardar cambios*. El usuario recibe la notificación.

### Cuentas de prueba
- **Admin:** `test@incidapp.com` · contraseña: *(completar)*
- **Usuario general:** `villalba@incidapp.com` · contraseña: *(completar)*

---

## 8. Pruebas

- **Pruebas automáticas de seguridad (backend):** `cd backend` y `npm test` → 19 casos (acceso sin token, permisos por rol, validación de datos, protecciones del Admin).
- **Pruebas funcionales en la app:** 15 casos documentados en el informe de la Tutoría 7 (registro, filtros, cancelación, notificaciones, panel, roles, sesión recordada, error sin servidor).

---

## 9. Limitaciones y trabajo futuro

- La ubicación se escribe como texto (no usa GPS ni mapa).
- Las notificaciones aparecen dentro de la app (no son notificaciones push del sistema).
- No hay recuperación de contraseña ni adjuntar fotos a los reportes.
- El APK está firmado con la clave de depuración: sirve para instalar y probar, pero no para publicar en Google Play.
- El backend gratuito se duerme tras 15 minutos de inactividad.
