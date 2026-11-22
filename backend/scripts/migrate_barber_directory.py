"""Reconcile public barber profiles. Preview with --dry-run before applying."""

import argparse
from collections import Counter
from pathlib import Path
import sys

import firebase_admin
from firebase_admin import firestore
from google.cloud.firestore_v1.base_query import FieldFilter

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "functions"))
from barber_directory import reconcile


def _migrate_barber_directory(db, dry_run):
    users = db.collection("users")
    directory = db.collection("barber_directory")
    # Existing entries are included to remove stale profiles and private fields.
    ids = {doc.id for doc in directory.select([]).stream()}
    ids.update(doc.id for doc in users.where(filter=FieldFilter("role", "==", "barber")).select([]).stream())
    counts = Counter()
    for uid in sorted(ids):
        result = reconcile(db.transaction(), users.document(uid), directory.document(uid), dry_run)
        counts[result] += 1
    print(f"{'Preview' if dry_run else 'Applied'}: {dict(counts)}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    firebase_admin.initialize_app()
    _migrate_barber_directory(firestore.client(), args.dry_run)
