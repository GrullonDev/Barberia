"""Booking lifecycle against the Firestore emulator (real transactions).

Run from the repository root:
    firebase emulators:exec --only firestore --project demo-barberia \
        "python -m pytest backend/tests/test_booking_emulator.py -q"

Calls booking_api.availability/reserve directly with callable-shaped request
objects, so the transaction, guard, idempotency and quota logic run exactly
as deployed (minus the HTTP envelope).
"""

from __future__ import annotations

import os
import sys
import threading
from datetime import date, datetime, timedelta, timezone
from pathlib import Path
from types import SimpleNamespace
from uuid import uuid4

import pytest

host = os.environ.get("FIRESTORE_EMULATOR_HOST", "")
if host.split(":")[0] not in {"127.0.0.1", "localhost"}:
    pytest.skip("requires the local Firestore emulator", allow_module_level=True)

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "functions"))

import firebase_admin  # noqa: E402
import google.auth.credentials  # noqa: E402
from firebase_admin import credentials, firestore  # noqa: E402
from firebase_functions import https_fn  # noqa: E402

import booking_api  # noqa: E402

Code = https_fn.FunctionsErrorCode
GT = timezone(timedelta(hours=-6))


class _EmulatorCredential(credentials.Base):
    def get_credential(self):
        return google.auth.credentials.AnonymousCredentials()


if not firebase_admin._apps:
    firebase_admin.initialize_app(_EmulatorCredential(), {"projectId": "demo-barberia"})
db = firestore.client()


def next_monday() -> date:
    today = datetime.now(GT).date()
    return today + timedelta(days=7 + (7 - today.weekday()) % 7)


DAY = next_monday()


def at(hour: int, minute: int = 0, day: date = DAY) -> datetime:
    return datetime(day.year, day.month, day.day, hour, minute, tzinfo=GT)


def iso(dt: datetime) -> str:
    return dt.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")


class Tenant:
    """A shop with one barber and 30/60-minute services, isolated by uuid."""

    def __init__(self, **shop_overrides):
        self.shop = "shop-" + uuid4().hex[:10]
        self.barber = "barber-" + uuid4().hex[:10]
        self.barber2 = "barber-" + uuid4().hex[:10]
        self.short = "svc30-" + uuid4().hex[:8]
        self.long = "svc60-" + uuid4().hex[:8]
        db.collection("shops").document(self.shop).set(
            {"name": "Test", "status": "active", "slotMinutes": 30,
             "timezoneOffsetHours": -6, "openHour": 9, "closeHour": 19, **shop_overrides})
        for barber in (self.barber, self.barber2):
            db.collection("users").document(barber).set(
                {"role": "barber", "shopId": self.shop, "name": "Barber", "isAvailable": True})
        for svc, minutes in ((self.short, 30), (self.long, 60)):
            db.collection("services").document(svc).set(
                {"shopId": self.shop, "name": f"Cut {minutes}", "durationMinutes": minutes,
                 "price": 50, "isActive": True})

    def ids(self, barber=None, service=None, shop=None):
        return {"shopId": shop or self.shop, "barberId": barber or self.barber,
                "serviceId": service or self.short}


def request(data, uid=None, ip="198.51.100.1"):
    return SimpleNamespace(
        data=data,
        auth=SimpleNamespace(uid=uid) if uid else None,
        raw_request=SimpleNamespace(headers={"X-Forwarded-For": ip}, remote_addr="10.0.0.1"))


_phone_seq = iter(range(10_000_000, 99_999_999, 7919))


def booking_payload(tenant, start, **overrides):
    phone = f"{next(_phone_seq):08d}"
    return {**tenant.ids(), "startAtIso": iso(start), "customerName": "Cliente Prueba",
            "customerPhone": phone, "idempotencyKey": uuid4().hex, **overrides}


def slots(tenant, **ids):
    data = {**tenant.ids(**ids), "dateLocal": DAY.isoformat()}
    return booking_api.availability(request(data))["slots"]


_ip_seq = iter(range(1, 1_000_000))


def reserve(payload, **kwargs):
    # Distinct client networks by default so the per-network guest quota is
    # not the shared document under test.
    kwargs.setdefault("ip", f"203.0.{next(_ip_seq) % 250}.{next(_ip_seq) % 250 + 1}")
    return booking_api.reserve(request(payload, **kwargs))


def code_of(fn, *args, **kwargs):
    with pytest.raises(https_fn.HttpsError) as info:
        fn(*args, **kwargs)
    return info.value.code


# ---------- availability --------------------------------------------------------


def test_availability_lists_working_hours_in_business_time():
    t = Tenant()
    free = slots(t)
    assert free[0] == iso(at(9)) and free[-1] == iso(at(18, 30))
    assert len(free) == 20
    assert slots(t, service=t.long)[-1] == iso(at(18))  # 60 min must end by 19:00


def test_closed_day_and_schedule_block():
    t = Tenant(openDays=[False] + [True] * 5 + [False])
    assert slots(t) == []
    t = Tenant()
    db.collection("schedule_blocks").add(
        {"shopId": t.shop, "barberId": t.barber, "startTime": at(12), "endTime": at(14)})
    free = slots(t)
    assert iso(at(11, 30)) in free and iso(at(14)) in free
    assert not {iso(at(12)), iso(at(12, 30)), iso(at(13)), iso(at(13, 30))} & set(free)
    # A multi-day block starting the previous day still applies.
    db.collection("schedule_blocks").add(
        {"shopId": t.shop, "barberId": t.barber2,
         "startTime": at(9, day=DAY - timedelta(days=1)), "endTime": at(10)})
    assert iso(at(9)) not in slots(t, barber=t.barber2)


def test_cross_tenant_requests_are_rejected():
    a, b = Tenant(), Tenant()
    for ids in (a.ids(service=b.short), a.ids(shop=b.shop), a.ids(barber=b.barber)):
        assert code_of(booking_api.availability,
                       request({**ids, "dateLocal": DAY.isoformat()})) == Code.FAILED_PRECONDITION
        assert code_of(reserve, {**booking_payload(a, at(10)), **ids}) == Code.FAILED_PRECONDITION
    assert code_of(booking_api.availability,
                   request({**a.ids(barber="missing"), "dateLocal": DAY.isoformat()})) == Code.NOT_FOUND


def test_inactive_service_or_suspended_shop_cannot_be_booked():
    t = Tenant()
    db.collection("services").document(t.short).update({"isActive": False})
    assert code_of(reserve, booking_payload(t, at(10))) == Code.FAILED_PRECONDITION
    t = Tenant(status="suspended")
    assert code_of(reserve, booking_payload(t, at(10))) == Code.FAILED_PRECONDITION


def test_shop_without_status_field_is_bookable():
    t = Tenant()
    db.collection("shops").document(t.shop).update({"status": firestore.DELETE_FIELD})
    assert reserve(booking_payload(t, at(10)))["bookingId"]


# ---------- reservation ------------------------------------------------------------


def test_reservation_persists_canonical_and_legacy_fields():
    t = Tenant()
    result = reserve(booking_payload(t, at(10), customerEmail="ana@example.com"), uid="client-1")
    doc = db.collection("bookings").document(result["bookingId"]).get().to_dict()
    assert doc["shopId"] == t.shop and doc["barberId"] == t.barber and doc["userId"] == "client-1"
    assert doc["startAt"] == at(10) and doc["endAt"] == at(10, 30)
    assert doc["status"] == "pending" and doc["time"] == "10:00 AM"
    assert doc["customerName"] == doc["clientName"] == "Cliente Prueba"
    assert doc["serviceName"] == doc["service"] == "Cut 30" and doc["servicePrice"] == 50
    assert result["endAtIso"] == iso(at(10, 30))
    notification = db.collection("notifications").document(result["bookingId"]).get().to_dict()
    assert notification["shopId"] == t.shop and notification["barberId"] == t.barber
    assert iso(at(10)) not in slots(t)


def test_slot_must_be_on_grid_within_hours_and_in_future():
    t = Tenant()
    for start in (at(10, 15), at(8, 30), at(19)):
        assert code_of(reserve, booking_payload(t, start)) == Code.FAILED_PRECONDITION
    # 60-minute service at 18:30 would end after closing.
    assert code_of(reserve, booking_payload(t, at(18, 30), serviceId=t.long)) == Code.FAILED_PRECONDITION
    past = datetime.now(GT).date() - timedelta(days=1)
    assert code_of(reserve, booking_payload(t, at(10, day=past))) == Code.FAILED_PRECONDITION


def test_overlap_with_variable_durations_is_rejected():
    t = Tenant()
    reserve(booking_payload(t, at(10), serviceId=t.long))           # 10:00–11:00
    assert code_of(reserve, booking_payload(t, at(10, 30))) == Code.ALREADY_EXISTS
    assert code_of(reserve, booking_payload(t, at(9, 30), serviceId=t.long)) == Code.ALREADY_EXISTS
    assert reserve(booking_payload(t, at(11)))["bookingId"]        # touching is fine
    assert reserve(booking_payload(t, at(10), barberId=t.barber2))["bookingId"]


def test_cancellation_releases_slot():
    t = Tenant()
    booking_id = reserve(booking_payload(t, at(15)))["bookingId"]
    assert iso(at(15)) not in slots(t)
    db.collection("bookings").document(booking_id).update({"status": "cancelled"})
    assert iso(at(15)) in slots(t)
    assert reserve(booking_payload(t, at(15)))["bookingId"]


def test_in_service_and_legacy_rows_keep_their_slot():
    t = Tenant()
    db.collection("bookings").add({"shopId": t.shop, "barberId": t.barber, "status": "live",
                                   "startAt": at(11), "endAt": at(11, 30)})
    db.collection("bookings").add({"shopId": t.shop, "barberId": t.barber, "status": "CONFIRMED",
                                   "date": at(7), "time": "04:00 PM"})
    free = slots(t)
    assert iso(at(11)) not in free and iso(at(16)) not in free
    assert code_of(reserve, booking_payload(t, at(16))) == Code.ALREADY_EXISTS


def test_idempotent_retry_returns_same_booking():
    t = Tenant()
    payload = booking_payload(t, at(13))
    first = reserve(payload)
    assert reserve(payload) == first
    assert code_of(reserve, {**payload, "customerName": "Otra Persona"}) == Code.FAILED_PRECONDITION
    rows = db.collection("bookings").where("barberId", "==", t.barber).get()
    assert len(rows) == 1


def test_same_network_guests_are_serialized_not_failed():
    t = Tenant()
    payloads = [booking_payload(t, at(10)), booking_payload(t, at(10), barberId=t.barber2)]
    outcomes = _race(payloads, ip="198.51.100.77")
    assert all(o[0] == "ok" or o[1] == Code.ABORTED for o in outcomes), outcomes
    assert any(o[0] == "ok" for o in outcomes)


def test_phone_quota_limits_abuse():
    t = Tenant()
    phone = "44443333"
    for hour in (9, 10, 11):
        reserve(booking_payload(t, at(hour), customerPhone=phone))
    assert code_of(reserve, booking_payload(t, at(12), customerPhone=phone)) == Code.RESOURCE_EXHAUSTED


def test_invalid_payloads():
    t = Tenant()
    assert code_of(reserve, booking_payload(t, at(10), customerPhone="12")) == Code.INVALID_ARGUMENT
    assert code_of(reserve, booking_payload(t, at(10), idempotencyKey="short")) == Code.INVALID_ARGUMENT
    assert code_of(reserve, booking_payload(t, at(10), startAtIso="2026-01-05T10:00:00")) == (
        Code.INVALID_ARGUMENT)


# ---------- concurrency --------------------------------------------------------------


def _race(payloads, **kwargs):
    barrier = threading.Barrier(len(payloads))
    outcomes = [None] * len(payloads)

    def run(i):
        barrier.wait()
        try:
            outcomes[i] = ("ok", reserve(payloads[i], **kwargs))
        except https_fn.HttpsError as error:
            outcomes[i] = ("error", error.code)

    threads = [threading.Thread(target=run, args=(i,)) for i in range(len(payloads))]
    for thread in threads:
        thread.start()
    for thread in threads:
        thread.join(timeout=120)
    return outcomes


def _occupying(tenant, barber):
    rows = [d.to_dict() for d in db.collection("bookings").where("barberId", "==", barber).get()]
    return [r for r in rows if r["shopId"] == tenant.shop]


def test_concurrent_identical_slot_only_one_wins():
    t = Tenant()
    outcomes = _race([booking_payload(t, at(10), customerPhone=f"5{i:07d}") for i in range(8)])
    wins = [o for o in outcomes if o[0] == "ok"]
    assert len(wins) == 1, outcomes
    # Losers get a clean, retryable code — never INTERNAL.
    assert all(o[1] in (Code.ALREADY_EXISTS, Code.ABORTED) for o in outcomes if o[0] != "ok")
    assert len(_occupying(t, t.barber)) == 1


def test_concurrent_overlapping_durations_never_double_book():
    t = Tenant()
    payloads = [booking_payload(t, at(10), serviceId=t.long, customerPhone="51111111"),
                booking_payload(t, at(10, 30), customerPhone="52222222"),
                booking_payload(t, at(9, 30), serviceId=t.long, customerPhone="53333333"),
                booking_payload(t, at(10, 30), serviceId=t.long, customerPhone="54444444")]
    _race(payloads)
    rows = _occupying(t, t.barber)
    ranges = sorted((r["startAt"], r["endAt"]) for r in rows)
    assert rows, "at least one reservation must succeed"
    for (s1, e1), (s2, e2) in zip(ranges, ranges[1:]):
        assert e1 <= s2, ranges


def test_concurrent_different_barbers_and_tenants_are_independent():
    a, b = Tenant(), Tenant()
    payloads = [booking_payload(a, at(10), customerPhone="61111111"),
                booking_payload(a, at(10), barberId=a.barber2, customerPhone="62222222"),
                booking_payload(b, at(10), customerPhone="63333333"),
                booking_payload(b, at(10), barberId=b.barber2, customerPhone="64444444")]
    outcomes = _race(payloads)
    assert [o[0] for o in outcomes] == ["ok"] * 4, outcomes


# ---------- schedule blocks vs bookings (createScheduleBlock) -------------------

import schedule_api  # noqa: E402
from reputation import apply_no_show  # noqa: E402


def make_admin(tenant):
    uid = "admin-" + uuid4().hex[:10]
    db.collection("users").document(uid).set({"role": "admin", "shopId": tenant.shop})
    return uid


def block(tenant, start, end, uid=None, barber=None, reason="Almuerzo"):
    data = {"barberId": barber or tenant.barber, "startIso": iso(start), "endIso": iso(end),
            "reason": reason}
    return schedule_api.create_block(request(data, uid=uid or tenant.barber))


def active_overlaps_block(tenant, barber):
    bookings = [r for r in _occupying(tenant, barber)
                if str(r.get("status", "pending")).lower() in ("pending", "confirmed", "live")]
    blocks = [d.to_dict() for d in db.collection("schedule_blocks")
              .where(filter=booking_api.FieldFilter("barberId", "==", barber)).get()]
    return [(b["startAt"], k["startTime"]) for b in bookings for k in blocks
            if b["startAt"] < k["endTime"] and k["startTime"] < b["endAt"]]


def test_block_rejects_interval_with_active_booking_but_not_cancelled():
    t = Tenant()
    booking_id = reserve(booking_payload(t, at(10)))["bookingId"]
    assert code_of(block, t, at(9, 30), at(10, 15)) == Code.FAILED_PRECONDITION
    assert block(t, at(10, 30), at(11))["blockId"]          # touching is fine
    db.collection("bookings").document(booking_id).update({"status": "cancelled"})
    assert block(t, at(9, 30), at(10, 15))["blockId"]


def test_booking_inside_block_is_rejected_and_removal_frees_it():
    t = Tenant()
    blk = block(t, at(12), at(13))["blockId"]
    assert iso(at(12)) not in slots(t)
    assert code_of(reserve, booking_payload(t, at(12, 30))) == Code.ALREADY_EXISTS
    db.collection("schedule_blocks").document(blk).delete()
    assert iso(at(12, 30)) in slots(t)
    assert reserve(booking_payload(t, at(12, 30)))["bookingId"]


def test_block_authorization_and_tenancy():
    a, b = Tenant(), Tenant()
    assert code_of(block, a, at(9), at(10), uid=a.barber, barber=a.barber2) == Code.PERMISSION_DENIED
    assert code_of(block, a, at(9), at(10), uid=b.barber, barber=a.barber) == Code.PERMISSION_DENIED
    assert code_of(block, a, at(9), at(10), uid=make_admin(b), barber=a.barber) == (
        Code.PERMISSION_DENIED)
    assert block(a, at(9), at(10), uid=make_admin(a), barber=a.barber2)["blockId"]
    anonymous = {"barberId": a.barber, "startIso": iso(at(9)), "endIso": iso(at(10)), "reason": "x"}
    assert code_of(schedule_api.create_block, request(anonymous)) == Code.UNAUTHENTICATED
    assert code_of(block, a, at(10), at(9)) == Code.INVALID_ARGUMENT
    assert code_of(block, a, at(9), at(9) + timedelta(days=40)) == Code.INVALID_ARGUMENT


def test_multi_day_block_checks_every_day():
    t = Tenant()
    next_day = DAY + timedelta(days=1)
    reserve(booking_payload(t, at(9, day=next_day)))
    assert code_of(block, t, at(18), at(12, day=next_day)) == Code.FAILED_PRECONDITION
    assert block(t, at(18), at(8, day=next_day))["blockId"]


def _race_calls(calls):
    barrier = threading.Barrier(len(calls))
    outcomes = [None] * len(calls)

    def run(i):
        barrier.wait()
        try:
            outcomes[i] = ("ok", calls[i]())
        except https_fn.HttpsError as error:
            outcomes[i] = ("error", error.code)
        except Exception as error:  # surfaced in the assertion message
            outcomes[i] = ("crash", repr(error))

    threads = [threading.Thread(target=run, args=(i,)) for i in range(len(calls))]
    for thread in threads:
        thread.start()
    for thread in threads:
        thread.join(timeout=120)
    return outcomes


def test_concurrent_booking_and_block_never_overlap():
    for _ in range(4):
        t = Tenant()
        outcomes = _race_calls([
            lambda: reserve(booking_payload(t, at(10), serviceId=t.long)),
            lambda: block(t, at(10, 30), at(12)),
            lambda: reserve(booking_payload(t, at(11))),
        ])
        assert active_overlaps_block(t, t.barber) == [], outcomes
        assert any(o[0] == "ok" for o in outcomes), outcomes
        assert all(o[0] == "ok" or o[1] in (Code.ALREADY_EXISTS, Code.FAILED_PRECONDITION,
                                            Code.ABORTED) for o in outcomes), outcomes


def test_concurrent_blocks_and_other_barbers_are_independent():
    t = Tenant()
    other = Tenant()
    outcomes = _race_calls([
        lambda: block(t, at(9), at(10)),
        lambda: block(t, at(9, 30), at(11)),                  # overlapping blocks are fine
        lambda: reserve(booking_payload(t, at(9), barberId=t.barber2)),
        lambda: reserve(booking_payload(other, at(9))),
    ])
    assert [o[0] for o in outcomes] == ["ok"] * 4, outcomes


# ---------- no-show reputation ---------------------------------------------------------


def mark_no_show(booking_id, by="staff-1"):
    db.collection("bookings").document(booking_id).update(
        {"status": "noshow", "statusChangedBy": by})
    return apply_no_show(db, booking_id)


def test_no_show_counts_once_and_blocks_at_threshold():
    t = Tenant(maxNoShows=2)
    phone = "33332222"
    first = reserve(booking_payload(t, at(9), customerPhone=phone))["bookingId"]
    assert mark_no_show(first) == "applied"
    assert apply_no_show(db, first) == "duplicate"          # retried trigger
    rep = booking_api.reputation_ref(db, t.shop, "+502" + phone).get().to_dict()
    assert rep["noShowCount"] == 1 and rep["shopId"] == t.shop
    event = db.collection("reputation_events").document(first).get().to_dict()
    assert event["markedBy"] == "staff-1"

    second = reserve(booking_payload(t, at(10), customerPhone=phone))["bookingId"]
    assert mark_no_show(second) == "applied"
    assert code_of(reserve, booking_payload(t, at(11), customerPhone=phone)) == (
        Code.FAILED_PRECONDITION)
    # Another tenant is unaffected.
    other = Tenant(maxNoShows=2)
    assert reserve(booking_payload(other, at(11), customerPhone=phone))["bookingId"]


def test_no_show_ignores_other_statuses_and_honours_legacy_records():
    t = Tenant()
    booking_id = reserve(booking_payload(t, at(9), customerPhone="31313131"))["bookingId"]
    assert apply_no_show(db, booking_id) == "not-no-show"
    # Legacy reputation docs were keyed by phone and carried the shopId.
    db.collection("reputation").document("+50232323232").set(
        {"shopId": t.shop, "noShowCount": 5})
    assert code_of(reserve, booking_payload(t, at(10), customerPhone="32323232")) == (
        Code.FAILED_PRECONDITION)
