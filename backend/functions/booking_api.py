"""Public booking callables (`getAvailability`, `reserveSlot`).

Concurrency invariant
---------------------
For a given (shopId, barberId, business-local calendar day) at most one
`reserveSlot` transaction can commit at a time, and each one decides on a
consistent snapshot of that day's bookings and schedule blocks.

Enforcement: every reservation transaction reads and then writes the guard
document ``booking_guards/{sha256(shopId, barberId, YYYY-MM-DD)}``. Firestore
serializes read-write transactions that touch the same document, so two
concurrent reservations for the same barber/day cannot both commit: the
loser is retried by ``@firestore.transactional`` and re-reads the winner's
booking, failing with ``already-exists`` if they overlap. Slots never cross
local midnight (see ``slot_engine.generate_candidates``), so one guard per
local day covers every possible overlap, for any service duration.

Writers that create occupancy MUST go through this module. Firestore rules
deny client-side booking creates, and staff updates cannot move a terminal
booking (cancelled, completed, no-show) back into an occupying status.
Cancelling releases the slot because ``slot_engine.occupies_slot`` ignores
terminal statuses.
"""
import hashlib
import json
import math
import random
import re
import time
from datetime import datetime, timedelta, timezone

from firebase_admin import firestore
from firebase_functions import https_fn
from google.cloud.firestore_v1.base_query import FieldFilter

from slot_engine import bookings_to_ranges, blocks_to_ranges, generate_candidates, has_conflict

DEFAULT_TZ_OFFSET_HOURS = -6  # Guatemala; used when a shop has no explicit offset.
Code = https_fn.FunctionsErrorCode
RESERVE_ATTEMPTS_PER_ROUND = 5
RESERVE_ROUNDS = 5


def fail(code, message):
    raise https_fn.HttpsError(code, message)


def string(data, key, limit, required=True):
    value = data.get(key)
    if value is None and not required:
        return ""
    if not isinstance(value, str) or len(value) > limit or (required and not value.strip()):
        fail(Code.INVALID_ARGUMENT, f"Campo inválido: {key}.")
    return value.strip()


def identifier(data, key):
    value = string(data, key, 256)
    if "/" in value or value in (".", ".."):
        fail(Code.INVALID_ARGUMENT, f"Identificador inválido: {key}.")
    return value


def instant(value):
    try:
        dt = datetime.fromisoformat(value.replace("Z", "+00:00"))
        if dt.tzinfo is None:
            raise ValueError()
        return dt.astimezone(timezone.utc)
    except (ValueError, OverflowError):
        fail(Code.INVALID_ARGUMENT, "La hora debe incluir zona horaria.")


def iso(dt):
    return dt.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")


def digest(*parts):
    return hashlib.sha256(json.dumps(parts, ensure_ascii=False).encode()).hexdigest()


def customer(data):
    name = string(data, "customerName", 100)
    phone = string(data, "customerPhone", 32)
    email = string(data, "customerEmail", 254, False)
    notes = string(data, "notes", 500, False)
    if len(name) < 2 or any(ord(c) < 32 for c in name):
        fail(Code.INVALID_ARGUMENT, "Nombre inválido.")
    compact = re.sub(r"[ ()-]", "", phone)
    if re.fullmatch(r"[0-9]{8}", compact):
        compact = "+502" + compact
    elif re.fullmatch(r"502[0-9]{8}", compact):
        compact = "+" + compact
    if not re.fullmatch(r"\+[1-9][0-9]{7,14}", compact):
        fail(Code.INVALID_ARGUMENT, "Teléfono inválido.")
    if email and not re.fullmatch(r"[^\s@]+@[^\s@]+\.[^\s@]+", email):
        fail(Code.INVALID_ARGUMENT, "Correo inválido.")
    return name, compact, email, notes


def read(db, collection, key, tx):
    return db.collection(collection).document(key).get(transaction=tx).to_dict() or {}


def positive(data, key, default, maximum):
    value = data.get(key, default)
    if type(value) is not int or not 1 <= value <= maximum:
        fail(Code.FAILED_PRECONDITION, "Configuración de agenda inválida.")
    return value


def working_hours(shop, barber, day):
    weekday = day.isoweekday()
    days = shop.get("openDays", [True] * 6 + [False])
    if not isinstance(days, list) or len(days) != 7 or days[weekday-1] is not True:
        return None
    availability = barber.get("availability") or {}
    if availability.get(("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")[weekday-1]) is False:
        return None
    shop_hours = [shop.get("openHour", 9), shop.get("closeHour", 19)]
    overrides = barber.get("workingHours") or {}
    personal = overrides.get(str(weekday), shop_hours)
    if personal is None:
        return None
    for pair in (shop_hours, personal):
        if (not isinstance(pair, list) or len(pair) != 2
                or any(type(h) is not int for h in pair) or not 0 <= pair[0] < pair[1] <= 24):
            fail(Code.FAILED_PRECONDITION, "Horario de atención inválido.")
    return [max(personal[0], shop_hours[0]), min(personal[1], shop_hours[1])]


def shop_timezone(shop):
    offset = shop.get("timezoneOffsetHours", DEFAULT_TZ_OFFSET_HOURS)
    if type(offset) is not int or not -12 <= offset <= 14:
        fail(Code.FAILED_PRECONDITION, "Zona horaria del negocio inválida.")
    return timezone(timedelta(hours=offset))


def schedule(db, ids, local_day, tx=None):
    """Validates tenant/barber/service and returns the day's candidate slots.

    `local_day` is the business-local calendar date. Returns
    (shop, barber, service, duration, step, candidates, day) where `day` is
    local midnight as an aware datetime.
    """
    shop_id, barber_id, service_id = ids
    shop = read(db, "shops", shop_id, tx)
    barber = read(db, "users", barber_id, tx)
    service = read(db, "services", service_id, tx)
    if not shop or not barber or not service:
        fail(Code.NOT_FOUND, "Negocio, barbero o servicio inexistente.")
    # Shops created before `status` existed are treated as active; an explicit
    # non-active status (e.g. "suspended") closes public booking.
    if (shop.get("status", "active") != "active" or shop.get("isActive", True) is not True
            or barber.get("role") != "barber" or barber.get("shopId") != shop_id
            or barber.get("isAvailable", True) is not True or barber.get("isActive", True) is not True
            or service.get("shopId") != shop_id or service.get("isActive") is not True):
        fail(Code.FAILED_PRECONDITION, "Negocio, barbero o servicio no disponible.")
    duration = positive(service, "durationMinutes", None, 1440)
    step = positive(shop, "slotMinutes", 30, 1440)
    tz = shop_timezone(shop)
    day = datetime.combine(local_day, datetime.min.time(), tzinfo=tz)
    candidates = generate_candidates(
        day, duration, step, working_hours(shop, barber, day),
        int(tz.utcoffset(None).total_seconds() // 3600))
    return shop, barber, service, duration, step, candidates, day


def occupancy(db, ids, day, tx=None):
    """Occupied ranges for the barber on the local day starting at `day`.

    Every query uses a single range field so it is served by the composite
    indexes declared in firestore.indexes.json (barberId + startAt,
    barberId + date, schedule_blocks barberId + endTime).
    """
    shop_id, barber_id, _ = ids
    midnight = day
    tomorrow = midnight + timedelta(days=1)
    def query(collection, field, lower, lower_op, upper=None):
        q = (db.collection(collection)
             .where(filter=FieldFilter("barberId", "==", barber_id))
             .where(filter=FieldFilter(field, lower_op, lower)))
        if upper is not None:
            q = q.where(filter=FieldFilter(field, "<", upper))
        return {s.id: doc for s in q.stream(transaction=tx)
                if (doc := s.to_dict() or {}).get("shopId", shop_id) == shop_id}
    # Canonical rows. Reservations never cross local midnight, so filtering
    # on startAt within the day finds every booking that can overlap.
    bookings = query("bookings", "startAt", midnight, ">=", tomorrow)
    # Legacy rows without startAt: `date` (+ `time`) may sit up to a day away
    # in UTC; bookings_to_ranges resolves the real start and the overlap test
    # discards anything outside this day.
    legacy = query("bookings", "date", midnight - timedelta(days=1), ">=",
                   tomorrow + timedelta(days=1))
    bookings.update({k: v for k, v in legacy.items() if v.get("startAt") is None})
    # Blocks may span several days (vacations): select by end, filter by start.
    blocks = {k: v for k, v in query("schedule_blocks", "endTime", midnight, ">").items()
              if (start := _block_start(v)) is not None and start < tomorrow}
    offset = int(day.utcoffset().total_seconds() // 3600)
    return bookings_to_ranges(bookings.values(), offset), blocks_to_ranges(blocks.values())


def _block_start(block):
    ranges = blocks_to_ranges([block])
    return ranges[0].start if ranges else None


def client_network(raw_request):
    """Best-effort client address for guest quotas.

    Behind Google's front end `remote_addr` is typically the proxy, shared by
    every caller, which would turn the per-network quota into a per-shop
    one. The front end appends the peer it saw as the last X-Forwarded-For
    entry; earlier entries are client-supplied and ignored. Not verified
    against a deployed function — confirm in production logs.
    """
    if raw_request is None:
        return None
    forwarded = raw_request.headers.get("X-Forwarded-For", "") if raw_request.headers else ""
    hops = [hop.strip() for hop in forwarded.split(",") if hop.strip()]
    return hops[-1] if hops else raw_request.remote_addr


def inputs(req):
    if not isinstance(req.data, dict):
        fail(Code.INVALID_ARGUMENT, "Solicitud inválida.")
    return tuple(identifier(req.data, key) for key in ("shopId", "barberId", "serviceId"))


def availability(req):
    ids = inputs(req)
    data = req.data
    db = firestore.client()
    if "dateLocal" in data:
        raw = string(data, "dateLocal", 10)
        try:
            local_day = datetime.strptime(raw, "%Y-%m-%d").date()
            if local_day.isoformat() != raw:
                raise ValueError()
        except ValueError:
            fail(Code.INVALID_ARGUMENT, "Fecha local inválida.")
    else:
        moment = instant(string(data, "dateIso", 40))
        local_day = moment.astimezone(shop_timezone(read(db, "shops", ids[0], None))).date()
    _, _, _, duration, step, candidates, day = schedule(db, ids, local_day)
    now = datetime.now(timezone.utc)
    candidates = [c for c in candidates if c.start > now]
    occupied = occupancy(db, ids, day) if candidates else ([], [])
    return {"slots": [iso(c.start) for c in candidates if not has_conflict(c, *occupied)],
            "durationMinutes": duration, "slotMinutes": step}


def reserve(req):
    ids = inputs(req)
    shop_id, barber_id, service_id = ids
    name, phone, email, notes = customer(req.data)
    start = instant(string(req.data, "startAtIso", 40))
    key = string(req.data, "idempotencyKey", 128)
    if not re.fullmatch(r"[A-Za-z0-9_-]{16,128}", key):
        fail(Code.INVALID_ARGUMENT, "Clave de solicitud inválida.")
    user_id = req.auth.uid if req.auth else "guest"
    fingerprint = digest(ids, iso(start), name, phone, email, notes, user_id)
    db = firestore.client()
    # The guard key needs the business-local day before the transaction
    # starts; the transaction re-reads the shop and aborts if it changed.
    tz = shop_timezone(read(db, "shops", shop_id, None))
    local_day = start.astimezone(tz).date()
    request_ref = db.collection("booking_requests").document(digest(shop_id, user_id, key))
    guard = db.collection("booking_guards").document(digest(shop_id, barber_id, local_day.isoformat()))
    booking = db.collection("bookings").document()
    notification = db.collection("notifications").document(booking.id)
    peer = client_network(getattr(req, "raw_request", None))
    @firestore.transactional
    def commit(tx):
        previous = request_ref.get(transaction=tx).to_dict()
        if previous:
            if previous["fingerprint"] != fingerprint:
                fail(Code.FAILED_PRECONDITION, "La clave ya identifica otra solicitud.")
            return previous["result"]
        guard.get(transaction=tx)
        shop, barber, service, duration, _, candidates, day = schedule(db, ids, local_day, tx)
        if start.astimezone(day.tzinfo).date() != local_day:
            fail(Code.ABORTED, "La configuración del negocio cambió. Intenta de nuevo.")
        now = datetime.now(timezone.utc)
        candidate = next((c for c in candidates if c.start == start and c.start > now), None)
        if candidate is None:
            fail(Code.FAILED_PRECONDITION, "Horario no disponible.")
        rep = read(db, "reputation", phone, tx)
        if rep.get("shopId") == shop_id and (rep.get("blocked") is True or
                rep.get("noShowCount", 0) >= positive(shop, "maxNoShows", 3, 1000)):
            fail(Code.FAILED_PRECONDITION, "Cliente bloqueado por historial de no-shows.")
        hour = now.replace(minute=0, second=0, microsecond=0)
        quotas = [("phone", phone, 3)]
        if req.auth:
            quotas.append(("uid", user_id, 8))
        elif peer:
            quotas.append(("guest-network", peer, 20))
        counts = []
        for kind, subject, limit in quotas:
            ref = db.collection("booking_limits").document(digest(shop_id, kind, subject))
            window = ref.get(transaction=tx).to_dict() or {}
            count = window["count"] if window.get("hour") == hour else 0
            if count >= limit:
                fail(Code.RESOURCE_EXHAUSTED, "Límite de reservas alcanzado. Intenta más tarde.")
            counts.append((ref, count + 1))
        if has_conflict(candidate, *occupancy(db, ids, day, tx)):
            fail(Code.ALREADY_EXISTS, "Ese horario ya fue reservado. Intenta con otro.")
        cents = service.get("priceCents")
        source_price = cents if cents is not None else service.get("price")
        if type(source_price) not in (float, int) or not math.isfinite(source_price) or source_price < 0:
            fail(Code.FAILED_PRECONDITION, "Precio de servicio inválido.")
        price = source_price / 100 if cents is not None else source_price
        barber_name = barber.get("name", "Barbero")
        service_name = service.get("name", "")
        timestamp = firestore.SERVER_TIMESTAMP
        tx.create(booking, {
            "shopId": shop_id, "userId": user_id, "barberId": barber_id, "serviceId": service_id,
            "barberName": barber_name, "serviceName": service_name, "service": service_name,
            "serviceDurationMinutes": duration, "servicePrice": price, "price": price,
            "startAt": start, "endAt": candidate.end, "date": start,
            "time": start.astimezone(day.tzinfo).strftime("%I:%M %p").lstrip("0"), "status": "pending",
            "clientName": name, "customerName": name, "phoneNormalized": phone,
            "clientPhone": phone, "customerPhone": phone, "clientEmail": email or None,
            "customerEmail": email or None, "notes": notes or None, "cancelReason": None,
            "confirmationSentAt": None, "confirmedAt": None, "createdAt": timestamp, "updatedAt": timestamp})
        tx.create(notification, {
            "shopId": shop_id, "title": "Nueva Cita Solicitada",
            "message": f"{name} ha agendado {service_name} con {barber_name}.",
            "barberId": barber_id, "barberName": barber_name, "clientName": name,
            "service": service_name, "bookingId": booking.id, "type": "new_booking",
            "target": "staff", "createdAt": timestamp, "read": False})
        result = {"bookingId": booking.id, "endAtIso": iso(candidate.end)}
        tx.set(guard, {"updatedAt": timestamp})
        tx.create(request_ref, {"fingerprint": fingerprint, "result": result})
        for ref, count in counts:
            tx.set(ref, {"hour": hour, "count": count})
        return result
    # Inner retries reuse the aborted transaction id, which production
    # Firestore honours to keep the caller's place in line. The jittered outer
    # rounds additionally break up contenders that keep aborting each other
    # (observed in the emulator with 8 simultaneous requests for one slot).
    for round_ in range(RESERVE_ROUNDS):
        try:
            return commit(db.transaction(max_attempts=RESERVE_ATTEMPTS_PER_ROUND))
        except ValueError as error:
            # google-cloud-firestore raises a bare ValueError once contention
            # has exhausted the attempts; nothing was written.
            if "Failed to commit transaction" not in str(error):
                raise
            if round_ + 1 < RESERVE_ROUNDS:
                time.sleep(random.uniform(0, min(1.0, 0.05 * 2 ** round_)))
    # Safe to retry with the same idempotency key.
    fail(Code.ABORTED, "Alta demanda en este horario. Intenta de nuevo.")
