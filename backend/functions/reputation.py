"""No-show reputation, applied server-side when staff marks a booking no-show.

Flow: staff sets `bookings/{id}.status = "noshow"` (rules require
`statusChangedBy == request.auth.uid`, the audit trail). The
`onBookingNoShow` trigger calls `apply_no_show`, which in one transaction:

  * re-reads the booking and only proceeds if it is still a no-show;
  * creates `reputation_events/{bookingId}` — `create` fails if it exists,
    so a retried or duplicated trigger can never count twice;
  * increments `reputation/{sha256(shopId, phone)}.noShowCount`.

Reputation is per tenant: one shop's no-shows never block another shop's
customers. `booking_api.reputation_blocked` applies `shops.maxNoShows`.
Clients cannot read or write either collection (see firestore.rules).
"""

from firebase_admin import firestore

import booking_api as api

NO_SHOW_STATUSES = {"noshow", "no_show", "no-show"}


def is_no_show(status):
    return isinstance(status, str) and status.strip().lower() in NO_SHOW_STATUSES


def apply_no_show(db, booking_id):
    """Returns "applied", "duplicate", "not-no-show" or "no-phone"."""
    booking_ref = db.collection("bookings").document(booking_id)
    event_ref = db.collection("reputation_events").document(booking_id)

    @firestore.transactional
    def commit(tx):
        booking = booking_ref.get(transaction=tx).to_dict() or {}
        if not is_no_show(booking.get("status")):
            return "not-no-show"
        if event_ref.get(transaction=tx).exists:
            return "duplicate"
        shop_id = booking.get("shopId")
        phone = booking.get("phoneNormalized") or booking.get("customerPhone")
        if not isinstance(shop_id, str) or not shop_id or not isinstance(phone, str) or not phone:
            return "no-phone"
        rep_ref = api.reputation_ref(db, shop_id, phone)
        rep = rep_ref.get(transaction=tx).to_dict() or {}
        count = rep.get("noShowCount", 0)
        count = (count if type(count) is int and count >= 0 else 0) + 1
        timestamp = firestore.SERVER_TIMESTAMP
        tx.create(event_ref, {
            "bookingId": booking_id, "shopId": shop_id, "phoneNormalized": phone,
            "markedBy": booking.get("statusChangedBy"), "createdAt": timestamp})
        tx.set(rep_ref, {
            "shopId": shop_id, "phoneNormalized": phone, "noShowCount": count,
            "blocked": rep.get("blocked") is True, "lastNoShowBookingId": booking_id,
            "lastNoShowAt": timestamp, "updatedAt": timestamp})
        return "applied"

    return commit(db.transaction())
