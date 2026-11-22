# Staging y pruebas end-to-end

## Estado actual (verificado 2026-11-22)

- El único proyecto Firebase de Barbería es **`barbershop-ee9c0`, que es
  producción**. Es el `default` de `.firebaserc` y el proyecto compilado en
  `lib/firebase_options.dart` (Android, iOS y Web).
- **No existe un proyecto de staging.** Hasta crearlo, cualquier
  `firebase deploy` o `flutter build web` apunta a producción.
- `backend/scripts/seed_staging.py` rechaza siempre `barbershop-ee9c0`
  (`PRODUCTION_PROJECTS`), aunque se pase `--confirm-project`.

## Entornos de la app Flutter

| Build | Firebase | Cómo |
|---|---|---|
| Release / por defecto | proyecto de `firebase_options.dart` | `flutter build web --release` |
| Emuladores locales | Auth 9099, Firestore 8080, Functions 5001 | `--dart-define=USE_FIREBASE_EMULATORS=true` (host: `FIREBASE_EMULATOR_HOST`, por defecto `localhost`) |
| Pruebas de navegador | igual + árbol de accesibilidad | `--dart-define=E2E_SEMANTICS=true` |

Ambos flags están en `lib/core/firebase/dev_environment.dart`, son `false` por
defecto y el compilador elimina el código de emuladores del build release.

El tenant público se fija con `--dart-define=SHOP_ID=<id>` (por defecto
`barberia`, el tenant de producción). El staff siempre usa el `shopId` de su
perfil `users/{uid}`, nunca el valor compilado.

## Prueba local completa (sin credenciales)

```bash
firebase emulators:start --only auth,firestore,functions,hosting --project demo-barberia
# en otra terminal:
FIRESTORE_EMULATOR_HOST=localhost:8080 FIREBASE_AUTH_EMULATOR_HOST=localhost:9099 \
  SEED_ADMIN_PASSWORD=... SEED_BARBER_PASSWORD=... \
  python backend/scripts/seed_staging.py --project demo-barberia
flutter build web --release --dart-define=USE_FIREBASE_EMULATORS=true \
  --dart-define=E2E_SEMANTICS=true --dart-define=SHOP_ID=barberia-staging
# Hosting del emulador sirve build/web en http://localhost:5000
```

Los proyectos `demo-*` nunca alcanzan servicios reales.

## Crear el proyecto de staging (pendiente, requiere al dueño de la cuenta)

1. Crear un proyecto **separado**, p. ej. `barberia-staging-<sufijo>`, en
   plan Blaze (Cloud Functions lo requiere). Habilitar Authentication
   (Email/Password), Firestore (misma región que producción) y Hosting.
2. Alias local: `firebase use --add` → elegir el proyecto → alias `staging`.
   No cambiar el `default`.
3. Configuración web de staging:
   `flutterfire configure --project=<staging-id> --platforms=web --out=lib/firebase_options_staging.dart`
   y seleccionar el archivo con un `--dart-define=FIREBASE_ENV=staging` en
   `main.dart`. Este archivo contiene solo claves públicas de cliente, pero
   no debe sustituir a `firebase_options.dart`.
4. Desplegar **siempre con `--project staging`** (nunca sin `--project`,
   porque el `default` es producción), en este orden:
   ```bash
   firebase deploy --project staging --only firestore:indexes
   # esperar a que los índices estén construidos
   firebase deploy --project staging --only firestore:rules,functions
   SEED_ADMIN_PASSWORD=... SEED_BARBER_PASSWORD=... \
     python backend/scripts/seed_staging.py --project <staging-id> --confirm-project <staging-id>
   flutter build web --release --dart-define=FIREBASE_ENV=staging --dart-define=SHOP_ID=barberia-staging
   firebase deploy --project staging --only hosting
   ```
5. Antes de cada deploy, verificar: `firebase use` muestra el alias activo,
   y `grep -o '<staging-id>' build/web/main.dart.js` coincide con el destino.

El seed es idempotente (ids fijos derivados de `--shop`), solo escribe en
su tenant (`shopId` con prefijo `barberia-staging`, `staging-` o `test-`),
no toca reservas existentes y las contraseñas salen del entorno. Lo cubre
`backend/tests/test_seed_staging_emulator.py`.

## Prueba de aceptación en Chrome (contra staging desplegado)

Reservar como cliente (barbero → servicio → fecha/hora → datos sintéticos →
confirmar), verificar el documento en `bookings`, la agenda del admin y del
barbero, intentar reservar el mismo slot otra vez (debe rechazarse) y
cancelar. No dar la prueba por aprobada si se ejecutó contra emuladores.
