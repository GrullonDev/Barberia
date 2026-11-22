"""Reconcile public barber profiles (`barber_directory`). Dry run by default.

For each uid that is a barber in `users` or already has a public entry, the
public entry is recomputed from the private profile (barber_directory.py):

  * replace  — barber with a shopId: entry set to the allowlisted fields
               (name, photoUrl, specialty, shopId, isAvailable);
  * delete   — entry whose user is missing, no longer a barber, or has no
               shopId (also removes private fields leaked into old entries);
  * unchanged — already correct.

Unavailable barbers keep their entry with `isAvailable: false` (the booking
page hides them); only non-barbers are deleted. Other collections are never
touched. Reruns are no-ops once converged.

Usage (from the repo root):
    python backend/scripts/migrate_barber_directory.py --project <id> [--shop <shopId>]
    python backend/scripts/migrate_barber_directory.py --project <id> --apply [--backup FILE]

With --apply, the current public entries that will change are first saved
to a JSON backup (default barber_directory_backup_<timestamp>.json); restore
an entry by writing that JSON back to barber_directory/{uid}.
"""

from __future__ import annotations

import argparse
import json
import sys
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "functions"))

from barber_directory import public_profile, reconcile  # noqa: E402


def plan(db, shop_id: str | None = None) -> list[dict]:
    users = db.collection("users")
    directory = db.collection("barber_directory")
    entries = {snap.id: snap.to_dict() or {} for snap in directory.stream()}
    barbers = {snap.id: snap.to_dict() or {} for snap in
               users.where("role", "==", "barber").stream()}
    actions = []
    for uid in sorted(set(entries) | set(barbers)):
        profile = barbers.get(uid)
        if profile is None:
            snap = users.document(uid).get()
            profile = snap.to_dict() or {} if snap.exists else {}
        current = entries.get(uid)
        tenants = {(current or {}).get("shopId"), profile.get("shopId")} - {None}
        if shop_id and shop_id not in tenants:
            continue   # tenant-scoped run: leave other shops alone
        target = public_profile(profile)
        action = "unchanged" if current == target else ("delete" if target is None else "replace")
        actions.append({"uid": uid, "action": action, "shopId": (current or profile).get("shopId"),
                        "current": current, "target": target,
                        "reason": None if action != "delete" else
                        ("user missing" if not profile else
                         f"role={profile.get('role')!r} shopId={profile.get('shopId')!r}")})
    return actions


def apply(db, actions: list[dict]) -> Counter:
    users = db.collection("users")
    directory = db.collection("barber_directory")
    counts = Counter()
    for item in actions:
        if item["action"] == "unchanged":
            counts["unchanged"] += 1
            continue
        # reconcile re-reads both documents transactionally, so a profile
        # edited since the plan converges to its latest state.
        counts[reconcile(db.transaction(), users.document(item["uid"]),
                         directory.document(item["uid"]))] += 1
    return counts


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--project", required=True, help="Firebase project id (explicit, never implied)")
    parser.add_argument("--shop", help="Only reconcile entries belonging to this shopId")
    parser.add_argument("--apply", action="store_true", help="Write changes (default: dry run)")
    parser.add_argument("--backup", help="Backup file for entries that will change (with --apply)")
    args = parser.parse_args(argv)

    import firebase_admin
    from firebase_admin import firestore

    firebase_admin.initialize_app(options={"projectId": args.project})
    db = firestore.client()
    actions = plan(db, args.shop)
    for item in actions:
        if item["action"] != "unchanged":
            print(f"{item['action']:8} {item['uid']} shop={item['shopId']}"
                  + (f" ({item['reason']})" if item["reason"] else ""))
    print("Plan:", dict(Counter(item["action"] for item in actions)))
    if not args.apply:
        print("Dry run: nothing written. Re-run with --apply to write.")
        return
    changing = {i["uid"]: i["current"] for i in actions if i["action"] != "unchanged" and i["current"]}
    backup = Path(args.backup or
                  f"barber_directory_backup_{datetime.now(timezone.utc):%Y%m%dT%H%M%SZ}.json")
    backup.write_text(json.dumps(changing, indent=2, ensure_ascii=False, default=str))
    print(f"Backed up {len(changing)} entries to {backup}")
    print("Applied:", dict(apply(db, actions)))


if __name__ == "__main__":
    main()
