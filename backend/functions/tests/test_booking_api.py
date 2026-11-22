"""Pure tests for booking_api validation and scheduling helpers (no emulator).

Run from backend/functions:
    python -m pytest tests
"""

from __future__ import annotations

import sys
from datetime import date, datetime, timedelta, timezone
from pathlib import Path
from types import SimpleNamespace

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from firebase_functions import https_fn  # noqa: E402

import booking_api  # noqa: E402
from slot_engine import (  # noqa: E402
    TimeRange,
    bookings_to_ranges,
    occupies_slot,
    parse_legacy_time,
)

GT = timezone(timedelta(hours=-6))
Code = https_fn.FunctionsErrorCode


def error_code(fn, *args):
    with pytest.raises(https_fn.HttpsError) as info:
        fn(*args)
    return info.value.code


# ---------- customer payload -------------------------------------------------


def test_customer_normalizes_local_and_prefixed_phones():
    assert booking_api.customer({"customerName": " Ana ", "customerPhone": "5555 1234"})[:2] == (
        "Ana", "+50255551234")
    assert booking_api.customer({"customerName": "Ana", "customerPhone": "50255551234"})[1] == (
        "+50255551234")
    assert booking_api.customer({"customerName": "Ana", "customerPhone": "+1 (415) 555-0100"})[1] == (
        "+14155550100")


@pytest.mark.parametrize("payload", [
    {"customerName": "A", "customerPhone": "55551234"},                  # name too short
    {"customerName": "x" * 101, "customerPhone": "55551234"},            # name too long
    {"customerName": "Ana\x00", "customerPhone": "55551234"},            # control char
    {"customerName": "Ana", "customerPhone": "1234"},                    # phone too short
    {"customerName": "Ana", "customerPhone": "+0123456789"},             # invalid country
    {"customerName": "Ana", "customerPhone": "55551234", "customerEmail": "nope"},
    {"customerName": "Ana", "customerPhone": "55551234", "notes": "n" * 501},
    {"customerName": 42, "customerPhone": "55551234"},                   # wrong type
    {"customerPhone": "55551234"},                                       # missing name
])
def test_customer_rejects_invalid_payloads(payload):
    assert error_code(booking_api.customer, payload) == Code.INVALID_ARGUMENT


def test_customer_email_and_notes_are_optional():
    name, phone, email, notes = booking_api.customer(
        {"customerName": "Ana", "customerPhone": "55551234"})
    assert (email, notes) == ("", "")


# ---------- request envelope --------------------------------------------------


@pytest.mark.parametrize("data", [
    None,
    "not-a-dict",
    {"barberId": "b", "serviceId": "s"},                         # missing shopId
    {"shopId": "a/b", "barberId": "b", "serviceId": "s"},        # path traversal
    {"shopId": "..", "barberId": "b", "serviceId": "s"},
    {"shopId": "a", "barberId": "", "serviceId": "s"},
])
def test_inputs_rejects_malformed_identifiers(data):
    assert error_code(booking_api.inputs, SimpleNamespace(data=data)) == Code.INVALID_ARGUMENT


def test_instant_requires_timezone():
    assert booking_api.instant("2026-01-05T16:00:00Z") == datetime(2026, 1, 5, 16, tzinfo=timezone.utc)
    assert booking_api.instant("2026-01-05T10:00:00-06:00") == datetime(2026, 1, 5, 16, tzinfo=timezone.utc)
    assert error_code(booking_api.instant, "2026-01-05T16:00:00") == Code.INVALID_ARGUMENT
    assert error_code(booking_api.instant, "garbage") == Code.INVALID_ARGUMENT


# ---------- shop timezone & working hours --------------------------------------


def test_shop_timezone_defaults_to_guatemala_and_validates():
    assert booking_api.shop_timezone({}).utcoffset(None) == timedelta(hours=-6)
    assert booking_api.shop_timezone({"timezoneOffsetHours": -5}).utcoffset(None) == timedelta(hours=-5)
    for bad in (-13, 15, "−6", 1.5, None):
        assert error_code(booking_api.shop_timezone, {"timezoneOffsetHours": bad}) == (
            Code.FAILED_PRECONDITION)


MONDAY = datetime(2026, 1, 5, tzinfo=GT)
SUNDAY = datetime(2026, 1, 11, tzinfo=GT)


def test_working_hours_default_week_closes_sunday():
    assert booking_api.working_hours({}, {}, MONDAY) == [9, 19]
    assert booking_api.working_hours({}, {}, SUNDAY) is None


def test_working_hours_intersects_barber_override_with_shop_hours():
    shop = {"openHour": 10, "closeHour": 18}
    assert booking_api.working_hours(shop, {"workingHours": {"1": [8, 20]}}, MONDAY) == [10, 18]
    assert booking_api.working_hours(shop, {"workingHours": {"1": [12, 16]}}, MONDAY) == [12, 16]
    assert booking_api.working_hours(shop, {"workingHours": {"1": None}}, MONDAY) is None


def test_working_hours_respects_closed_days_and_barber_day_off():
    closed_monday = {"openDays": [False] + [True] * 5 + [False]}
    assert booking_api.working_hours(closed_monday, {}, MONDAY) is None
    assert booking_api.working_hours({}, {"availability": {"Mon": False}}, MONDAY) is None


def test_working_hours_rejects_corrupt_configuration():
    assert error_code(booking_api.working_hours, {"openHour": 19, "closeHour": 9}, {}, MONDAY) == (
        Code.FAILED_PRECONDITION)
    assert error_code(booking_api.working_hours, {"openHour": 9.0}, {}, MONDAY) == (
        Code.FAILED_PRECONDITION)


# ---------- client network key -----------------------------------------------------


def test_client_network_prefers_last_forwarded_hop():
    raw = SimpleNamespace(headers={"X-Forwarded-For": "6.6.6.6, 203.0.113.7"}, remote_addr="10.0.0.1")
    assert booking_api.client_network(raw) == "203.0.113.7"
    assert booking_api.client_network(SimpleNamespace(headers={}, remote_addr="10.0.0.1")) == "10.0.0.1"
    assert booking_api.client_network(None) is None


# ---------- slot engine: status & legacy compatibility ----------------------------


@pytest.mark.parametrize("status", ["pending", "PENDING", "Confirmed", "LIVE", "live",
                                    "inProgress", "ACTIVE", None])
def test_occupying_statuses_are_case_insensitive(status):
    assert occupies_slot(status)


@pytest.mark.parametrize("status", ["cancelled", "CANCELLED", "canceled", "completed",
                                    "FINISHED", "noshow", "no_show", "NOSHOW", "", 7])
def test_terminal_statuses_release_the_slot(status):
    assert not occupies_slot(status)


def test_parse_legacy_time():
    assert parse_legacy_time("10:00 AM") == (10, 0)
    assert parse_legacy_time("12:15 AM") == (0, 15)
    assert parse_legacy_time("12:30 PM") == (12, 30)
    assert parse_legacy_time("2:45 pm") == (14, 45)
    assert parse_legacy_time("14:30") == (14, 30)
    for bad in ("13:00 PM", "25:00", "10:75", "ten", None, 10):
        assert parse_legacy_time(bad) is None


def test_legacy_booking_uses_local_date_and_time_string():
    # Old admin "manual" bookings stored the creation timestamp in `date` and
    # the appointment clock time in `time`.
    created = datetime(2026, 1, 5, 8, 0, tzinfo=GT)
    ranges = bookings_to_ranges(
        [{"status": "CONFIRMED", "date": created, "time": "02:30 PM"}], -6)
    assert ranges == [TimeRange(datetime(2026, 1, 5, 14, 30, tzinfo=GT),
                                datetime(2026, 1, 5, 15, 0, tzinfo=GT))]


def test_live_and_uppercase_bookings_block_their_interval():
    start = datetime(2026, 1, 5, 10, tzinfo=GT)
    docs = [{"status": s, "startAt": start, "endAt": start + timedelta(minutes=45)}
            for s in ("live", "CONFIRMED", "cancelled")]
    assert len(bookings_to_ranges(docs)) == 2


def test_missing_end_uses_recorded_duration():
    start = datetime(2026, 1, 5, 10, tzinfo=GT)
    (r,) = bookings_to_ranges([{"startAt": start, "serviceDurationMinutes": 60}])
    assert r.end - r.start == timedelta(minutes=60)


def test_schedule_uses_business_local_day():
    # 2026-01-05 is a Monday in Guatemala.
    assert date(2026, 1, 5).isoweekday() == 1
