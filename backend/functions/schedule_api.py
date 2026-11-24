"""Staff schedule-block callables (`createScheduleBlock`).

Invariant shared with booking_api.reserve: a barber never has an occupying
booking that overlaps a schedule block. Both writers read and write the
per (shop, barber, local day) guard of every day they touch, then decide on
the bookings and blocks of those days inside the same transaction, so a
block and a reservation for the same barber cannot commit concurrently on a
stale view of each other.

Deleting a block only frees time, so it stays a direct, rule-checked client
delete. Creating and editing go through this module (rules deny both).
"""

from datetime import timedelta

from firebase_admin import firestore
from firebase_functions import https_fn

import booking_api as api
from slot_engine import TimeRange

Code = https_fn.FunctionsErrorCode
MAX_BLOCK_DAYS = 31


def _caller(db, req):
    if req.auth is None:
        api.fail(Code.UNAUTHENTICATED, "Inicia sesión.")
    profile = api.read(db, "users", req.auth.uid, None)
    shop_id = profile.get("shopId")
    if profile.get("role") not in ("barber", "admin") or not isinstance(shop_id, str) or not shop_id:
        api.fail(Code.PERMISSION_DENIED, "Solo el personal del negocio puede bloquear horarios.")
    return profile, shop_id


def local_days(start, end, tz):
    """Business-local calendar dates touched by [start, end)."""
    first = start.astimezone(tz).date()
    last = (end - timedelta(microseconds=1)).astimezone(tz).date()
    days = []
    day = first
    while day <= last:
        days.append(day)
        day += timedelta(days=1)
    return days


def create_block(req):
    if not isinstance(req.data, dict):
        api.fail(Code.INVALID_ARGUMENT, "Solicitud inválida.")
    db = firestore.client()
    profile, shop_id = _caller(db, req)
    barber_id = api.identifier(req.data, "barberId")
    # A barber blocks only their own agenda; an admin any barber of the shop.
    if profile["role"] == "barber" and barber_id != req.auth.uid:
        api.fail(Code.PERMISSION_DENIED, "Solo puedes bloquear tu propia agenda.")
    start = api.instant(api.string(req.data, "startIso", 40))
    end = api.instant(api.string(req.data, "endIso", 40))
    reason = api.string(req.data, "reason", 100)
    if end <= start:
        api.fail(Code.INVALID_ARGUMENT, "La hora final debe ser posterior al inicio.")
    if end - start > timedelta(days=MAX_BLOCK_DAYS):
        api.fail(Code.INVALID_ARGUMENT, f"Un bloqueo no puede superar {MAX_BLOCK_DAYS} días.")

    tz = api.shop_timezone(api.read(db, "shops", shop_id, None))
    days = local_days(start, end, tz)
    guards = [api.guard_ref(db, shop_id, barber_id, day) for day in days]
    block_ref = db.collection("schedule_blocks").document()
    candidate = TimeRange(start=start, end=end)

    @firestore.transactional
    def commit(tx):
        for guard in guards:
            guard.get(transaction=tx)
        shop = api.read(db, "shops", shop_id, tx)
        if api.shop_timezone(shop) != tz:
            api.fail(Code.ABORTED, "La configuración del negocio cambió. Intenta de nuevo.")
        barber = api.read(db, "users", barber_id, tx)
        if barber.get("role") != "barber" or barber.get("shopId") != shop_id:
            api.fail(Code.PERMISSION_DENIED, "Ese barbero no pertenece a tu negocio.")
        ids = (shop_id, barber_id, None)
        for day in days:
            midnight = api.datetime.combine(day, api.datetime.min.time(), tzinfo=tz)
            bookings, _ = api.occupancy(db, ids, midnight, tx)
            if any(candidate.overlaps(booking) for booking in bookings):
                api.fail(Code.FAILED_PRECONDITION,
                         "Hay citas activas en ese intervalo. Cancélalas o reprográmalas primero.")
        timestamp = firestore.SERVER_TIMESTAMP
        tx.create(block_ref, {
            "shopId": shop_id, "barberId": barber_id, "type": reason, "reason": reason,
            "startTime": start, "endTime": end, "createdBy": req.auth.uid,
            "createdAt": timestamp, "updatedAt": timestamp})
        for guard in guards:
            tx.set(guard, {"updatedAt": timestamp})
        return {"blockId": block_ref.id}

    return api.run_guarded(db, commit, "Agenda ocupada. Intenta de nuevo.")
