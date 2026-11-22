# Sistema de reservas — arquitectura verificada

Este documento describe lo que el repositorio implementa hoy (rama
`fix/barberia-booking-stability`). Todo lo marcado como *verificado* tiene
un test automatizado que lo ejercita; ver [Pruebas](#pruebas).

## Arquitectura

```
Flutter (web pública / móvil staff)
  BookingPage ──► BookingRepository ──► BookingBackend
                                        ├─ Firestore (lectura pública)
                                        │    barber_directory, services, shops
                                        └─ Cloud Functions (callable)
                                             getAvailability, reserveSlot
  AdminPortalPage / BarberPortalPage ──► Firestore (listeners en vivo)
                                        bookings, notifications, schedule_blocks
                                        └─ staffBooking(): proyección común

Cloud Functions (Python, backend/functions)
  main.py          → declaraciones de funciones
  booking_api.py   → validación, transacción de reserva, cuotas, idempotencia
  slot_engine.py   → lógica pura de slots y ocupación
  barber_directory.py → proyección pública de perfiles de barbero
```

- Los clientes **nunca** escriben en `bookings` ni `notifications`; las
  reglas lo deniegan. Toda reserva pasa por `reserveSlot` (Admin SDK).
- El “agregar reserva” del portal admin abre el mismo flujo público
  (`/booking`), así que también pasa por `reserveSlot`.
- Staff (admin del shop, barbero asignado) solo puede cambiar estado,
  notas y campos de check-in de una reserva existente.

## Esquema canónico de `bookings/{id}`

Escrito por `reserveSlot` (`booking_api.reserve`):

| Campo | Tipo | Notas |
|---|---|---|
| `shopId` | string | Tenant. Validado contra el barbero **y** el servicio. |
| `barberId` | string | uid del barbero (`users/{uid}`, `role == "barber"`). |
| `userId` | string | `request.auth.uid` o `"guest"`. Nunca viene del payload. |
| `serviceId`, `serviceName`, `serviceDurationMinutes`, `servicePrice` | | Snapshot del servicio al reservar. |
| `startAt`, `endAt` | Timestamp (UTC) | **Fuente de verdad** del horario. |
| `status` | string | Minúsculas al escribir: `pending`, `confirmed`, `live`, `completed`, `cancelled`, `noshow`. |
| `customerName`, `customerPhone` (E.164), `customerEmail`, `phoneNormalized`, `notes` | | Datos del cliente validados server-side. |
| `createdAt`, `updatedAt` | server timestamp | |

Campos legacy que se siguen escribiendo para compatibilidad de lectura:
`date` (= `startAt`), `time` (`"10:00 AM"` en hora local del negocio),
`clientName`, `clientPhone`, `clientEmail`, `service`, `price`, `barberName`.

### Reservas legacy

Documentos antiguos pueden tener solo `date` + `time` y estados en
mayúsculas (`CONFIRMED`, `FINISHED`, `inProgress`). Se soportan sin migrar:

- **Backend** (`slot_engine.bookings_to_ranges`): estado case-insensitive;
  sin `startAt` se usa el día local de `date` a la hora `time`; sin `endAt`
  se usa `serviceDurationMinutes` o 30 min.
- **Portales** (`lib/core/providers/staff_booking.dart`): `staffBooking()`
  prefiere los campos canónicos y cae a los legacy; `staffStatus()` unifica
  todas las grafías (`FINISHED`→`COMPLETED`, `no_show`→`NOSHOW`, …).

No se requiere migración destructiva. `backend/scripts/*` soportan
`--dry-run`.

### Zona horaria

Fechas se guardan en UTC. El día de negocio y las horas mostradas usan
`shops/{shopId}.timezoneOffsetHours` (default `-6`, Guatemala, sin horario de
verano), tanto en backend (`booking_api.shop_timezone`) como en Flutter
(`appConfigProvider.timezoneOffsetHours`, `bookingCalendarDay`). Nunca se usa
la zona del dispositivo.

## Ciclo de vida

```
reserveSlot ─► pending ─► confirmed ─► live ─► completed
                  │            │          │
                  └────────────┴──────────┴─► cancelled | noshow
```

- Ocupan agenda: `pending`, `confirmed`, `live` (y alias legacy `active`,
  `inProgress`).
- Terminales (liberan el slot): `completed`/`finished`, `cancelled`,
  `noshow`. Las reglas impiden que staff reactive una reserva terminal —
  reactivarla ocuparía un slot fuera de la transacción con guardia.
- El cliente autenticado dueño puede cancelar (`pending`/`confirmed` →
  `cancelled`). Las reservas `guest` las cancela el staff.

## Contratos de Cloud Functions

### `getAvailability`

```json
{ "shopId": "str", "barberId": "str", "serviceId": "str", "dateLocal": "2026-01-05" }
```

Respuesta: `{ "slots": ["2026-01-05T15:00:00Z", …], "slotMinutes": 30, "durationMinutes": 45 }`.
`dateIso` (instante ISO con zona) se acepta como alternativa legacy a
`dateLocal`. Solo devuelve slots futuros.

### `reserveSlot`

```json
{
  "shopId": "str", "barberId": "str", "serviceId": "str",
  "startAtIso": "2026-01-05T15:00:00Z",
  "customerName": "2–100 caracteres",
  "customerPhone": "8 dígitos GT o E.164",
  "customerEmail": "opcional",
  "notes": "opcional, ≤500",
  "idempotencyKey": "[A-Za-z0-9_-]{16,128}"
}
```

Respuesta: `{ "bookingId": "str", "endAtIso": "…Z" }`. Repetir la misma
`idempotencyKey` con el mismo payload devuelve la misma reserva.

| Código | Significado |
|---|---|
| `invalid-argument` | Payload mal formado (ids, teléfono, correo, hora sin zona, clave). |
| `not-found` | Shop, barbero o servicio inexistente. |
| `failed-precondition` | Cruce de tenant, servicio/barbero/shop inactivo, fuera de horario o de la grilla, hora pasada, cliente bloqueado, o clave reutilizada con otro payload. |
| `already-exists` | El intervalo choca con una reserva activa o un bloqueo. |
| `resource-exhausted` | Cuota: 3/h por teléfono, 8/h por usuario autenticado, 20/h por red para invitados (por shop). |
| `aborted` | Contención agotó los reintentos; nada se escribió. Reintentar con la **misma** clave. |

La app mapea cada código a un mensaje localizado; en `already-exists` y
`failed-precondition` vuelve a la agenda y recarga disponibilidad.

## Invariante de concurrencia

> Para un (shopId, barberId, día local) solo una transacción de
> `reserveSlot` puede confirmar a la vez, y decide sobre una vista
> consistente de las reservas y bloqueos de ese día.

Cada transacción lee **y escribe** `booking_guards/{sha256(shop, barber, día)}`.
Firestore serializa transacciones read-write sobre el mismo documento, así
que dos reservas concurrentes del mismo barbero/día no pueden confirmar
ambas: la perdedora se reintenta, relee la reserva ganadora y falla con
`already-exists` si se solapan. Como ningún slot cruza la medianoche local,
un guardia por día cubre cualquier solapamiento, para cualquier duración.
Barberos y tenants distintos usan guardias distintos y no se bloquean.

Otras escrituras que crean ocupación están cerradas: las reglas niegan
`create` de bookings desde el cliente y la reactivación de estados
terminales. **Limitación conocida:** `schedule_blocks` los crea staff desde
el cliente sin pasar por el guardia; un bloqueo creado en el mismo instante
que una reserva puede quedar solapado (decisión de staff, no doble reserva).

**Vivacidad bajo contención.** El cliente Python reintenta transacciones
abortadas sin espera, confiando en que Firestore conserve su turno
(`retry_transaction`). En el emulador eso no ocurre: con 8 solicitudes
simultáneas al mismo slot se observó que *todas* agotaban los reintentos
(`aborted`, ninguna reserva — seguro, pero sin progreso). `reserve` ejecuta
hasta 5 rondas de 5 intentos con espera aleatoria exponencial entre rondas
(≤ 1 s); si aun así no confirma, responde `aborted` y la app permite
reintentar con la misma clave.

Verificado en el emulador: 8 reservas simultáneas del mismo slot → 1 éxito;
carreras con duraciones mixtas solapadas → nunca dos intervalos solapados;
barberos/tenants distintos en paralelo → todos confirman.

## Índices requeridos

Declarados en `firestore.indexes.json`:

| Colección | Campos | Usado por |
|---|---|---|
| bookings | barberId ↑, startAt ↑ | ocupación del día (backend) |
| bookings | barberId ↑, date ↑ | ocupación de reservas legacy (backend) |
| schedule_blocks | barberId ↑, endTime ↑ | bloqueos que tocan el día (backend) |
| notifications | shopId ↑, createdAt ↓ | feed del admin |
| notifications | shopId ↑, barberId ↑, createdAt ↓ | feed del barbero |

(Más índices previos de `userId/date`, `status/date`, `walkins`.)

## Pruebas

| Suite | Comando | Cubre |
|---|---|---|
| Python unit | `cd backend/functions && python -m pytest tests` | motor de slots, validación de payload, horario, zona, estados, legacy |
| Emulador: reservas | `firebase emulators:exec --only firestore --project demo-barberia "python -m pytest backend/tests/test_booking_emulator.py"` | ciclo completo, colisiones, concurrencia, cancelación, bloqueos, cross-tenant, idempotencia, cuotas |
| Emulador: reglas | `firebase emulators:exec --only auth,firestore --project demo-barberia "python -m pytest backend/tests/test_firestore_rules.py"` | aislamiento de tenant, barbero vs barbero, escalamiento de rol, colecciones solo-servidor |
| Flutter | `flutter test` (CI: `--platform chrome`) | repositorio, filtros por shop, flujo de BookingPage, validación, doble envío, reintento idempotente, proyección staff |

Requisitos locales: Python 3.11 con `pip install -r backend/functions/requirements.txt pytest`,
Java 21 y Firebase CLI para emuladores. CI (`.github/workflows/ci.yml`)
ejecuta todas las suites más `flutter build web --release` y
`flutter build apk --debug`.

## Plataformas

- **Web** (plataforma pública principal): `flutter build web --release`.
- **Android**: Flutter 3.50 exige Gradle ≥ 9.3.1, AGP ≥ 9.1.1 y KGP ≥ 2.4.10;
  el proyecto usa Gradle 9.5.0, AGP 9.3.1, KGP 2.4.20 (valores del template
  de Flutter 3.50). Si el repo vive en un volumen **exFAT/FAT** de macOS, el
  build falla con `._drawable-… is not a directory`: macOS crea archivos
  AppleDouble `._*` que AGP no tolera. Compilar desde un disco APFS.
- **iOS**: mínimo iOS 15.0 (Firebase iOS SDK 12, requerido por
  `firebase_core` 4.x). Verificado con
  `flutter build ios --simulator --debug --no-codesign`. Firmar para
  dispositivo/App Store requiere un equipo de Apple Developer y perfiles
  (no configurados en el repo). Si `pod install` reporta specs
  desactualizadas, ejecutar `pod repo update`.

## Prerrequisitos de despliegue

1. `firebase deploy --only firestore:indexes` y esperar a que los índices
   estén construidos **antes** de desplegar funciones.
2. `firebase deploy --only firestore:rules`.
3. `firebase deploy --only functions` (crea `syncBarberDirectory`).
4. Ejecutar `python backend/scripts/migrate_barber_directory.py --dry-run`,
   revisar, y luego sin `--dry-run` para sincronizar perfiles públicos.
5. Cada `shops/{id}` debe tener `timezoneOffsetHours` entero y horario
   (`openHour`/`closeHour` enteros, `openDays` de 7 booleanos) válido;
   `status` ausente se trata como `active`.
6. Recomendado: habilitar App Check en las callables públicas (no
   implementado) para reforzar la protección anti-abuso.
