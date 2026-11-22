"""Public barber profiles, derived exclusively from the current private profile."""

from google.cloud import firestore


def public_profile(data):
    shop_id = data.get("shopId")
    if data.get("role") != "barber" or not isinstance(shop_id, str) or not shop_id.strip():
        return None
    entry = {
        key: data[key] if isinstance(data.get(key), str) else None
        for key in ("name", "photoUrl", "specialty")
    }
    return {**entry, "shopId": shop_id, "isAvailable": data.get("isAvailable", True) is True}


@firestore.transactional
def reconcile(transaction, user_ref, public_ref, dry_run=False):
    # Re-read both documents so retries and out-of-order events converge.
    profile = public_profile(user_ref.get(transaction=transaction).to_dict() or {})
    previous = public_ref.get(transaction=transaction).to_dict()
    if previous == profile:
        return "unchanged"
    if profile is None:
        if not dry_run:
            transaction.delete(public_ref)
        return "delete"
    if not dry_run:
        transaction.set(public_ref, profile)
    return "replace"
