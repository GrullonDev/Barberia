# Estrategia de Plataformas — Web como sistema principal, móvil estable

> Estado: **vigente** · Última revisión: 2026-11-21

## 1. Decisión

El producto evoluciona hacia un **sistema web** como plataforma principal de
operación del negocio (reservas públicas **y** portales de staff), porque la
web ofrece mayor estabilidad operativa:

- Un único despliegue (Firebase Hosting) llega a todos los usuarios al
  instante — sin revisiones de tiendas, sin versiones viejas instaladas.
- Sin dependencia de SDKs nativos, permisos del sistema operativo ni
  fragmentación de dispositivos Android/iOS.
- Rollback inmediato desde Hosting si un release sale mal.
- Funciona en el equipo de recepción, tablet o laptop del barbero sin instalar nada.

**La app móvil no se elimina.** Sigue siendo un canal soportado. Sin embargo,
**la prioridad inmediata es estabilizar la app móvil** (hoy es el único canal
del staff) antes de mover la operación a la web. El orden importa: la web se
construye sobre una base que ya probamos estable en móvil, no al revés.

## 2. Principios

1. **Un solo código Flutter** para móvil y web. No se crea un segundo frontend.
2. **El backend es la fuente de verdad.** Toda regla de negocio crítica
   (disponibilidad, colisiones, reputación, alta/baja de barberos) vive en
   Cloud Functions + `firestore.rules`, nunca solo en la UI. Así la web y el
   móvil se comportan igual y la seguridad no depende del cliente.
3. **Las capacidades por plataforma se declaran en un solo lugar**
   (`lib/core/platform/platform_capabilities.dart`). Nada de `kIsWeb`
   repartido por las pantallas. Habilitar el staff en web debe ser un cambio
   de configuración, no una reescritura.
4. **Nada de dependencias muertas.** Cada plugin nativo es superficie de
   fallo en el build y en runtime. Si no se usa, se elimina.
5. **Cada fase termina con criterios medibles** (sección 5), no con "se ve bien".

## 3. Situación actual (punto de partida)

| Área | Móvil (Android/iOS) | Web |
| --- | --- | --- |
| Sitio público + reservas | Sí | Sí |
| Login de staff | Sí (ruta inicial `/login`) | **No** (bloqueado en el router) |
| Portal admin | Sí | **No** |
| Portal barbero | Sí | **No** |
| Página legacy `public/index.html` | — | Es lo que Hosting publica hoy; usa `config/barberia` (ya reemplazado por `shops/`) y escribe directo a `bookings`, lo que las reglas actuales deniegan |

Riesgos de estabilidad detectados en la revisión:

- `pubspec.yaml` declaraba `.env` como asset, pero `.env` está en
  `.gitignore`: **un clon limpio no compila** (corregido en Fase 1).
- 10 dependencias sin ningún uso en `lib/`, varias con código nativo
  (`flutter_local_notifications`, `add_2_calendar`, `connectivity_plus`,
  `share_plus`, `path_provider`, …) — riesgo de fallos de Gradle/CocoaPods y
  mayor tamaño de app sin beneficio (eliminadas en Fase 1).
- Sin pruebas: no hay carpeta `test/` y el motor de slots no tenía tests.
- `admin_portal_page.dart` (~4.100 líneas) y `barber_portal_page.dart`
  (~4.900 líneas) concentran UI, estado y acceso a Firestore en un solo
  archivo, con suscripciones `.listen` manuales. Es la principal fuente de
  fragilidad y el principal obstáculo para llevarlos a web.
- Release de Android firmado con la clave de debug.
- Sin CI: nada impide que un cambio que rompe `flutter analyze` llegue a `develop`.

## 4. Hoja de ruta

### Fase 1 — Estabilización móvil (ACTUAL)

Objetivo: que la app que usa hoy el staff no falle, y que cualquier
desarrollador pueda clonar, compilar y probar.

- [x] Quitar `.env` de los assets (build reproducible desde clon limpio).
- [x] Eliminar dependencias sin uso.
- [x] Tests del motor de slots (`backend/functions/tests`).
- [x] Tests Flutter base (capacidades por plataforma, utilidades).
- [x] Centralizar capacidades por plataforma (`PlatformCapabilities`).
- [x] CI en GitHub Actions: `flutter analyze`, `flutter test`, `pytest`.
- [x] Captura global de errores (`FlutterError.onError` /
      `PlatformDispatcher.onError`) + Firebase Crashlytics en móvil
      (`lib/core/observability/crash_reporting.dart`).
- [ ] Crashlytics iOS: agregar la fase de build que sube los dSYM
      (`flutterfire configure` en macOS) para ver stack traces simbolizados.
- [ ] Activar Crashlytics en la consola de Firebase y verificar un crash de prueba
      en Android e iOS.
- [ ] Firma de release Android con keystore propio (fuera del repo).
- [ ] Extraer de los portales los repositorios de datos (bookings, barberos,
      servicios, notificaciones) a `features/*/data/` con providers Riverpod
      (`StreamProvider`) en lugar de `.listen` manuales en widgets.
- [ ] Tests de widget para login de staff, redirecciones por rol y flujo de reserva.
- [ ] Probar en dispositivos reales: Android gama baja + iPhone, red lenta / offline.

**Criterio de salida:** 0 errores de `analyze`, CI verde, sin crashes
reportados en Crashlytics durante 2 semanas de uso real del staff.

### Fase 2 — Preparar la web (sin cambiar a los usuarios)

- [ ] Publicar el build de Flutter en Hosting (`hosting.public = build/web`)
      y retirar `public/index.html` legacy.
- [ ] Revisar layouts de los portales con `Responsive` (escritorio y tablet).
- [ ] Persistencia de sesión de Firebase Auth en web (`Persistence.LOCAL`)
      y cierre de sesión por inactividad para equipos compartidos.
- [ ] Canal de preview de Hosting (`firebase hosting:channel:deploy`) para QA.

### Fase 3 — Staff en web (beta)

- [ ] Activar `staffPortalsEnabled` en web (un solo flag en
      `PlatformCapabilities`) para un grupo piloto de admins.
- [ ] Notificaciones al admin vía web (FCM web o in-app) en lugar de las locales móviles.
- [ ] Recolectar feedback y medir errores frente a móvil.

### Fase 4 — Web como sistema principal

- [ ] La web pasa a ser el canal recomendado para administración.
- [ ] El móvil queda como canal complementario (agenda del barbero,
      notificaciones en movimiento) con el mismo código y backend.

## 5. Cómo medir "estable"

| Métrica | Meta |
| --- | --- |
| `flutter analyze` | 0 errores, 0 warnings nuevos |
| CI en `develop` | verde en cada merge |
| Sesiones sin crash (móvil) | ≥ 99,5 % |
| Reservas fallidas por error de cliente (no de negocio) | < 0,5 % |
| Tiempo de rollback web | < 5 min (Hosting) |

## 6. Qué NO hacemos por ahora

- No reescribir en otro framework web (React, etc.). Flutter Web cubre la
  necesidad y mantiene un solo código.
- No retirar la app de las tiendas.
- No abrir los portales de staff en web hasta cerrar la Fase 1.
