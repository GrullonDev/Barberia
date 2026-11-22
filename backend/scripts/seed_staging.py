"""Seed an isolated test tenant for staging / emulator end-to-end testing.

Creates (or converges, on rerun) one synthetic shop with an admin, two
barbers, three services, business hours and a recurring lunch block. Every
document uses a fixed id derived from --shop, so reruns overwrite the same
documents and never duplicate them. Nothing outside this tenant is touched;
existing bookings of the tenant are left alone.

Accounts (synthetic, @example.test addresses):
    admin.<shop>@example.test, barber1.<shop>@example.test, barber2.<shop>@example.test
Passwords come from the environment and are never printed or committed:
    SEED_ADMIN_PASSWORD, SEED_BARBER_PASSWORD

Usage (repo root):
    # Emulators (no credentials needed):
    FIRESTORE_EMULATOR_HOST=localhost:8080 FIREBASE_AUTH_EMULATOR_HOST=localhost:9099 \\
      SEED_ADMIN_PASSWORD=... SEED_BARBER_PASSWORD=... \\
      python backend/scripts/seed_staging.py --project demo-barberia
    # A real (staging) project requires --confirm-project with the same id:
    python backend/scripts/seed_staging.py --project <id> --confirm-project <id>

Safety: production project ids (PRODUCTION_PROJECTS) are always refused, as is
a half-configured emulator environment (only one of the two *_EMULATOR_HOST
variables set), which would write Firestore and Auth to different backends.
"""

from __future__ import annotations

import argparse
import os
import sys
from datetime import datetime, timedelta, timezone

DEFAULT_SHOP = "barberia-staging"
# Never seed these, with or without --confirm-project.
PRODUCTION_PROJECTS = frozenset({"barbershop-ee9c0"})
TEST_SHOP_PREFIXES = ("barberia-staging", "test-", "staging-")
GT = timezone(timedelta(hours=-6))


def accounts(shop):
    return {
        "admin": {"uid": f"{shop}-admin", "email": f"admin.{shop}@example.test",
                  "name": "Admin Pruebas", "role": "admin"},
        "barber1": {"uid": f"{shop}-barber-1", "email": f"barber1.{shop}@example.test",
                    "name": "Carlos Prueba", "role": "barber", "specialty": "Fade & barba"},
        "barber2": {"uid": f"{shop}-barber-2", "email": f"barber2.{shop}@example.test",
                    "name": "Diego Prueba", "role": "barber", "specialty": "Corte clásico"},
    }


SERVICES = [
    ("corte", "Corte Clásico (TEST)", 30, 75),
    ("fade", "Fade + Barba (TEST)", 60, 120),
    ("barba", "Perfilado de Barba (TEST)", 30, 50),
]


def seed(db, auth, shop, admin_password, barber_password):
    db.collection("shops").document(shop).set({
        "name": "Barbería de Pruebas", "status": "active", "isActive": True,
        "isTestTenant": True, "language": "es", "currencySymbol": "Q",
        "timezoneOffsetHours": -6, "slotMinutes": 30, "maxNoShows": 3,
        "openHour": 9, "closeHour": 19, "openDays": [True] * 6 + [False],
    }, merge=True)

    for key, account in accounts(shop).items():
        password = admin_password if account["role"] == "admin" else barber_password
        try:
            auth.update_user(account["uid"], email=account["email"], password=password,
                             display_name=account["name"], disabled=False)
        except auth.UserNotFoundError:
            auth.create_user(uid=account["uid"], email=account["email"], password=password,
                             display_name=account["name"])
        profile = {"role": account["role"], "shopId": shop, "name": account["name"],
                   "email": account["email"], "mustChangePassword": False, "isTestAccount": True}
        if account["role"] == "barber":
            profile.update({"isAvailable": True, "specialty": account["specialty"],
                            # barber2 works afternoons only, to exercise personal hours
                            "workingHours": {str(d): ([9, 19] if key == "barber1" else [13, 19])
                                             for d in range(1, 7)}})
            db.collection("barber_directory").document(account["uid"]).set({
                "name": account["name"], "photoUrl": None, "specialty": account["specialty"],
                "shopId": shop, "isAvailable": True})
        db.collection("users").document(account["uid"]).set(profile)

    for slug, name, minutes, price in SERVICES:
        db.collection("services").document(f"{shop}-{slug}").set({
            "shopId": shop, "name": name, "durationMinutes": minutes, "price": price,
            "isActive": True, "category": "hair", "extendedDescription": "Servicio de prueba."})

    # Lunch block 12:00–13:00 for barber1 on the next six business days.
    barber1 = accounts(shop)["barber1"]["uid"]
    today = datetime.now(GT).date()
    for offset in range(1, 8):
        day = today + timedelta(days=offset)
        if day.isoweekday() == 7:
            continue
        start = datetime(day.year, day.month, day.day, 12, tzinfo=GT)
        db.collection("schedule_blocks").document(f"{shop}-lunch-{day.isoformat()}").set({
            "shopId": shop, "barberId": barber1, "type": "Almuerzo", "reason": "Almuerzo",
            "startTime": start, "endTime": start + timedelta(hours=1), "createdBy": "seed"})
    return accounts(shop)


def check_target(project, confirm_project, shop, env):
    """Validate the seed target; returns True when both emulators are in use.

    Raises ValueError describing why the target is refused.
    """
    firestore_emu = bool(env.get("FIRESTORE_EMULATOR_HOST"))
    auth_emu = bool(env.get("FIREBASE_AUTH_EMULATOR_HOST"))
    if firestore_emu != auth_emu:
        raise ValueError("Set both FIRESTORE_EMULATOR_HOST and FIREBASE_AUTH_EMULATOR_HOST, "
                         "or neither: a mixed setup would seed two different backends.")
    emulated = firestore_emu and auth_emu
    if project in PRODUCTION_PROJECTS:
        raise ValueError(f"Refusing to seed production project {project!r}.")
    if not emulated and confirm_project != project:
        raise ValueError("Refusing to seed a real project without --confirm-project <same id>.")
    if not shop.startswith(TEST_SHOP_PREFIXES):
        raise ValueError("The test shop id must start with barberia-staging, staging- or test-.")
    passwords = (env.get("SEED_ADMIN_PASSWORD"), env.get("SEED_BARBER_PASSWORD"))
    if not all(passwords) or min(map(len, passwords)) < 10:
        raise ValueError("Set SEED_ADMIN_PASSWORD and SEED_BARBER_PASSWORD (10+ characters).")
    return emulated


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--project", required=True)
    parser.add_argument("--confirm-project", help="Required (same id) when not using emulators")
    parser.add_argument("--shop", default=DEFAULT_SHOP)
    args = parser.parse_args(argv)

    try:
        emulated = check_target(args.project, args.confirm_project, args.shop, os.environ)
    except ValueError as error:
        sys.exit(str(error))
    admin_password = os.environ.get("SEED_ADMIN_PASSWORD")
    barber_password = os.environ.get("SEED_BARBER_PASSWORD")

    import firebase_admin
    from firebase_admin import auth, firestore

    if emulated:
        import google.auth.credentials
        from firebase_admin import credentials

        class _Anonymous(credentials.Base):
            def get_credential(self):
                return google.auth.credentials.AnonymousCredentials()

        firebase_admin.initialize_app(_Anonymous(), {"projectId": args.project})
    else:
        firebase_admin.initialize_app(options={"projectId": args.project})
    seeded = seed(firestore.client(), auth, args.shop, admin_password, barber_password)
    print(f"Seeded shop {args.shop!r} in {args.project} ({'emulator' if emulated else 'REAL'}):")
    for account in seeded.values():
        print(f"  {account['role']:6} {account['email']}  uid={account['uid']}")


if __name__ == "__main__":
    main()
