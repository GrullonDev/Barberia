"""Backfill `startAt`/`endAt` on legacy manual bookings. Dry run by default.

Old admin "manual" bookings stored the *creation* time in `date` and the
appointment clock time in `time` ("10:00 AM"), with no `startAt`. Reads
already compensate (slot_engine.bookings_to_ranges, staff_booking.dart);
this script makes the canonical fields explicit so queries and reports
agree.

For every booking WITHOUT `startAt` whose `time` parses:
    startAt      = business-local day of `date` at `time`
                   (shops/{shopId}.timezoneOffsetHours, default -6)
    endAt        = startAt + serviceDurationMinutes (default 30)
    date         = startAt                   (canonical mirror)
    legacyDate   = original `date`           (kept for recovery)
    createdAt    = original `date` if createdAt is missing
    legacyMigratedAt = server timestamp

Rows that already have `startAt` are never touched, so reruns are no-ops.
Rows whose `time` does not parse are reported and skipped. Each write has
an update_time precondition: a row edited during the run is skipped, not
overwritten.

Usage (from the repo root, credentials via ADC or GOOGLE_APPLICATION_CREDENTIALS):
    python backend/scripts/migrate_legacy_bookings.py --project <id> [--shop <shopId>]
    python backend/scripts/migrate_legacy_bookings.py --project <id> --apply

Recovery: `legacyDate` holds the original value; restore with
    date = legacyDate, and delete startAt/endAt/legacyDate/legacyMigratedAt.
"""

from __future__ import annotations

import argparse
import json
import sys
from datetime import timedelta
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "functions"))

from slot_engine import LEGACY_DEFAULT_MINUTES, _coerce_dt, _legacy_start, parse_legacy_time  # noqa: E402

DEFAULT_OFFSET = -6


def plan(db, shop_id: str | None = None) -> dict:
    """Returns {"updates": [...], "skipped": [...]} without writing."""
    offsets: dict[str, int] = {}

    def offset_for(shop):
        if shop not in offsets:
            data = db.collection("shops").document(shop).get().to_dict() or {}
            value = data.get("timezoneOffsetHours", DEFAULT_OFFSET)
            offsets[shop] = value if type(value) is int else DEFAULT_OFFSET
        return offsets[shop]

    query = db.collection("bookings")
    if shop_id:
        query = query.where("shopId", "==", shop_id)
    updates, skipped = [], []
    for snap in query.stream():
        doc = snap.to_dict() or {}
        if doc.get("startAt") is not None:
            continue
        shop = doc.get("shopId")
        original = _coerce_dt(doc.get("date"))
        if not isinstance(shop, str) or original is None or parse_legacy_time(doc.get("time")) is None:
            skipped.append({"id": snap.id, "shopId": shop, "reason": "missing shopId, date or parseable time",
                            "time": doc.get("time")})
            continue
        start = _legacy_start(doc, offset_for(shop))
        minutes = doc.get("serviceDurationMinutes")
        if type(minutes) is not int or minutes <= 0:
            minutes = LEGACY_DEFAULT_MINUTES
        updates.append({"id": snap.id, "shopId": shop, "updateTime": snap.update_time,
                        "original": original, "startAt": start,
                        "endAt": start + timedelta(minutes=minutes),
                        "setCreatedAt": doc.get("createdAt") is None})
    return {"updates": updates, "skipped": skipped}


def apply(db, planned: dict) -> dict:
    from google.api_core.exceptions import FailedPrecondition
    from google.cloud import firestore

    applied, conflicts = 0, []
    for item in planned["updates"]:
        ref = db.collection("bookings").document(item["id"])
        data = {"startAt": item["startAt"], "endAt": item["endAt"], "date": item["startAt"],
                "legacyDate": item["original"], "legacyMigratedAt": firestore.SERVER_TIMESTAMP}
        if item["setCreatedAt"]:
            data["createdAt"] = item["original"]
        try:
            ref.update(data, option=db.write_option(last_update_time=item["updateTime"]))
            applied += 1
        except FailedPrecondition:
            conflicts.append(item["id"])
    return {"applied": applied, "conflicts": conflicts}


def _printable(planned):
    return {
        "updates": [{k: (v.isoformat() if hasattr(v, "isoformat") else v)
                     for k, v in item.items() if k != "updateTime"} for item in planned["updates"]],
        "skipped": planned["skipped"],
    }


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--project", required=True, help="Firebase project id (explicit, never implied)")
    parser.add_argument("--shop", help="Only migrate this shopId")
    parser.add_argument("--apply", action="store_true", help="Write changes (default: dry run)")
    args = parser.parse_args(argv)

    import firebase_admin
    from firebase_admin import firestore as admin_firestore

    firebase_admin.initialize_app(options={"projectId": args.project})
    db = admin_firestore.client()
    planned = plan(db, args.shop)
    print(json.dumps(_printable(planned), indent=2, ensure_ascii=False))
    print(f"{len(planned['updates'])} to update, {len(planned['skipped'])} skipped.")
    if not args.apply:
        print("Dry run: nothing written. Re-run with --apply to write.")
        return
    print(json.dumps(apply(db, planned)))


if __name__ == "__main__":
    main()
