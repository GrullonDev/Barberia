"""Staging seed script against the Auth + Firestore emulators.

    firebase emulators:exec --only auth,firestore --project demo-barberia \
        "python -m pytest backend/tests/test_seed_staging_emulator.py -q"
"""

from __future__ import annotations

import importlib.util
import os
from pathlib import Path
from uuid import uuid4

import pytest

if os.environ.get("FIRESTORE_EMULATOR_HOST", "").split(":")[0] not in {"127.0.0.1", "localhost"}:
    pytest.skip("requires the local Firestore emulator", allow_module_level=True)
if not os.environ.get("FIREBASE_AUTH_EMULATOR_HOST"):
    pytest.skip("requires the local Auth emulator", allow_module_level=True)

import firebase_admin  # noqa: E402
import google.auth.credentials  # noqa: E402
from firebase_admin import auth, credentials, firestore  # noqa: E402

SCRIPTS = Path(__file__).resolve().parents[1] / "scripts"
spec = importlib.util.spec_from_file_location("seed_staging", SCRIPTS / "seed_staging.py")
seed_staging = importlib.util.module_from_spec(spec)
spec.loader.exec_module(seed_staging)


class _EmulatorCredential(credentials.Base):
    def get_credential(self):
        return google.auth.credentials.AnonymousCredentials()


if not firebase_admin._apps:
    firebase_admin.initialize_app(_EmulatorCredential(), {"projectId": "demo-barberia"})
db = firestore.client()

PASSWORDS = {"SEED_ADMIN_PASSWORD": "admin-pass-123", "SEED_BARBER_PASSWORD": "barber-pass-123"}
EMULATORS = {"FIRESTORE_EMULATOR_HOST": "localhost:8080",
             "FIREBASE_AUTH_EMULATOR_HOST": "localhost:9099"}


# ---------- target guard ---------------------------------------------------------------


def test_guard_accepts_emulators_without_confirmation():
    assert seed_staging.check_target("demo-barberia", None, "test-x", {**EMULATORS, **PASSWORDS})


def test_guard_requires_confirmation_for_real_project():
    with pytest.raises(ValueError, match="confirm-project"):
        seed_staging.check_target("barberia-staging", None, "test-x", PASSWORDS)
    assert seed_staging.check_target(
        "barberia-staging", "barberia-staging", "test-x", PASSWORDS) is False


@pytest.mark.parametrize("env", [PASSWORDS, {**EMULATORS, **PASSWORDS}])
def test_guard_always_refuses_production(env):
    for project in seed_staging.PRODUCTION_PROJECTS:
        with pytest.raises(ValueError, match="production"):
            seed_staging.check_target(project, project, "test-x", env)


@pytest.mark.parametrize("missing", list(EMULATORS))
def test_guard_refuses_half_configured_emulators(missing):
    env = {**EMULATORS, **PASSWORDS}
    del env[missing]
    with pytest.raises(ValueError, match="both"):
        seed_staging.check_target("demo-barberia", "demo-barberia", "test-x", env)


def test_guard_refuses_non_test_shop_and_weak_passwords():
    env = {**EMULATORS, **PASSWORDS}
    with pytest.raises(ValueError, match="shop id"):
        seed_staging.check_target("demo-barberia", None, "barberia", env)
    with pytest.raises(ValueError, match="10\\+"):
        seed_staging.check_target("demo-barberia", None, "test-x",
                                  {**EMULATORS, "SEED_ADMIN_PASSWORD": "short",
                                   "SEED_BARBER_PASSWORD": "barber-pass-123"})


# ---------- seeding --------------------------------------------------------------------


def tenant_docs(shop):
    return {name: sorted(d.id for d in db.collection(name).where("shopId", "==", shop).stream())
            for name in ("users", "barber_directory", "services", "schedule_blocks")}


def test_seed_is_idempotent_and_tenant_scoped():
    shop = "test-" + uuid4().hex[:8]
    other = db.collection("shops").document("shop-" + uuid4().hex[:8])
    other.set({"name": "Otro", "timezoneOffsetHours": -6})
    booking = db.collection("bookings").document()
    booking.set({"shopId": shop, "status": "CONFIRMED", "customerName": "Existente"})

    seed_staging.seed(db, auth, shop, "admin-pass-123", "barber-pass-123")
    first = tenant_docs(shop)
    seed_staging.seed(db, auth, shop, "admin-pass-123", "barber-pass-123")
    second = tenant_docs(shop)

    assert first == second
    assert len(first["users"]) == 3
    assert len(first["barber_directory"]) == 2
    assert len(first["services"]) == len(seed_staging.SERVICES)
    assert 5 <= len(first["schedule_blocks"]) <= 7   # next 7 days minus Sundays
    assert db.collection("shops").document(shop).get().to_dict()["isTestTenant"] is True
    assert other.get().to_dict() == {"name": "Otro", "timezoneOffsetHours": -6}
    assert booking.get().to_dict()["customerName"] == "Existente"

    for account in seed_staging.accounts(shop).values():
        user = auth.get_user(account["uid"])
        assert user.email == account["email"] and not user.disabled
        profile = db.collection("users").document(account["uid"]).get().to_dict()
        assert profile["shopId"] == shop and profile["role"] == account["role"]
