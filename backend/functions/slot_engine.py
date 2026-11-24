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

import re
from dataclasses import dataclass
from datetime import datetime, time, timedelta, timezone
from typing import Iterable

# Status que bloquean el slot, en minúsculas. Los documentos históricos usan
# mayúsculas ('CONFIRMED', 'LIVE') y camelCase ('inProgress'); el barber
# portal escribe 'live' al iniciar el servicio. La comparación es siempre
# case-insensitive (ver `occupies_slot`). Terminales: completed, finished,
# cancelled/canceled, noshow/no_show.
OCCUPYING_STATUSES: frozenset[str] = frozenset(
    {"pending", "confirmed", "inprogress", "live", "active"}
)

LEGACY_DEFAULT_MINUTES = 30
_LEGACY_TIME = re.compile(r"^\s*(\d{1,2}):(\d{2})\s*([AaPp][Mm])?\s*$")


def occupies_slot(status: object) -> bool:
    """True si el status (cualquier casing; ausente = pending) ocupa agenda."""
    if status is None:
        return True
    return isinstance(status, str) and status.strip().lower() in OCCUPYING_STATUSES


def parse_legacy_time(value: object) -> tuple[int, int] | None:
    """'10:00 AM' / '2:30 pm' / '14:30' → (hora, minuto) en 24h."""
    if not isinstance(value, str):
        return None
    match = _LEGACY_TIME.match(value)
    if not match:
        return None
    hour, minute, meridiem = int(match.group(1)), int(match.group(2)), match.group(3)
    if minute > 59:
        return None
    if meridiem:
        if not 1 <= hour <= 12:
            return None
        hour = hour % 12 + (12 if meridiem.lower() == "pm" else 0)
    elif hour > 23:
        return None
    return hour, minute


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
    business_tz_offset_hours: int,
) -> bool:
    """True si `candidate` cabe entero dentro del horario del barbero.

    `working_hours_for_weekday` es [openHour, closeHour] en hora local del
    negocio. `business_tz_offset_hours` viene de `config/barberia.timezoneOffsetHours`
    (ver `_load_config` en main.py) — no hay default hardcodeado porque cada
    negocio puede estar en un país distinto. `None` en working_hours significa
    día cerrado.
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
    business_tz_offset_hours: int,
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


def bookings_to_ranges(
    booking_docs: Iterable[dict], business_tz_offset_hours: int | None = None
) -> list[TimeRange]:
    """Mapea docs de `bookings/` a TimeRange solo si ocupan slot.

    Esquema canónico: `startAt`/`endAt` (Timestamps UTC). Compatibilidad
    legacy, en orden:
      * sin `endAt` → `serviceDurationMinutes` o 30 min;
      * sin `startAt` pero con `date` + `time` ('10:00 AM') → el día local de
        `date` a la hora `time` (requiere `business_tz_offset_hours`). Las
        reservas manuales antiguas guardaban en `date` la hora de *creación*,
        así que `date` solo no indica cuándo es la cita.
    """
    out: list[TimeRange] = []
    for b in booking_docs:
        if not occupies_slot(b.get("status", "pending")):
            continue
        start = _coerce_dt(b.get("startAt"))
        if start is None:
            start = _legacy_start(b, business_tz_offset_hours)
        if start is None:
            continue
        start = _as_utc(start)
        end = _coerce_dt(b.get("endAt"))
        if end is None:
            minutes = b.get("serviceDurationMinutes")
            if type(minutes) is not int or minutes <= 0:
                minutes = LEGACY_DEFAULT_MINUTES
            end = start + timedelta(minutes=minutes)
        end = _as_utc(end)
        if end <= start:
            continue
        out.append(TimeRange(start=start, end=end))
    return out


def _legacy_start(b: dict, business_tz_offset_hours: int | None) -> datetime | None:
    date_value = _coerce_dt(b.get("date"))
    if date_value is None:
        return None
    clock = parse_legacy_time(b.get("time"))
    if clock is None or business_tz_offset_hours is None:
        return date_value
    tz = timezone(timedelta(hours=business_tz_offset_hours))
    local_day = _as_utc(date_value).astimezone(tz).date()
    return datetime.combine(local_day, time(hour=clock[0], minute=clock[1]), tzinfo=tz)


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
