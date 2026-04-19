"""Cloud Functions (Python v2) del backend de Barbería.

Funciones disponibles:
    - reserveSlot(data, context)
        Callable. Crea una reserva atómicamente (transacción Firestore).
        Valida contra bookings existentes, schedule_blocks, working_hours,
        reputación del teléfono y existencia del servicio.
        Usa el Admin SDK, bypass de Firestore rules — las reglas bloquean
        la creación directa por cliente, así que esta es la única puerta.

    - getAvailability(data, context)
        Callable read-only. Dada (barberId, dateIsoUtc, serviceId) devuelve
        la lista de horarios libres (ISO UTC) que el cliente puede pintar
        en el calendario.

Convenciones:
    - Todas las fechas se transportan en ISO 8601 UTC (sufijo "Z" o "+00:00").
    - El cliente manda `customerPhone` crudo; la función normaliza a E.164.
    - El booking se escribe con TODOS los campos v2 (startAt, endAt,
      serviceDurationMinutes, servicePrice, phoneNormalized, createdAt,
      updatedAt, status='pending').
"""

from __future__ import annotations

import re
from datetime import datetime, timedelta, timezone
from typing import Any

import firebase_admin
from firebase_admin import firestore
from firebase_functions import https_fn, options
from google.cloud.firestore_v1.base_query import FieldFilter
from google.cloud.firestore_v1.transaction import Transaction

from slot_engine import (
    OCCUPYING_STATUSES,
    TimeRange,
    blocks_to_ranges,
    bookings_to_ranges,
    generate_candidates,
    has_conflict,
    is_within_working_hours,
)

# Región: us-central1 es default de Firebase Functions. Para un negocio
# guatemalteco, us-east1 o southamerica-east1 serían marginalmente más
# rápidos; se puede cambiar en un segundo deploy.
options.set_global_options(region="us-central1", max_instances=10)

firebase_admin.initialize_app()


# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------


_PHONE_DIGITS = re.compile(r"\D+")


def normalize_phone(raw: str | None) -> str | None:
    """Replica el comportamiento de Dart `phone_normalizer.dart`.

    Acepta entradas como '+502 1234 5678', '12345678', '50212345678'
    y devuelve '+50212345678' si hay 8 dígitos locales.
    """
    if not raw:
        return None
    digits = _PHONE_DIGITS.sub("", raw)
    if digits.startswith("502") and len(digits) == 11:
        return "+" + digits
    if len(digits) == 8:
        return "+502" + digits
    if digits.startswith("00"):
        digits = digits[2:]
        return "+" + digits if len(digits) >= 10 else None
    if len(digits) >= 10:
        return "+" + digits
    return None


def _parse_iso_utc(value: str) -> datetime:
    """Parsea ISO 8601; acepta sufijo Z."""
    if value.endswith("Z"):
        value = value[:-1] + "+00:00"
    dt = datetime.fromisoformat(value)
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def _require(data: dict[str, Any], keys: list[str]) -> None:
    missing = [k for k in keys if data.get(k) in (None, "")]
    if missing:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message=f"Campos requeridos: {', '.join(missing)}",
        )


def _load_barber_working_hours(
    db, barber_id: str, iso_weekday: int
) -> list[int] | None:
    """Lee workingHours del barbero para el día de la semana dado.

    `iso_weekday` sigue la convención ISO/Dart (1=Mon .. 7=Sun) para
    coincidir con el modelo Barber de Flutter y con el persistido en
    Firestore (keys string "1".."7"). El caller se encarga de convertir
    desde `datetime.weekday()` (0..6) haciendo `+1`.

    Estructura esperada: {"1": [9, 19], "2": [9, 19], ..., "7": null}
    """
    snap = db.collection("barbers").document(barber_id).get()
    if not snap.exists:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.NOT_FOUND,
            message=f"Barbero {barber_id} no existe.",
        )
    data = snap.to_dict() or {}
    if not data.get("isAvailable", True):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
            message="Barbero no disponible.",
        )
    wh = (data.get("workingHours") or {}).get(str(iso_weekday))
    return wh if isinstance(wh, list) else None


def _load_service(db, service_id: str) -> dict[str, Any]:
    snap = db.collection("services").document(service_id).get()
    if not snap.exists:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.NOT_FOUND,
            message=f"Servicio {service_id} no existe.",
        )
    data = snap.to_dict() or {}
    if not data.get("isActive", True):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
            message="Servicio inactivo.",
        )
    return data


def _load_config(db) -> dict[str, Any]:
    snap = db.collection("config").document("barberia").get()
    return snap.to_dict() or {"slotMinutes": 30, "maxNoShows": 3}


def _reputation_blocked(db, phone_normalized: str | None, max_no_shows: int) -> bool:
    if not phone_normalized:
        return False
    snap = db.collection("reputation").document(phone_normalized).get()
    if not snap.exists:
        return False
    data = snap.to_dict() or {}
    if data.get("blocked") is True:
        return True
    return int(data.get("noShowCount") or 0) >= max_no_shows


# -----------------------------------------------------------------------------
# reserveSlot
# -----------------------------------------------------------------------------


@https_fn.on_call()
def reserveSlot(req: https_fn.CallableRequest) -> dict[str, Any]:
    """Crea atómicamente un booking v2 validando contra colisiones.

    Input:
        barberId: str
        serviceId: str
        startAtIso: str  (ISO 8601 UTC)
        customerName: str
        customerPhone: str | None
        customerEmail: str | None
        notes: str | None
        userId: str | None   (si es None, se usa req.auth.uid o 'guest')

    Output:
        { bookingId: str, endAtIso: str }

    Errores:
        invalid-argument   → payload incompleto o mal formado
        not-found          → barber o service no existen
        failed-precondition→ barber no disponible, servicio inactivo, fuera
                             de horario, o cliente bloqueado por reputación
        already-exists     → colisión con otro booking en ese slot
    """
    data = req.data or {}
    _require(
        data,
        [
            "barberId",
            "serviceId",
            "startAtIso",
            "customerName",
        ],
    )

    barber_id: str = data["barberId"]
    service_id: str = data["serviceId"]
    start_at: datetime = _parse_iso_utc(data["startAtIso"])
    customer_name: str = data["customerName"]
    customer_phone: str | None = data.get("customerPhone")
    customer_email: str | None = data.get("customerEmail")
    notes: str | None = data.get("notes")
    user_id: str = data.get("userId") or (
        req.auth.uid if req.auth else "guest"
    )

    db = firestore.client()

    # Lecturas previas a la transacción (seguras de cachear).
    service = _load_service(db, service_id)
    duration = int(service.get("durationMinutes") or 30)
    price = float(service.get("priceCents", 0)) / 100 if service.get(
        "priceCents"
    ) is not None else float(service.get("price") or 0)
    end_at = start_at + timedelta(minutes=duration)

    # Python datetime.weekday() devuelve 0..6 (lunes=0); convertimos a ISO
    # (1..7) para coincidir con Dart/Barber model.
    wh = _load_barber_working_hours(db, barber_id, start_at.weekday() + 1)
    candidate = TimeRange(start=start_at, end=end_at)
    if not is_within_working_hours(candidate, wh):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
            message="Horario fuera del turno del barbero.",
        )

    phone_normalized = normalize_phone(customer_phone)
    config = _load_config(db)
    if _reputation_blocked(
        db, phone_normalized, int(config.get("maxNoShows", 3))
    ):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
            message="Cliente bloqueado por historial de no-shows.",
        )

    # Ventana de consulta de conflictos: +/- duración del día.
    day_start = start_at.replace(hour=0, minute=0, second=0, microsecond=0)
    day_end = day_start + timedelta(days=1)

    booking_ref = db.collection("bookings").document()
    transaction = db.transaction()

    @firestore.transactional
    def _txn(tx: Transaction) -> None:
        # Releer bookings activos del barbero para este día.
        overlapping_q = (
            db.collection("bookings")
            .where(filter=FieldFilter("barberId", "==", barber_id))
            .where(filter=FieldFilter("startAt", ">=", day_start))
            .where(filter=FieldFilter("startAt", "<", day_end))
        )
        booking_docs = [d.to_dict() for d in overlapping_q.stream(transaction=tx)]

        blocks_q = (
            db.collection("schedule_blocks")
            .where(filter=FieldFilter("barberId", "==", barber_id))
            .where(filter=FieldFilter("startTime", ">=", day_start))
            .where(filter=FieldFilter("startTime", "<", day_end))
        )
        block_docs = [d.to_dict() for d in blocks_q.stream(transaction=tx)]

        if has_conflict(
            candidate,
            bookings_to_ranges(booking_docs),
            blocks_to_ranges(block_docs),
        ):
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.ALREADY_EXISTS,
                message="Ese horario ya fue reservado. Intenta con otro.",
            )

        tx.set(
            booking_ref,
            {
                "userId": user_id,
                "barberId": barber_id,
                "serviceId": service_id,
                "serviceName": service.get("name", ""),
                "serviceDurationMinutes": duration,
                "servicePrice": price,
                "startAt": start_at,
                "endAt": end_at,
                # Retro-compat: campos viejos que Flutter todavía lee.
                "date": start_at,
                "status": "pending",
                "customerName": customer_name,
                "customerEmail": customer_email,
                "customerPhone": customer_phone,
                "phoneNormalized": phone_normalized,
                "notes": notes,
                "cancelReason": None,
                "confirmationSentAt": None,
                "confirmedAt": None,
                "createdAt": firestore.SERVER_TIMESTAMP,
                "updatedAt": firestore.SERVER_TIMESTAMP,
            },
        )

    _txn(transaction)

    return {
        "bookingId": booking_ref.id,
        "endAtIso": end_at.isoformat().replace("+00:00", "Z"),
    }


# -----------------------------------------------------------------------------
# getAvailability
# -----------------------------------------------------------------------------


@https_fn.on_call()
def getAvailability(req: https_fn.CallableRequest) -> dict[str, Any]:
    """Lista slots libres de un barbero para una fecha y servicio.

    Input:
        barberId: str
        dateIso: str         (ISO 8601 — se usa solo la parte de fecha)
        serviceId: str

    Output:
        { slots: [startIsoUtc, ...], slotMinutes: int, durationMinutes: int }
    """
    data = req.data or {}
    _require(data, ["barberId", "dateIso", "serviceId"])

    barber_id: str = data["barberId"]
    date_input: datetime = _parse_iso_utc(data["dateIso"])
    service_id: str = data["serviceId"]

    db = firestore.client()
    service = _load_service(db, service_id)
    duration = int(service.get("durationMinutes") or 30)
    config = _load_config(db)
    slot_minutes = int(config.get("slotMinutes") or 30)

    wh = _load_barber_working_hours(db, barber_id, date_input.weekday() + 1)

    candidates = generate_candidates(
        date=date_input,
        duration_minutes=duration,
        slot_minutes=slot_minutes,
        working_hours_for_weekday=wh,
    )

    day_start = date_input.replace(hour=0, minute=0, second=0, microsecond=0)
    day_end = day_start + timedelta(days=1)

    bookings_q = (
        db.collection("bookings")
        .where(filter=FieldFilter("barberId", "==", barber_id))
        .where(filter=FieldFilter("startAt", ">=", day_start))
        .where(filter=FieldFilter("startAt", "<", day_end))
    )
    active_bookings = [
        d.to_dict()
        for d in bookings_q.stream()
        if (d.to_dict() or {}).get("status") in OCCUPYING_STATUSES
    ]
    blocks_q = (
        db.collection("schedule_blocks")
        .where(filter=FieldFilter("barberId", "==", barber_id))
        .where(filter=FieldFilter("startTime", ">=", day_start))
        .where(filter=FieldFilter("startTime", "<", day_end))
    )
    blocks = [d.to_dict() for d in blocks_q.stream()]

    booking_ranges = bookings_to_ranges(active_bookings)
    block_ranges = blocks_to_ranges(blocks)

    free_slots: list[str] = []
    for c in candidates:
        if has_conflict(c, booking_ranges, block_ranges):
            continue
        free_slots.append(c.start.isoformat().replace("+00:00", "Z"))

    return {
        "slots": free_slots,
        "slotMinutes": slot_minutes,
        "durationMinutes": duration,
    }
