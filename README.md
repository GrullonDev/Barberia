# Barbería (Booking App)

Aplicación multi-plataforma (Android, iOS, Web, Desktop) para reservar servicios de barbería en pocos pasos. Incluye selección de servicios, calendario con slots, formulario de datos del cliente, confirmación con QR geolocalizado e integración para añadir la cita al calendario (.ics).

---
## Tabla de Contenido
1. Visión General
2. Características Implementadas
3. Stack Técnico
4. Estructura de Carpetas
5. Arquitectura & Estado
6. Localización (i18n)
7. Flujo de Reserva (UX resumido)
8. Configuración de Ubicación / QR
9. Calendario e ICS
10. Requisitos / Versiones mínimas
11. Puesta en Marcha (Running)
12. Scripts / Comandos Útiles
13. Estándares de Código & Lints
14. Pruebas
15. Roadmap / Próximos Pasos
16. Cómo Contribuir
17. Licencia (placeholder)

---
## 1. Visión General
El objetivo es ofrecer un flujo de reserva fluido y rápido sin necesidad de registro, manteniendo buenas prácticas de accesibilidad, internacionalización y separación de responsabilidades.

## 2. Características Implementadas
- Catálogo de servicios con filtros básicos.
- Selección de fecha y hora (TableCalendar + slots agrupados mañana/tarde).
- Resumen contextual antes de confirmar.
- Formulario de datos (nombre + teléfono / email) con validaciones.
- Opt‑in para recordatorios (persistencia local de preferencia).
- Pantalla de Privacidad (placeholder localizada + versión/fecha).
- Pantalla de confirmación con:
	- Código de cita (badge).
	- QR que abre Google Maps con coordenadas reales de prueba + fragmento con metadatos (id, servicio, fecha ISO8601).
	- Botones copiar / compartir enlace.
	- Fallback Maps → Waze → navegador.
	- Exportación a calendario mediante archivo `.ics` (MIME `text/calendar`).
- Página "Mis Citas" con animaciones y CTA según estado (nueva cita / ir al inicio).
- Persistencia ligera de borrador de formulario (SharedPreferences).
- Localización español / inglés (intl + gen_l10n).

## 3. Stack Técnico
- Flutter SDK (Dart >= constraint en `pubspec.yaml`: `sdk: ^3.9.0`).
- State Management: Riverpod (`flutter_riverpod`).
- Ruteo: `go_router`.
- Internacionalización: `intl` + generación automática (`flutter gen-l10n`).
- UI & Animaciones: Material 3 + `flutter_animate`.
- Almacenamiento local: `shared_preferences`.
- Calendario: `table_calendar`.
- QR: `qr_flutter`.
- Compartir & archivos: `share_plus`, `path_provider`.
- Markdown (privacidad futura): `flutter_markdown` + `http` (fetch remoto placeholder pendiente).
- Utilidades: `url_launcher` (Maps/Waze), validadores custom.

## 4. Estructura de Carpetas (resumen)
```
lib/
	app/            -> Router, tema futuro
	common/         -> Config, utils, prefs
	features/
		booking/
			models/     -> Entidades (Booking, BookingDraft, Service...)
			providers/  -> Riverpod providers
			pages/      -> UI screens (calendar, details, confirmation, my bookings)
			widgets/    -> Componentes reutilizables (cards, chips...)
		static/       -> Pantallas estáticas (Privacidad)
	l10n/           -> ARB locale files + generado
```

## 5. Arquitectura & Estado
- Patrón por features (modular, favorece escalabilidad).
- Riverpod para estado derivado, lectura reactiva y testabilidad.
- `BookingDraft` acumula pasos antes de concretar `Booking` final (evita estados parciales). Al confirmar se agrega a `bookingsProvider` y se limpia el draft.
- Config centralizada: `LocationConfig` (dirección + coordenadas + builders de URIs).

## 6. Localización (i18n)
- Archivos ARB: `lib/l10n/app_es.arb`, `app_en.arb`.
- Clase generada: `S` (`l10n.yaml` define output).
- Para añadir traducciones: agregar clave a ambos ARB, luego ejecutar:
	```bash
	flutter gen-l10n
	```
- Evitar textos literales en widgets nuevos. Reutilizar claves existentes (ej. `appointment_rebook_soon`).

## 7. Flujo de Reserva (UX)
1. Home / Servicios → seleccionar servicio.
2. Calendario → elegir fecha & slot.
3. Datos del cliente → validación + opt‑in recordatorios.
4. Confirmación → QR + opciones de compartir + exportar .ics.
5. Mis Citas → listado de reservas (futuro: reprogramar / cancelar real).

## 8. Configuración de Ubicación / QR
- Archivo: `lib/common/config/location_config.dart`.
- Fragmento del QR incluye: `appt`, `svc`, `dt`. Puede servir para una mini landing futura (short link o deep link propio).
- Fallback de navegación: Google Maps → Waze → navegador.

## 9. Calendario e ICS
- Slots simples (display) sin lógica de disponibilidad remota aún.
- Generación ICS en modelo `Booking` (`toIcsString()`): incluye UID básico y rango horario.
- Exportación: se escribe archivo temporal y se comparte con `share_plus` para mejor compatibilidad con apps de calendario.

## 10. Requisitos / Versiones mínimas
- Dart SDK: `>=3.9.0 <4.0.0` (según `environment` en `pubspec.yaml`).
- Flutter: versión estable compatible con ese rango de Dart (ej. 3.24.x o superior que soporte Dart 3.9). Verifica con:
	```bash
	flutter --version
	```
- Plataformas soportadas: Android, iOS, Web, macOS, Windows, Linux (módulos generados por `flutter create`).

## 11. Puesta en Marcha
```bash
# Instalar dependencias
flutter pub get

# (Opcional) Regenerar l10n tras añadir claves
flutter gen-l10n

# Ejecutar (ejemplo Android conectado)
flutter run

# Ejecutar pruebas
flutter test
```

## 12. Scripts / Comandos Útiles
```bash
flutter analyze              # Lints
flutter pub outdated         # Ver paquetes desactualizados
flutter clean && flutter pub get  # Reset rápido
```

## 13. Estándares de Código & Lints
- Basado en `flutter_lints` (puede ampliarse). 
- Preferir widgets `const` siempre que sea viable.
- Evitar usar `BuildContext` tras `await` (capturar valores previamente) para reducir `use_build_context_synchronously`.
- Nombres de rutas centralizados en `RouteNames`.

## 14. Pruebas
- Carpeta `test/` (actualmente ejemplos mínimos). 
- Sugerido: añadir pruebas para conflicto de horarios, form validators, generación ICS, providers de reprogramación futura.

## 15. Roadmap / Próximos Pasos
- Reprogramar / cancelar (acciones reales + estados `canceled`).
- Capa de persistencia durable (local DB / backend real).
- Mini landing (short link) al escanear QR (decodificar fragmento y mostrar estado en web).
- Remote Config / fetch dinámico de ubicación y política de privacidad (cache + ETag / TTL).
- Cache markdown de privacidad + fallback offline.
- Tests unitarios e integración adicionales (Golden tests para páginas clave).
- Tematización avanzada y dark mode refinado.

## 16. Cómo Contribuir
1. Crea rama desde `develop` (ej: `feature/short-link-landing`).
2. Aplica cambios con commits descriptivos (convención sugerida: `feat:`, `fix:`, `refactor:`, `chore:`, `docs:`).
3. Corre `flutter analyze` y `flutter test` antes de abrir PR.
4. Asegura traducciones en ambos ARB para cualquier texto nuevo.
5. Incluye notas en el PR sobre decisiones técnicas y capturas si corresponde.

### Estilo de Mensajes de Commit
```
feat: añade fallback a Waze en confirmación
fix: corrige validación de email en formulario de datos
```

## 17. Licencia
Actualmente sin licencia explícita. (Añadir una: MIT / Apache-2.0 / Propietaria según necesidades). 

---
### Preguntas / Soporte
Crear un issue describiendo contexto, pasos para reproducir y resultado esperado.

---
Este README se mantendrá actualizado conforme avancen las funcionalidades y arquitectura.
