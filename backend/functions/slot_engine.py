"""Motor de disponibilidad de slots.

Lógica pura (sin Firestore) + helpers que leen de Firestore. La parte pura
se puede testear sin emulador; la parte con I/O se usa desde `main.py`
dentro de la transacción de `reserveSlot`.

Modelo mental:
    - Un barbero tiene working_hours por día de la semana (0=lunes, 6=domingo).
      Ejemplo: {0: [9,19], 6: None} → L lunes 9-19, domingo cerrado.
    - La barbería tiene un slot_minutes global (ej. 30).
    - Un slot candidato [start, start+duration) está libre si:
        * cae dentro de working_hours,
        * no solapa con otro booking con status en {pending, confirmed,
          inProgress} del mismo barbero,
        * no solapa con ningún schedule_block del barbero.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, time, timedelta, timezone
from typing import Iterable

# Status que bloquean el slot. Coincide con Booking.occupiesSlot en Dart.
OCCUPYING_STATUSES: frozenset[str] = frozenset(
    {"pending", "confirmed", "inProgress"}
)


@dataclass(frozen=True)
class TimeRange:
    """Intervalo medio-abierto [start, end). Comparaciones en UTC."""

    start: datetime
    end: datetime

    def overlaps(self, other: "TimeRange") -> bool:
        return self.start < other.end and other.start < self.end


def _as_utc(dt: datetime) -> datetime:
    """Normaliza cualquier datetime a UTC-aware."""
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def has_conflict(
    candidate: TimeRange,
    existing_bookings: Iterable[TimeRange],
    schedule_blocks: Iterable[TimeRange],
) -> bool:
    """True si `candidate` solapa con algún booking activo o block.

    Pura: no toca Firestore. El caller filtra antes por barberId y status.
    """
    for br in existing_bookings:
        if candidate.overlaps(br):
            return True
    for sb in schedule_blocks:
        if candidate.overlaps(sb):
            return True
    return False


def is_within_working_hours(
    candidate: TimeRange,
    working_hours_for_weekday: list[int] | None,
    business_tz_offset_hours: int = -6,
) -> bool:
    """True si `candidate` cabe entero dentro del horario del barbero.

    `working_hours_for_weekday` es [openHour, closeHour] en hora local del
    negocio (Guatemala = UTC-6). `None` significa día cerrado.
    """
    if working_hours_for_weekday is None:
        return False
    open_h, close_h = working_hours_for_weekday[0], working_hours_for_weekday[1]

    tz = timezone(timedelta(hours=business_tz_offset_hours))
    local_start = candidate.start.astimezone(tz)
    local_end = candidate.end.astimezone(tz)

    # Mismo día (no dejamos que un slot cruce medianoche).
    if local_start.date() != local_end.date():
        return False

    day_open = datetime.combine(
        local_start.date(), time(hour=open_h), tzinfo=tz
    )
    day_close = datetime.combine(
        local_start.date(), time(hour=close_h), tzinfo=tz
    )
    return day_open <= local_start and local_end <= day_close


def generate_candidates(
    date: datetime,
    duration_minutes: int,
    slot_minutes: int,
    working_hours_for_weekday: list[int] | None,
    business_tz_offset_hours: int = -6,
) -> list[TimeRange]:
    """Genera todos los TimeRange candidatos del día.

    La granularidad es `slot_minutes` (ej. 30). Para una duración de 45min,
    el slot puede empezar a :00, :30, :00, etc. pero debe caber completo
    antes del cierre.
    """
    if working_hours_for_weekday is None:
        return []

    tz = timezone(timedelta(hours=business_tz_offset_hours))
    local_date = date.astimezone(tz).date()
    open_h, close_h = working_hours_for_weekday[0], working_hours_for_weekday[1]

    day_open = datetime.combine(local_date, time(hour=open_h), tzinfo=tz)
    day_close = datetime.combine(local_date, time(hour=close_h), tzinfo=tz)

    candidates: list[TimeRange] = []
    cursor = day_open
    step = timedelta(minutes=slot_minutes)
    duration = timedelta(minutes=duration_minutes)

    while cursor + duration <= day_close:
        candidates.append(
            TimeRange(start=_as_utc(cursor), end=_as_utc(cursor + duration))
        )
        cursor += step

    return candidates


# -----------------------------------------------------------------------------
# Adaptadores Firestore (usados por main.py)
# -----------------------------------------------------------------------------


def bookings_to_ranges(booking_docs: Iterable[dict]) -> list[TimeRange]:
    """Mapea docs de `bookings/` a TimeRange solo si ocupan slot."""
    out: list[TimeRange] = []
    for b in booking_docs:
        status = b.get("status", "pending")
        if status not in OCCUPYING_STATUSES:
            continue
        start = _coerce_dt(b.get("startAt") or b.get("date"))
        end = _coerce_dt(b.get("endAt"))
        if start is None or end is None:
            # Best effort: si falta endAt, asumimos 30min.
            if start is not None and end is None:
                end = start + timedelta(minutes=30)
            else:
                continue
        out.append(TimeRange(start=_as_utc(start), end=_as_utc(end)))
    return out


def blocks_to_ranges(block_docs: Iterable[dict]) -> list[TimeRange]:
    out: list[TimeRange] = []
    for b in block_docs:
        start = _coerce_dt(b.get("startTime"))
        end = _coerce_dt(b.get("endTime"))
        if start is None or end is None:
            continue
        out.append(TimeRange(start=_as_utc(start), end=_as_utc(end)))
    return out


def _coerce_dt(value: object) -> datetime | None:
    """Acepta Timestamp de Firestore, datetime o ISO string."""
    if value is None:
        return None
    if isinstance(value, datetime):
        return value
    # Firestore Timestamp proto (tiene .to_datetime()).
    to_dt = getattr(value, "to_datetime", None)
    if callable(to_dt):
        return to_dt()  # type: ignore[no-any-return]
    if isinstance(value, str):
        try:
            return datetime.fromisoformat(value.replace("Z", "+00:00"))
        except ValueError:
            return None
    return None
