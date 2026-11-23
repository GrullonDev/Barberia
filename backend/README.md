# Backend — Cloud Functions (Python)

Funciones `firebase-functions` v2 del proyecto **barbershop-ee9c0**.

## Estructura

```
backend/
└── functions/
    ├── main.py              # onCall functions: reserveSlot, getAvailability
    ├── slot_engine.py       # lógica pura de disponibilidad (testable)
    ├── requirements.txt     # deps pinneadas
    └── .gitignore
```

## Setup local (una vez)

Necesitas Python **3.11+** y Firebase CLI **13+**.

```bash
# Desde la raíz del repo
cd backend/functions
python3.11 -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

El venv está ignorado por `.gitignore`; cada dev se crea el suyo.

## Emulador (desarrollo)

Levantar Firestore + Functions + Auth en local:

```bash
# Raíz del repo
firebase emulators:start --only auth,firestore,functions
```

La UI queda en http://localhost:4000.

Para que Flutter use el emulador en debug, añade en `main.dart` antes de
`runApp`:

```dart
if (kDebugMode) {
  await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
}
```

(No está activo por defecto porque rompe el flow de producción.)

## Deploy a producción

```bash
firebase deploy --only functions
```

Primera vez desplegando Python en este proyecto: Firebase CLI pedirá
habilitar la API de Cloud Build y Cloud Functions 2nd gen — acepta.

Región configurada: `us-central1` (ver `options.set_global_options` en
`main.py`). Si necesitas cambiarla, redeploya con la nueva región.

## Probar `reserveSlot` con `curl`

Las funciones callable usan el wire protocol de Firebase. El formato no es
un REST puro: el payload va dentro de `{ "data": {...} }` y el auth va en
header `Authorization: Bearer <idToken>`. Ejemplo:

```bash
TOKEN=$(firebase auth:export --format=json ... | jq -r '.users[0].idToken')
curl -X POST \
  https://us-central1-barbershop-ee9c0.cloudfunctions.net/reserveSlot \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "barberId": "BARBER_ID",
      "serviceId": "SERVICE_ID",
      "startAtIso": "2026-04-20T14:00:00Z",
      "customerName": "Jorge",
      "customerPhone": "+50212345678"
    }
  }'
```

## Testing de `slot_engine.py`

La lógica pura (sin Firestore) se puede testear con `pytest`:

```bash
cd backend/functions
source venv/bin/activate
pip install pytest
pytest tests/      # TODO: añadir tests
```

## Contratos

### `reserveSlot(data) → { bookingId, endAtIso }`

Input mínimo:

```json
{
  "barberId": "str",
  "serviceId": "str",
  "startAtIso": "2026-04-20T14:00:00Z",
  "customerName": "Jorge",
  "customerPhone": "+50212345678",
  "customerEmail": null,
  "notes": null,
  "userId": null
}
```

Errores (`FunctionsErrorCode`):

| Código               | Significado                                                   |
|----------------------|---------------------------------------------------------------|
| `invalid-argument`   | Falta un campo requerido o tiene formato inválido             |
| `not-found`          | barberId o serviceId no existen                               |
| `failed-precondition`| Barbero no disponible, servicio inactivo, fuera de horario, o cliente bloqueado por reputación |
| `already-exists`     | Ese slot ya tiene booking activo — el cliente debe elegir otro |

### `getAvailability(data) → { slots: [ISO], slotMinutes, durationMinutes }`

Read-only. Para pintar el calendario sin lecturas masivas en el cliente.
