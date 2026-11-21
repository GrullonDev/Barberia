"""Tests del motor puro de slots (sin Firestore ni emulador).

Ejecutar desde backend/functions:
    python -m pytest tests
"""

from __future__ import annotations

import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from slot_engine import (  # noqa: E402
    TimeRange,
    blocks_to_ranges,
    bookings_to_ranges,
    generate_candidates,
    has_conflict,
    is_within_working_hours,
)

GT = -6  # Guatemala, UTC-6
TZ = timezone(timedelta(hours=GT))


def local(y, m, d, h, mi=0) -> datetime:
    return datetime(y, m, d, h, mi, tzinfo=TZ)


def rng(start: datetime, minutes: int) -> TimeRange:
    return TimeRange(start=start, end=start + timedelta(minutes=minutes))


# ---------- TimeRange / has_conflict -----------------------------------------


def test_overlap_is_half_open():
    a = rng(local(2026, 1, 5, 10), 30)
    touching = rng(local(2026, 1, 5, 10, 30), 30)
    inside = rng(local(2026, 1, 5, 10, 15), 30)
    assert not a.overlaps(touching)
    assert not touching.overlaps(a)
    assert a.overlaps(inside)


def test_has_conflict_with_bookings_and_blocks():
    cand = rng(local(2026, 1, 5, 10), 30)
    assert not has_conflict(cand, [], [])
    assert has_conflict(cand, [rng(local(2026, 1, 5, 10, 15), 30)], [])
    assert has_conflict(cand, [], [rng(local(2026, 1, 5, 9), 90)])
    assert not has_conflict(cand, [rng(local(2026, 1, 5, 10, 30), 30)], [])


# ---------- is_within_working_hours ------------------------------------------


def test_closed_day_is_never_available():
    assert not is_within_working_hours(rng(local(2026, 1, 5, 10), 30), None, GT)


def test_slot_must_fit_entirely_inside_hours():
    hours = [9, 19]
    assert is_within_working_hours(rng(local(2026, 1, 5, 9), 30), hours, GT)
    assert is_within_working_hours(rng(local(2026, 1, 5, 18, 30), 30), hours, GT)
    assert not is_within_working_hours(rng(local(2026, 1, 5, 18, 45), 30), hours, GT)
    assert not is_within_working_hours(rng(local(2026, 1, 5, 8, 45), 30), hours, GT)


def test_working_hours_are_evaluated_in_business_timezone():
    # 15:00 UTC == 09:00 en UTC-6 -> dentro de [9, 19].
    utc_start = datetime(2026, 1, 5, 15, 0, tzinfo=timezone.utc)
    assert is_within_working_hours(rng(utc_start, 30), [9, 19], GT)
    # Misma hora UTC pero negocio en UTC+0 -> 15:00 local, también dentro.
    assert is_within_working_hours(rng(utc_start, 30), [9, 19], 0)
    # 14:30 UTC == 08:30 local GT -> fuera.
    early = datetime(2026, 1, 5, 14, 30, tzinfo=timezone.utc)
    assert not is_within_working_hours(rng(early, 30), [9, 19], GT)


def test_slot_cannot_cross_midnight():
    assert not is_within_working_hours(rng(local(2026, 1, 5, 23, 45), 30), [0, 24 - 1], GT)


# ---------- generate_candidates ----------------------------------------------


def test_generate_candidates_count_and_bounds():
    cands = generate_candidates(local(2026, 1, 5, 12), 30, 30, [9, 12], GT)
    assert len(cands) == 6  # 9:00, 9:30, ..., 11:30
    assert cands[0].start == local(2026, 1, 5, 9)
    assert cands[-1].end == local(2026, 1, 5, 12)
    assert all(c.start.tzinfo == timezone.utc for c in cands)


def test_generate_candidates_long_service_must_fit_before_close():
    cands = generate_candidates(local(2026, 1, 5, 12), 45, 30, [9, 11], GT)
    # 9:00-9:45, 9:30-10:15, 10:00-10:45; 10:30-11:15 no cabe.
    assert [c.start for c in cands] == [
        local(2026, 1, 5, 9),
        local(2026, 1, 5, 9, 30),
        local(2026, 1, 5, 10),
    ]


def test_generate_candidates_closed_day():
    assert generate_candidates(local(2026, 1, 5, 12), 30, 30, None, GT) == []


def test_generate_candidates_uses_local_date_of_input():
    # 03:00 UTC del día 6 sigue siendo el día 5 en UTC-6.
    d = datetime(2026, 1, 6, 3, 0, tzinfo=timezone.utc)
    cands = generate_candidates(d, 30, 60, [9, 10], GT)
    assert len(cands) == 1
    assert cands[0].start == local(2026, 1, 5, 9)


# ---------- adaptadores Firestore --------------------------------------------


def test_bookings_to_ranges_filters_non_occupying_statuses():
    start = local(2026, 1, 5, 10)
    docs = [
        {"status": "pending", "startAt": start, "endAt": start + timedelta(minutes=30)},
        {"status": "cancelled", "startAt": start, "endAt": start + timedelta(minutes=30)},
        {"status": "completed", "startAt": start, "endAt": start + timedelta(minutes=30)},
        {"status": "confirmed", "startAt": start.isoformat(), "endAt": None},
        {"status": "inProgress"},  # sin fechas -> se ignora
    ]
    ranges = bookings_to_ranges(docs)
    assert len(ranges) == 2
    # Sin endAt se asume 30 min.
    assert ranges[1].end - ranges[1].start == timedelta(minutes=30)


def test_bookings_default_status_is_pending_and_occupies():
    start = local(2026, 1, 5, 10)
    assert len(bookings_to_ranges([{"date": start, "endAt": start + timedelta(minutes=15)}])) == 1


def test_blocks_to_ranges_accepts_iso_and_z_suffix_and_skips_invalid():
    docs = [
        {"startTime": "2026-01-05T16:00:00Z", "endTime": "2026-01-05T17:00:00Z"},
        {"startTime": "not-a-date", "endTime": "2026-01-05T17:00:00Z"},
        {"startTime": None, "endTime": None},
    ]
    ranges = blocks_to_ranges(docs)
    assert len(ranges) == 1
    assert ranges[0].start == datetime(2026, 1, 5, 16, tzinfo=timezone.utc)


def test_naive_datetimes_are_treated_as_utc():
    naive = datetime(2026, 1, 5, 16, 0)
    ranges = blocks_to_ranges([{"startTime": naive, "endTime": naive + timedelta(hours=1)}])
    assert ranges[0].start.tzinfo == timezone.utc
