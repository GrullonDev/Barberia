"""barber_directory reconciliation against the Firestore emulator.

    firebase emulators:exec --only firestore --project demo-barberia \
        "python -m pytest backend/tests/test_barber_directory_emulator.py -q"
"""

from __future__ import annotations

import os
import sys
from pathlib import Path
from uuid import uuid4

import pytest

if os.environ.get("FIRESTORE_EMULATOR_HOST", "").split(":")[0] not in {"127.0.0.1", "localhost"}:
    pytest.skip("requires the local Firestore emulator", allow_module_level=True)

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "functions"))

import firebase_admin  # noqa: E402
import google.auth.credentials  # noqa: E402
from firebase_admin import credentials, firestore  # noqa: E402

from barber_directory import reconcile  # noqa: E402


class _EmulatorCredential(credentials.Base):
    def get_credential(self):
        return google.auth.credentials.AnonymousCredentials()


if not firebase_admin._apps:
    firebase_admin.initialize_app(_EmulatorCredential(), {"projectId": "demo-barberia"})
db = firestore.client()


def refs():
    uid = uuid4().hex
    return db.collection("users").document(uid), db.collection("barber_directory").document(uid)


def test_projection_exposes_only_allowlisted_fields():
    user, public = refs()
    user.set({"role": "barber", "shopId": "a", "name": "Ana", "email": "ana@private.test",
              "phone": "+50255551234", "workingHours": {"1": [9, 19]}, "specialty": 7})
    assert reconcile(db.transaction(), user, public) == "replace"
    assert public.get().to_dict() == {"name": "Ana", "photoUrl": None, "specialty": None,
                                      "shopId": "a", "isAvailable": True}
    assert reconcile(db.transaction(), user, public) == "unchanged"


def test_demoted_or_unassigned_profiles_are_removed():
    user, public = refs()
    user.set({"role": "barber", "shopId": "a", "name": "Ana"})
    reconcile(db.transaction(), user, public)
    user.update({"role": "client"})
    assert reconcile(db.transaction(), user, public) == "delete"
    assert not public.get().exists


def test_dry_run_writes_nothing():
    user, public = refs()
    user.set({"role": "barber", "shopId": "a", "name": "Ana"})
    assert reconcile(db.transaction(), user, public, dry_run=True) == "replace"
    assert not public.get().exists
