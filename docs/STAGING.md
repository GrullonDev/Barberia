# Staging y pruebas end-to-end

## Proyectos

| | Staging | Producción (protegido) |
|---|---|---|
| Project ID | `barberia-staging` | `barbershop-ee9c0` |
| Número | `169151296960` | `956317826330` |
| Alias `.firebaserc` | `staging` | `default` |
| Opciones Flutter | `lib/firebase_options_staging.dart` (solo Web) | `lib/firebase_options.dart` |
| Hosting | https://barberia-staging.web.app | — |

**Nunca ejecutar `firebase deploy` sin `--project`**: el `default` es producción.
Toda operación de staging pasa por `tool/staging.sh`, que fija
`--project barberia-staging` y falla si algo no cuadra.

## Estado del entorno (verificado 2026-11-22)

| Servicio | Estado |
|---|---|
| Plan de facturación | Blaze. Política de limpieza de Artifact Registry: 7 días |
| Firestore | `(default)`, `nam5`, Standard, delete-protection ON. Reglas e índices del repo desplegados; 9/9 índices READY |
| Authentication | Email/Password habilitado; dominios autorizados `barberia-staging.web.app`, `barberia-staging.firebaseapp.com`; 3 cuentas sintéticas |
| App Web | `Barberia Web (staging)` — `1:169151296960:web:cb9ed6ec4580f0756e8425` |
| Cloud Functions | 8 en `us-central1`, python311: `getAvailability`, `reserveSlot`, `createScheduleBlock`, `inviteBarber`, `removeBarber`, `resetBarberPassword` (callables); `syncBarberDirectory`, `onBookingNoShow` (triggers Firestore) |
| Hosting | https://barberia-staging.web.app (build `FIREBASE_ENV=staging`, `SHOP_ID=barberia-staging`, `WEB_STAFF_PORTALS=true`) |

El primer deploy de Functions en un proyecto nuevo puede fallar dos veces
mientras se crean las cuentas de servicio (IAM y Eventarc); basta reintentar
`tool/staging.sh deploy functions` uno o dos minutos después.

Ubicación de Firestore: se eligió `nam5` (igual que producción y contiene
`us-central1`, la región fijada en `backend/functions/main.py`). Es
irreversible para la base `(default)`.

## Selección de entorno en Flutter

| Flag (`--dart-define`) | Valores | Efecto |
|---|---|---|
| `FIREBASE_ENV` | `production` (defecto), `staging`, `demo` | proyecto Firebase; otro valor detiene la app al iniciar |
| `SHOP_ID` | `barberia-staging` en staging | tenant público de reservas |
| `WEB_STAFF_PORTALS` | `true` en staging (`tool/staging.sh`) | incluye `/login`, `/admin/portal`, `/barber/portal` en web; sin él la web es solo pública y el pie de página oculta "Acceso Personal" |
| `USE_FIREBASE_EMULATORS` | `true` | Auth 9099, Firestore 8080, Functions 5001 |
| `E2E_SEMANTICS` | `true` | árbol de accesibilidad para Playwright |

`lib/core/firebase/firebase_environment.dart` resuelve el entorno con
constantes de compilación, así que **un build de staging no contiene la
configuración de producción** (CI y `tool/staging.sh` lo verifican con
`grep` sobre `build/web/main.dart.js`). Al iniciar, `verifyFirebaseProject`
compara el `projectId` real con el esperado y aborta si difieren; fuera de
producción (o en debug) imprime `[firebase] FIREBASE_ENV=… project=…`.

`demo` es para emuladores (`demo-barberia`, nunca alcanza servicios reales)
y exige `USE_FIREBASE_EMULATORS=true`.

### Configuración FlutterFire

`firebase_options_staging.dart` se generó con
`firebase apps:sdkconfig WEB <appId> --project barberia-staging` en vez de
`flutterfire configure`, porque este último reescribe la sección `flutter`
de `firebase.json`, que apunta a producción. Las claves son identificadores
públicos de cliente.

Staging nativo (pendiente, no requerido para Web): registrar apps
Android/iOS en `barberia-staging` con un bundle id distinto (p. ej.
`…barberia.staging`), generar sus opciones con
`flutterfire configure --project=barberia-staging --platforms=android,ios --out=lib/firebase_options_staging.dart`
**restaurando después `firebase.json`**, y añadir flavors nativos para que
`google-services.json` / `GoogleService-Info.plist` no reemplacen los de
producción. Hasta entonces `FIREBASE_ENV=staging` en nativo lanza
`UnsupportedError`.

## Operaciones (`tool/staging.sh`)

```bash
tool/staging.sh verify                       # proyecto accesible y número 169151296960
tool/staging.sh deploy firestore:indexes     # esperar estado READY
tool/staging.sh deploy auth,firestore:rules
tool/staging.sh deploy functions             # requiere Blaze
tool/staging.sh seed                         # ver "Datos de prueba"
tool/staging.sh build                        # FIREBASE_ENV=staging, SHOP_ID=barberia-staging, WEB_STAFF_PORTALS=true
tool/staging.sh deploy hosting               # rechaza un build/web que no sea de staging
```

Destinos permitidos: `auth`, `firestore`, `firestore:rules`,
`firestore:indexes`, `functions`, `hosting`.

Índices: los de `firestore.indexes.json` (ver `docs/BOOKING_SYSTEM.md`).
Estado: `https://console.firebase.google.com/project/barberia-staging/firestore/databases/-default-/indexes`.

## Datos de prueba

`backend/scripts/seed_staging.py` crea un tenant sintético: tienda
`barberia-staging`, admin + 2 barberos (barbero 2 solo por la tarde), 3
servicios de 30/60 min y almuerzo 12–13 del barbero 1 los próximos días
hábiles. Correos `@example.test`.

Salvaguardas: rechaza siempre producción (`PRODUCTION_PROJECTS`), solo
acepta proyectos reales de `STAGING_PROJECTS` con `--confirm-project`,
rechaza emuladores a medias, exige shop con prefijo de prueba, ids fijos
(idempotente), no toca reservas ni otros tenants.

```bash
# Contraseñas: generadas al azar, fuera del repo (chmod 600)
set -a; . ~/.barberia-staging/credentials.env; set +a
# Credenciales: ADC (gcloud auth application-default login) o un access
# token de corta duración en GOOGLE_OAUTH_ACCESS_TOKEN
tool/staging.sh seed
```

Las reservas se crean solo con `reserveSlot` (Functions), no por el seed.

## Prueba local con emuladores

```bash
firebase emulators:start --only auth,firestore,functions,hosting --project demo-barberia
FIRESTORE_EMULATOR_HOST=localhost:8080 FIREBASE_AUTH_EMULATOR_HOST=localhost:9099 \
  SEED_ADMIN_PASSWORD=... SEED_BARBER_PASSWORD=... \
  python backend/scripts/seed_staging.py --project demo-barberia
flutter build web --release --dart-define=FIREBASE_ENV=demo \
  --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=E2E_SEMANTICS=true \
  --dart-define=SHOP_ID=barberia-staging
# http://localhost:5000
```

## Prueba de aceptación en Chrome (contra https://barberia-staging.web.app)

A. Cliente: barbero → servicio → fecha → hora → datos sintéticos → resumen →
   confirmar → mensaje de éxito → documento en `bookings`.
B. Mismo barbero y hora otra vez → rechazado.
C. Admin (`admin.barberia-staging@example.test`): la reserva aparece con datos correctos.
D. Barbero asignado: aparece en su día; el otro barbero no la ve.
E. Cancelar → el slot vuelve a estar disponible.
F. Datos inválidos, horario bloqueado (12:00 barbero 1), permisos.

No dar la prueba por aprobada si se ejecutó contra emuladores.

## Rollback

- Hosting: `firebase hosting:clone barberia-staging:live@<versión-anterior> barberia-staging:live`
  o "Rollback" en la consola de Hosting.
- Reglas: volver a desplegar el `firestore.rules` del commit anterior
  (`git checkout <sha> -- firestore.rules && tool/staging.sh deploy firestore:rules`).
- Functions: desplegar el commit anterior con `tool/staging.sh deploy functions`.
- Datos: el tenant es sintético; se puede volver a sembrar en cualquier momento.

## Resultado de la aceptación en Chrome (2026-11-22)

Ejecutada con Playwright + Google Chrome contra https://barberia-staging.web.app:

| Escenario | Resultado | Evidencia |
|---|---|---|
| A. Reserva de cliente | OK | `ck8fIq5YBvyb2uZgsSaz` (Carlos, Corte Clásico, mar 24 10:00) persistida en `bookings` |
| B. Duplicado / carrera | OK | 10:00 ya no se ofrece; carrera en 10:30 y 11:00 → HTTP 409 y "Ese horario ya fue reservado por otro cliente. Elige otro."; sin documento duplicado |
| C. Portal admin | OK (tras corrección) | reserva visible con datos correctos; "Próxima cita" correcta |
| D. Portal barbero | OK (tras corrección) | aparece el martes 24 en orden; el barbero 2 no ve nada |
| E. Cancelación | OK | admin cancela con confirmación → `status: cancelled`; 10:00 vuelve a ofrecerse y se reserva otra vez (`IJ4mCm1MJIAicpBhaYU1`) |
| F. Validación y errores | OK | domingo sin horarios, almuerzo bloqueado, nombre/teléfono inválidos, `/admin/portal` anónimo → `/login`, contraseña errónea con mensaje |

Defectos encontrados y corregidos en esta corrida: enlace "Acceso Personal"
roto en web pública, router que mandaba al staff a `/` tras iniciar sesión,
"Próxima cita" y cola del barbero mal ordenadas, encabezado del horario fijo
en hoy.

Notas para automatizar Flutter Web: activar el árbol de accesibilidad
(`flt-semantics-placeholder`), escribir con el teclado (no `fill`) y
verificar el valor, y no hacer clic por coordenadas en campos de texto.

## Limitaciones conocidas

- Cuota anti-abuso de `reserveSlot`: 3 reservas por teléfono y hora; usar
  teléfonos sintéticos distintos en pruebas repetidas.
- "Próximo espacio disponible: 16:00 (30m)" en el portal del barbero es un
  texto fijo de maqueta (no se calcula).
- La lista de reservas del admin se ordena por creación y las tarjetas no
  muestran la fecha, solo la hora.
- Correos de invitación/restablecimiento por SendGrid no configurados en
  staging (`SENDGRID_*`); el restablecimiento estándar de Firebase Auth sí.
- App Check desactivado (`ENFORCE_APP_CHECK=false`).
