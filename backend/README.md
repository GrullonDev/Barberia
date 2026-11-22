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

## Contratos, esquema y pruebas

La referencia verificada del sistema de reservas — contratos de
`getAvailability`/`reserveSlot`, códigos de error, esquema canónico de
`bookings`, invariante de concurrencia, índices y comandos de prueba — está
en [`docs/BOOKING_SYSTEM.md`](../docs/BOOKING_SYSTEM.md).

Resumen de pruebas:

```bash
# Unitarias (sin emulador)
cd backend/functions && python -m pytest tests

# Integración contra emuladores (desde la raíz del repo)
firebase emulators:exec --only auth,firestore --project demo-barberia \
  "python -m pytest backend/tests -q"
```
