# Barberia - Luxe & Blade

Aplicacion Flutter multiplataforma para una barberia premium. El proyecto combina un sitio publico de marca, flujo de reserva de citas, autenticacion para personal y portales operativos para administradores y barberos.

## Direccion del Producto

El producto evoluciona hacia un **sistema web** como plataforma principal (mayor estabilidad: un solo despliegue, rollback inmediato, sin tiendas ni fragmentacion de dispositivos). **La app movil se mantiene** y, por ahora, **la prioridad es estabilizarla**, ya que hoy es el canal del staff. Ver la hoja de ruta completa en [`docs/ESTRATEGIA_PLATAFORMAS.md`](docs/ESTRATEGIA_PLATAFORMAS.md).

Que puede hacer cada plataforma se define en un solo lugar: `lib/core/platform/platform_capabilities.dart`. Para un build piloto de web con portales de staff: `flutter build web --dart-define=WEB_STAFF_PORTALS=true`.

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

## Modelo de Datos y Backend

El esquema canónico de `bookings`, el ciclo de vida de una cita, los
contratos de Cloud Functions, el invariante anti doble-reserva, los índices
requeridos y los comandos de prueba están documentados en
[`docs/BOOKING_SYSTEM.md`](docs/BOOKING_SYSTEM.md).

Colecciones principales: `shops` (configuración por tenant, reemplaza
`config/barberia`), `users` (perfiles privados con `role` y `shopId`),
`barber_directory` (proyección pública de barberos, escrita solo por el
servidor), `services`, `bookings`, `schedule_blocks`, `notifications`,
`reputation`, `walkins`/`clients`, y las colecciones solo-servidor
`booking_guards`, `booking_requests` y `booking_limits`.

Funciones en `backend/functions`: `reserveSlot`, `getAvailability`,
`inviteBarber`, `removeBarber`, `resetBarberPassword` y el trigger
`syncBarberDirectory`.

Las reglas (`firestore.rules`) aíslan cada tenant: los clientes no pueden
crear reservas directamente, cada barbero ve solo sus citas, el admin solo
gestiona su shop y ningún usuario puede cambiar su propio rol o `shopId`.
Están cubiertas por `backend/tests/test_firestore_rules.py`.

## Reporte de Errores (Crashlytics)

En Android/iOS los errores no capturados (framework y async) se envian a Firebase Crashlytics. En web/desktop el modulo es un no-op.

- En builds debug la recoleccion esta apagada. Para probarla: `flutter run --dart-define=CRASHLYTICS_IN_DEBUG=true`.
- Errores manejados relevantes se reportan con `CrashReporting.recordNonFatal(...)`.
- Solo se adjuntan `uid`, `role` y `shopId` del staff; nunca email, telefono ni nombres.
- iOS: para stack traces legibles hay que subir los dSYM (ejecutar `flutterfire configure` en macOS, que agrega la fase de build).

## Requisitos

- Flutter 3.50.0 estable (Dart 3.14.0), fijado en `.fvmrc`.
- FVM opcional para usar la versión fijada.
- Firebase CLI para emuladores y deploy.
- Python 3.11+ para Cloud Functions.

## Puesta en Marcha

```bash
flutter pub get
flutter run -d chrome
```

Con FVM:

```bash
fvm flutter pub get
fvm flutter run -d chrome
```

Analisis y pruebas:

```bash
fvm flutter analyze
fvm flutter test
cd backend/functions && python -m pytest tests
```

La CI (`.github/workflows/ci.yml`) ejecuta estos mismos pasos en cada push y PR.

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

Firebase Hosting sirve el contenido de `build/web/`. Genera el build antes de publicar.

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
- Varios textos del codigo muestran mojibake en comentarios/strings leidos desde archivos; revisar codificacion UTF-8 si se normaliza contenido.
- `.env` ya no se empaqueta como asset (no se usaba y rompia el build en un clon limpio); no agregar secretos al repositorio.

## Proximos Pasos Recomendados

- Consolidar routers y entrada de app para evitar confusion.
- Agregar pruebas Flutter para auth/routing (el flujo de reserva ya tiene tests).
- Habilitar App Check en las callables públicas.
- Documentar esquema definitivo de Firestore con ejemplos de documentos.

## Licencia

No hay licencia explicita en el repositorio. Definir MIT, Apache-2.0, propietaria u otra segun el uso previsto.
