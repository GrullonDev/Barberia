"""Migration scripts against the Firestore emulator.

    firebase emulators:exec --only firestore --project demo-barberia \
        "python -m pytest backend/tests/test_migrations_emulator.py -q"
"""

from __future__ import annotations

import importlib.util
import os
from datetime import datetime, timedelta, timezone
from pathlib import Path
from uuid import uuid4

import pytest

if os.environ.get("FIRESTORE_EMULATOR_HOST", "").split(":")[0] not in {"127.0.0.1", "localhost"}:
    pytest.skip("requires the local Firestore emulator", allow_module_level=True)

import firebase_admin  # noqa: E402
import google.auth.credentials  # noqa: E402
from firebase_admin import credentials, firestore  # noqa: E402

SCRIPTS = Path(__file__).resolve().parents[1] / "scripts"
GT = timezone(timedelta(hours=-6))


def load(name):
    spec = importlib.util.spec_from_file_location(name, SCRIPTS / f"{name}.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


legacy = load("migrate_legacy_bookings")
directory = load("migrate_barber_directory")


class _EmulatorCredential(credentials.Base):
    def get_credential(self):
        return google.auth.credentials.AnonymousCredentials()


if not firebase_admin._apps:
    firebase_admin.initialize_app(_EmulatorCredential(), {"projectId": "demo-barberia"})
db = firestore.client()


def shop():
    shop_id = "shop-" + uuid4().hex[:10]
    db.collection("shops").document(shop_id).set({"timezoneOffsetHours": -6})
    return shop_id


# ---------- legacy bookings ------------------------------------------------------------


def test_legacy_plan_is_dry_and_only_targets_rows_without_start():
    s = shop()
    created = datetime(2026, 1, 6, 5, 30, tzinfo=timezone.utc)   # Jan 5, 23:30 GT
    manual = db.collection("bookings").document()
    manual.set({"shopId": s, "date": created, "time": "09:00 AM", "status": "CONFIRMED"})
    canonical = db.collection("bookings").document()
    canonical.set({"shopId": s, "startAt": datetime(2026, 2, 1, 15, tzinfo=timezone.utc),
                   "date": datetime(2026, 2, 1, 15, tzinfo=timezone.utc)})
    broken = db.collection("bookings").document()
    broken.set({"shopId": s, "date": created, "time": "noon"})

    planned = legacy.plan(db, s)
    assert [u["id"] for u in planned["updates"]] == [manual.id]
    assert [k["id"] for k in planned["skipped"]] == [broken.id]
    assert planned["updates"][0]["startAt"] == datetime(2026, 1, 5, 9, tzinfo=GT)
    assert "startAt" not in manual.get().to_dict()   # dry run wrote nothing


def test_legacy_apply_preserves_original_and_is_idempotent():
    s = shop()
    created = datetime(2026, 1, 5, 14, tzinfo=timezone.utc)
    ref = db.collection("bookings").document()
    ref.set({"shopId": s, "date": created, "time": "2:30 PM", "serviceDurationMinutes": 45})
    assert legacy.apply(db, legacy.plan(db, s)) == {"applied": 1, "conflicts": []}
    doc = ref.get().to_dict()
    assert doc["startAt"] == datetime(2026, 1, 5, 14, 30, tzinfo=GT)
    assert doc["endAt"] == datetime(2026, 1, 5, 15, 15, tzinfo=GT)
    assert doc["date"] == doc["startAt"]
    assert doc["legacyDate"] == created and doc["createdAt"] == created
    assert legacy.plan(db, s)["updates"] == []       # rerun is a no-op


def test_legacy_apply_skips_rows_edited_after_planning():
    s = shop()
    ref = db.collection("bookings").document()
    ref.set({"shopId": s, "date": datetime(2026, 1, 5, 14, tzinfo=timezone.utc), "time": "10:00 AM"})
    planned = legacy.plan(db, s)
    ref.update({"status": "cancelled"})
    assert legacy.apply(db, planned) == {"applied": 0, "conflicts": [ref.id]}
    assert "startAt" not in ref.get().to_dict()


def test_legacy_plan_is_tenant_scoped():
    a, b = shop(), shop()
    db.collection("bookings").add({"shopId": b, "date": datetime.now(timezone.utc), "time": "10:00 AM"})
    assert legacy.plan(db, a)["updates"] == []


# ---------- barber directory -------------------------------------------------------------


def test_directory_plan_reports_deletions_and_respects_shop_scope():
    s, other = shop(), shop()
    keep, demoted, foreign = uuid4().hex, uuid4().hex, uuid4().hex
    db.collection("users").document(keep).set({"role": "barber", "shopId": s, "name": "A",
                                               "isAvailable": False})
    db.collection("users").document(demoted).set({"role": "client", "shopId": s})
    db.collection("barber_directory").document(demoted).set({"shopId": s, "name": "Old",
                                                             "email": "leak@example.test"})
    db.collection("users").document(foreign).set({"role": "barber", "shopId": other, "name": "F"})

    actions = {a["uid"]: a for a in directory.plan(db, s)}
    assert actions[keep]["action"] == "replace"
    assert actions[keep]["target"]["isAvailable"] is False    # inactive barbers are kept
    assert actions[demoted]["action"] == "delete" and "client" in actions[demoted]["reason"]
    assert foreign not in actions
    assert db.collection("barber_directory").document(demoted).get().exists   # dry run

    counts = directory.apply(db, list(actions.values()))
    assert counts["replace"] == 1 and counts["delete"] == 1
    assert not db.collection("barber_directory").document(demoted).get().exists
    assert not db.collection("barber_directory").document(foreign).get().exists  # untouched
    assert {a["action"] for a in directory.plan(db, s)} == {"unchanged"}
