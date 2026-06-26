# Barberia - Luxe & Blade

Aplicacion Flutter multiplataforma para una barberia premium. El proyecto combina un sitio publico de marca, flujo de reserva de citas, autenticacion para personal y portales operativos para administradores y barberos.

## Funcionalidades Principales

- Sitio publico con Home, Servicios, Galeria, Barberos, Membresias y Personalizador de corte.
- Flujo de reserva en pasos:
  - seleccion de barbero,
  - seleccion de servicio,
  - fecha y hora,
  - datos del cliente,
  - resumen y confirmacion.
- Lectura de barberos desde `users` con `role == barber` y fallback a datos locales si Firestore no devuelve resultados.
- Creacion de reservas en `bookings` con estado inicial `PENDING`.
- Notificaciones administrativas en `notifications` al confirmar una reserva.
- Login de personal con Firebase Auth y validacion de rol (`admin` o `barber`) desde `users/{uid}`.
- Rutas protegidas para `/admin/portal` y `/barber/portal`.
- Portal de administrador con dashboard, reservas, gestion de barberos, servicios, configuracion, notificaciones y horarios.
- Portal de barbero con dashboard, agenda, clientes, ingresos, sesion activa y perfil.
- Configuracion remota desde `config/barberia` para idioma y simbolo de moneda.
- Backend Python con motor puro de slots, validacion de colisiones, bloqueos de horario, reputacion/no-shows e invitacion/eliminacion de barberos.

## Stack Tecnico

- Flutter / Dart (`sdk: ^3.11.5`)
- Riverpod (`flutter_riverpod`)
- GoRouter
- Firebase Core, Auth, Firestore y Functions
- Cloud Functions Python 3.11
- Material 3
- Google Fonts
- `flutter_animate`
- `shared_preferences`
- `table_calendar`
- `qr_flutter`
- `share_plus`
- `url_launcher`
- `flutter_local_notifications`
- Firebase Hosting / Emulators

## Estructura Relevante

```text
lib/
  main.dart                         # Inicializa Firebase y ProviderScope
  app_first.dart                    # MaterialApp.router real de la app
  firebase_options.dart             # Configuracion generada por FlutterFire
  core/
    router/app_router.dart          # Rutas y redirecciones por rol
    providers/config_provider.dart  # Config remota desde Firestore
    theme/app_theme.dart            # Tokens visuales y ThemeData
    l10n/app_localizations.dart     # Traducciones ES/EN usadas por la UI
  features/
    home/                           # Landing publica
    services/                       # Pagina de servicios
    gallery/                        # Galeria
    barbers/                        # Barberos y portal del barbero
    booking/                        # Flujo de reserva
    membership/                     # Membresias
    personalizer/                   # Personalizador de corte
    auth/                           # Login y estado de autenticacion
    admin/                          # Portal administrativo

backend/functions/
  main.py                           # Callable functions: reserveSlot, getAvailability, inviteBarber, removeBarber
  slot_engine.py                    # Motor puro de disponibilidad
  requirements.txt

tool/
  list_users_script.dart
  list_clients_script.dart
  create_user_role.py
  migrate_bookings_v2.dart
```

## Rutas de la App

| Ruta | Vista |
| --- | --- |
| `/` | Home publica |
| `/gallery` | Galeria |
| `/personalizer` | Personalizador de corte |
| `/booking` | Reserva de citas |
| `/barbers` | Barberos |
| `/membership` | Membresias |
| `/services` | Servicios |
| `/login` | Acceso de personal |
| `/barber/portal` | Portal de barbero, requiere rol `barber` |
| `/admin/portal` | Portal de admin, requiere rol `admin` |

En Android/iOS la ruta inicial configurada es `/login`; en web/desktop inicia en `/`.

## Modelo de Datos Esperado

Colecciones usadas o previstas en Firestore:

- `users`: perfiles de usuarios, barberos y admins. El campo `role` controla permisos (`client`, `barber`, `admin`).
- `bookings`: reservas. La UI actual usa campos como `clientName`, `clientEmail`, `clientPhone`, `service`, `price`, `time`, `barberId`, `barberName`, `status`, `date` y `createdAt`.
- `notifications`: notificaciones visibles para el portal administrativo.
- `services`: catalogo administrable por admin y usado por las Cloud Functions.
- `config/barberia`: idioma, moneda, horarios y parametros globales.
- `schedule_blocks`: bloqueos de agenda por barbero.
- `reputation`: control anti no-show por telefono normalizado.
- `walkins`: cola sin cita, preparada en reglas.

## Backend y Reglas

El backend en `backend/functions` expone:

- `reserveSlot`: crea una reserva de forma atomica validando servicio, barbero, horario laboral, conflictos, bloqueos y reputacion.
- `getAvailability`: devuelve slots libres para un barbero, fecha y servicio.
- `inviteBarber`: crea cuenta de Firebase Auth, documento `users/{uid}` e intenta enviar credenciales por SendGrid.
- `removeBarber`: elimina el documento del barbero y su cuenta Auth.

Las reglas de Firestore estan en `firestore.rules`. El modelo de seguridad distingue clientes, barberos y administradores. Nota importante: actualmente las reglas permiten lectura/escritura abierta en `bookings` y `notifications`; conviene cerrarlas antes de produccion si la app publica queda expuesta.

## Requisitos

- Flutter estable compatible con Dart `^3.11.5`.
- FVM opcional; `.fvmrc` apunta a `stable`.
- Firebase CLI para emuladores y deploy.
- Python 3.11+ para Cloud Functions.

## Puesta en Marcha

```bash
flutter pub get
flutter run
```

Con FVM:

```bash
fvm flutter pub get
fvm flutter run
```

Analisis y pruebas:

```bash
fvm flutter analyze
fvm flutter test
```

La carpeta `test/` no contiene pruebas relevantes actualmente.

## Firebase Local

Levantar emuladores:

```bash
firebase emulators:start --only auth,firestore,functions
```

Puertos configurados:

- Auth: `9099`
- Firestore: `8080`
- Functions: `5001`
- Hosting: `5000`
- Emulator UI: `4000`

La app Flutter no conecta automaticamente a emuladores en `main.dart`; si se necesita desarrollo local completo, hay que configurar `useAuthEmulator`, `useFirestoreEmulator` y `useFunctionsEmulator`.

## Deploy

Funciones:

```bash
firebase deploy --only functions
```

Reglas e indices:

```bash
firebase deploy --only firestore
```

Hosting:

```bash
flutter build web
firebase deploy --only hosting
```

`firebase.json` sirve hosting desde `public/`. Si se desea publicar el build de Flutter, ajustar `hosting.public` a `build/web` o copiar el build a `public/` antes del deploy.

## Scripts Utiles

```bash
dart run tool/list_users_script.dart
dart run tool/list_clients_script.dart
dart run tool/migrate_bookings_v2.dart
python tool/create_user_role.py
python tool/inspect_firestore_collections.py
```

Revisar cada script antes de ejecutarlo, especialmente los de migracion o escritura.

## Estado y Riesgos Detectados

- El README anterior describia una version mas antigua del proyecto; esta version documenta la estructura actual.
- Hay dos entradas de app (`lib/app_first.dart` y `lib/app/app.dart`), pero `main.dart` usa `app_first.dart`.
- Tambien hay dos routers (`lib/core/router/app_router.dart` y `lib/app/router.dart`); el router activo es `core/router/app_router.dart`.
- La UI de reserva actual crea reservas directamente en Firestore, mientras el backend ya ofrece `reserveSlot` para evitar colisiones. Un siguiente paso tecnico seria conectar la UI a esa function.
- Varios textos del codigo muestran mojibake en comentarios/strings leidos desde archivos; revisar codificacion UTF-8 si se normaliza contenido.
- `.env` contiene configuracion de Firebase y ubicacion; no agregar secretos privados reales al repositorio.

## Proximos Pasos Recomendados

- Conectar `BookingPage` a `getAvailability` y `reserveSlot`.
- Endurecer reglas de `bookings` y `notifications`.
- Consolidar routers y entrada de app para evitar confusion.
- Agregar pruebas unitarias para `slot_engine.py` y pruebas Flutter para auth/routing/reserva.
- Documentar esquema definitivo de Firestore con ejemplos de documentos.
- Revisar configuracion de Hosting para publicar `build/web`.

## Licencia

No hay licencia explicita en el repositorio. Definir MIT, Apache-2.0, propietaria u otra segun el uso previsto.
