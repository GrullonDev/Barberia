"""Seed/actualización idempotente de datos para demo en vivo.

Prepara `barbershop-ee9c0` para que el flujo de reserva (booking_page.dart
-> BookingRepository -> Cloud Functions reserveSlot/getAvailability) tenga
datos reales con los que trabajar, en vez de los catálogos hardcodeados que
se eliminaron del cliente.

Toca dos cosas:

1. config/barberia
   - Fuerza `timezoneOffsetHours: -6` (Guatemala) SIEMPRE, porque
     `slot_engine.is_within_working_hours`/`generate_candidates` ya no
     tienen ese valor hardcodeado — lo leen de aquí (ver main.py:_load_config).
   - Agrega `branding` y `businessHours` SOLO SI NO EXISTEN — no pisa
     personalización que el admin ya haya hecho desde el portal. Estos dos
     campos hoy no los lee ningún código (ni config_provider.dart ni
     main.py); quedan como base para cuando se construya esa UI.

2. services/{id}
   - 3 documentos con ID semántico (idempotentes: re-ejecutar el script no
     duplica nada, usa `set(..., merge=True)`).
   - Nota importante: el campo de duración se llama `durationMinutes`
     (no `serviceDurationMinutes` — ese es el nombre que usa el booking ya
     RESERVADO, como snapshot, dentro de `bookings/{id}`). El motor de
     slots lee `durationMinutes` directo del documento de `services`
     (ver backend/functions/main.py:_load_service). Si se sembrara con el
     nombre equivocado, `reserveSlot` caería al default de 30 min en
     silencio.

Uso:
    cd backend/scripts
    pip install firebase-admin   # si no está ya instalado en tu entorno

    # Opción A: detección automática. El script busca, en este orden, en
    # backend/scripts/, backend/functions/ y la raíz del repo:
    #   - serviceAccountKey.json
    #   - *firebase-adminsdk*.json  (nombre real que descarga la consola de
    #     Firebase: "<project-id>-firebase-adminsdk-<hash>.json")
    # Ambos patrones ya están en .gitignore — NUNCA los commitees.
    python seed_demo_data.py [--dry-run]

    # Opción B: ruta explícita (si el archivo está en otro lado o con otro nombre).
    python seed_demo_data.py --credentials "C:\\ruta\\a\\tu-archivo.json" [--dry-run]

    # Opción C: variable de entorno estándar de Google (si ya la usas para
    # otros scripts de este repo, como migrate_barbers_to_users.py).
    GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json \\
        python seed_demo_data.py [--dry-run]

`--dry-run` imprime exactamente qué escribiría, sin tocar Firestore.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, firestore

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent

# Directorios donde se busca la credencial, en orden de prioridad.
_SEARCH_DIRS = [SCRIPT_DIR, SCRIPT_DIR.parent / "functions", PROJECT_ROOT]

# Nombres exactos conocidos, más el patrón que genera la consola de Firebase
# al descargar la clave: "<project-id>-firebase-adminsdk-<hash>.json"
# (ver .gitignore:156 — ya está excluido del repo con ese patrón).
_EXACT_NAMES = ("serviceAccountKey.json",)
_GLOB_PATTERNS = ("*firebase-adminsdk*.json",)


def _find_credential_file() -> Path | None:
    for directory in _SEARCH_DIRS:
        for name in _EXACT_NAMES:
            candidate = directory / name
            if candidate.exists():
                return candidate
        for pattern in _GLOB_PATTERNS:
            matches = sorted(directory.glob(pattern))
            if matches:
                return matches[0]
    return None

# -----------------------------------------------------------------------------
# Datos a sembrar
# -----------------------------------------------------------------------------

FORCED_CONFIG_FIELDS = {
    "timezoneOffsetHours": -6,
}

DEFAULT_BRANDING = {
    "primaryColor": "#C8C6C5",
    "secondaryColor": "#E9C349",
    "logoUrl": "",
}

_OPEN_CLOSE = {"open": "09:00", "close": "20:00"}
DEFAULT_BUSINESS_HOURS = {
    "monday": _OPEN_CLOSE,
    "tuesday": _OPEN_CLOSE,
    "wednesday": _OPEN_CLOSE,
    "thursday": _OPEN_CLOSE,
    "friday": _OPEN_CLOSE,
    "saturday": _OPEN_CLOSE,
    "sunday": {"open": "10:00", "close": "17:00"},
}

SERVICES: list[dict] = [
    {
        "id": "corte_premium",
        "name": "Corte Premium & Estilizado",
        "description": "Corte a la medida con consulta de estilo y acabado con productos premium.",
        "price": 125.00,
        "durationMinutes": 45,
        "isActive": True,
    },
    {
        "id": "perfilado_barba_toalla",
        "name": "Perfilado de Barba con Toalla Caliente",
        "description": "Perfilado de barba con navaja y tratamiento de toalla caliente.",
        "price": 75.00,
        "durationMinutes": 30,
        "isActive": True,
    },
    {
        "id": "combo_luxe",
        "name": "Combo Luxe (Corte + Barba)",
        "description": "Experiencia completa: corte premium y perfilado de barba en una sola cita.",
        "price": 175.00,
        "durationMinutes": 60,
        "isActive": True,
    },
]


def _init_app(explicit_path: str | None) -> None:
    if explicit_path:
        path = Path(explicit_path).expanduser().resolve()
        if not path.exists():
            print(f"[error] --credentials apunta a un archivo que no existe: {path}", file=sys.stderr)
            sys.exit(1)
        firebase_admin.initialize_app(credentials.Certificate(str(path)))
        print(f"[auth] Usando credenciales de servicio (--credentials): {path}")
        return

    found = _find_credential_file()
    if found is not None:
        firebase_admin.initialize_app(credentials.Certificate(str(found)))
        print(f"[auth] Usando credenciales de servicio: {found}")
        return

    # Sin archivo encontrado: cae a Application Default Credentials
    # (GOOGLE_APPLICATION_CREDENTIALS, o gcloud auth application-default login).
    firebase_admin.initialize_app()
    print("[auth] No se encontró un archivo de credenciales en "
          f"{[str(d) for d in _SEARCH_DIRS]}; usando Application Default Credentials.")


def seed_config(db, dry_run: bool) -> None:
    doc_ref = db.collection("config").document("barberia")
    snap = doc_ref.get()
    existing = snap.to_dict() or {}

    update: dict = dict(FORCED_CONFIG_FIELDS)  # siempre se fuerzan

    if "branding" not in existing:
        update["branding"] = DEFAULT_BRANDING
    if "businessHours" not in existing:
        update["businessHours"] = DEFAULT_BUSINESS_HOURS

    print("-" * 60)
    print(f"config/barberia ({'existe' if snap.exists else 'no existe, se creará'})")
    for key, value in update.items():
        already_had = key in existing
        action = "forzado (ya existía, se sobreescribe)" if key in FORCED_CONFIG_FIELDS and already_had \
            else "forzado (nuevo)" if key in FORCED_CONFIG_FIELDS \
            else "agregado (no existía)"
        print(f"  [{action}] {key} = {value}")

    skipped = [k for k in ("branding", "businessHours") if k in existing]
    for key in skipped:
        print(f"  [sin tocar] {key} ya existía, se preserva el valor actual")

    if not dry_run:
        doc_ref.set(update, merge=True)
        print("  -> escrito en Firestore (merge=True)")
    else:
        print("  -> dry-run, no se escribió nada")


def seed_services(db, dry_run: bool) -> None:
    print("-" * 60)
    print(f"services/* ({len(SERVICES)} documentos)")

    batch = db.batch()
    for service in SERVICES:
        doc_id = service["id"]
        data = {k: v for k, v in service.items() if k != "id"}
        ref = db.collection("services").document(doc_id)
        batch.set(ref, data, merge=True)
        print(f"  [set merge=True] services/{doc_id} -> name={data['name']!r}, "
              f"price={data['price']}, durationMinutes={data['durationMinutes']}, "
              f"isActive={data['isActive']}")

    if not dry_run:
        batch.commit()
        print(f"  -> batch de {len(SERVICES)} servicios confirmado atómicamente")
    else:
        print("  -> dry-run, no se escribió nada")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Imprime lo que haría sin escribir en Firestore.",
    )
    parser.add_argument(
        "--credentials",
        default=None,
        help="Ruta explícita al JSON de la cuenta de servicio (anula la búsqueda automática).",
    )
    args = parser.parse_args()

    _init_app(args.credentials)
    db = firestore.client()

    print("=" * 60)
    print("Seed de datos de demo — barbershop-ee9c0" + (" (DRY RUN)" if args.dry_run else ""))
    print("=" * 60)

    try:
        seed_config(db, args.dry_run)
        seed_services(db, args.dry_run)
    except Exception as e:  # noqa: BLE001
        print(f"[error] {e}", file=sys.stderr)
        sys.exit(1)

    print("=" * 60)
    print("Listo." if not args.dry_run else "Dry-run completado, nada fue escrito.")
    print("=" * 60)


if __name__ == "__main__":
    main()
