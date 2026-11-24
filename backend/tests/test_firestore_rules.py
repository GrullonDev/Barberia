"""Run with firebase emulators:exec --only auth,firestore --project demo-barberia."""

import json
import os
import unittest
from urllib.error import HTTPError
from urllib.request import Request, urlopen
from uuid import uuid4


def emulator(name):
    host = os.environ[name]
    if host.split(":")[0] not in {"127.0.0.1", "localhost"}:
        raise RuntimeError("Tests require local emulators")
    return "http://" + host


def call(url, method, data=None, token=None):
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = "Bearer " + token
    request = Request(url, data=None if data is None else json.dumps(data).encode(),
                      method=method, headers=headers)
    try:
        with urlopen(request) as response:
            return response.status, json.load(response)
    except HTTPError as error:
        return error.code, json.load(error)


class Authorization(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.base = emulator("FIRESTORE_EMULATOR_HOST") + "/v1/projects/demo-barberia/databases/(default)/documents/"
        auth = emulator("FIREBASE_AUTH_EMULATOR_HOST") + "/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo"
        cls.auth_url = auth
        cls.people = {}
        for label, role, shop in [('admin', 'admin', 'a'), ('barber', 'barber', 'a'),
                                  ('other', 'barber', 'b'), ('client', 'client', None)]:
            code, account = call(auth, "POST", {"returnSecureToken": True})
            assert code == 200, account
            uid = account['localId']
            cls.people[label] = uid, account['idToken']
            cls.put("users/" + uid, {"role": role, **({"shopId": shop} if shop else {})}, "owner")
        cls.booking = "bookings/" + uuid4().hex
        cls.put(cls.booking, {"shopId": "a", "barberId": cls.people['barber'][0],
                              "userId": cls.people['client'][0], "status": "pending"}, "owner")

    @classmethod
    def put(cls, path, fields, token, update=False):
        mask = "?" + "&".join("updateMask.fieldPaths=" + key for key in fields) if update else ""
        return call(cls.base + path + mask, "PATCH", {"fields": {
            key: {"stringValue": value} for key, value in fields.items()}}, token)

    def test_user_and_service_boundaries(self):
        client, token = self.people['client']
        self.assertEqual(self.put("users/" + client, {"name": "Client"}, token, True)[0], 200)
        self.assertEqual(self.put("users/" + client, {"role": "admin"}, token, True)[0], 403)
        other = "users/" + self.people['other'][0]
        self.assertEqual(call(self.base + other, "GET")[0], 403)
        self.assertEqual(self.put(other, {"shopId": "a"}, self.people['admin'][1], True)[0], 403)
        service = 'services/' + uuid4().hex
        self.put(service, {"shopId": "b"}, "owner")
        self.assertEqual(self.put(service, {"shopId": "a"}, self.people['admin'][1], True)[0], 403)

    def test_booking_boundaries(self):
        for label in ('client', 'barber', 'admin'):
            token = self.people[label][1]
            self.assertEqual(self.put("bookings/" + uuid4().hex, {"shopId": "a"}, token)[0], 403)
            self.assertEqual(call(self.base + self.booking, "GET", token=token)[0], 200)
            self.assertEqual(self.put(self.booking, {"shopId": "b"}, token, True)[0], 403)
        self.assertEqual(call(self.base + self.booking, "GET", token=self.people['other'][1])[0], 403)
        self.assertEqual(self.put(self.booking, self.audited("confirmed", "barber"),
                                  self.people['barber'][1], True)[0], 200)
        self.assertEqual(self.put(self.booking, self.audited("cancelled", "client"),
                                  self.people['client'][1], True)[0], 200)

    def new_booking(self, barber_label="barber", shop="a", status="pending"):
        path = "bookings/" + uuid4().hex
        self.put(path, {"shopId": shop, "barberId": self.people[barber_label][0],
                        "userId": self.people['client'][0], "status": status}, "owner")
        return path

    def test_barbers_only_see_their_own_appointments(self):
        # A second barber in the same shop must not read or update the booking.
        code, account = call(self.auth_url, "POST", {"returnSecureToken": True})
        peer_uid, peer_token = account['localId'], account['idToken']
        self.put("users/" + peer_uid, {"role": "barber", "shopId": "a"}, "owner")
        path = self.new_booking()
        self.assertEqual(call(self.base + path, "GET", token=peer_token)[0], 403)
        self.assertEqual(self.put(path, {"status": "confirmed", "statusChangedBy": peer_uid},
                                  peer_token, True)[0], 403)
        # The shop admin still sees every booking of the shop.
        self.assertEqual(call(self.base + path, "GET", token=self.people['admin'][1])[0], 200)

    def test_cross_shop_staff_cannot_touch_bookings(self):
        path = self.new_booking(barber_label="other", shop="b")
        for label in ('admin', 'barber'):
            token = self.people[label][1]
            self.assertEqual(call(self.base + path, "GET", token=token)[0], 403)
            self.assertEqual(self.put(path, self.audited("cancelled", label), token, True)[0], 403)

    def test_anonymous_cannot_read_bookings(self):
        self.assertEqual(call(self.base + self.new_booking(), "GET")[0], 403)

    def test_terminal_bookings_cannot_be_revived(self):
        # Reviving would re-occupy a slot outside the reserveSlot guard.
        for status in ("cancelled", "completed", "noshow"):
            path = self.new_booking(status=status)
            for label in ('barber', 'admin'):
                self.assertEqual(self.put(path, self.audited("confirmed", label),
                                          self.people[label][1], True)[0], 403, (status, label))

    def test_staff_cannot_reschedule_or_reprice(self):
        path = self.new_booking()
        for field, value in (("barberId", self.people['other'][0]), ("startAt", "x"),
                             ("servicePrice", "0"), ("userId", "someone")):
            self.assertEqual(self.put(path, {field: value}, self.people['admin'][1], True)[0], 403, field)

    def test_client_can_only_cancel(self):
        path = self.new_booking()
        token = self.people['client'][1]
        self.assertEqual(self.put(path, self.audited("confirmed", "client"), token, True)[0], 403)
        self.assertEqual(self.put(path, {**self.audited("cancelled", "client"), "startAt": "x"},
                                  token, True)[0], 403)
        self.assertEqual(self.put(path, self.audited("cancelled", "client"), token, True)[0], 200)

    def test_server_only_collections_are_closed(self):
        for collection in ("booking_guards", "booking_requests", "booking_limits", "notifications",
                           "reputation"):
            path = collection + "/" + uuid4().hex
            self.put(path, {"shopId": "a"}, "owner")
            for label in ('client', 'barber', 'admin'):
                token = self.people[label][1]
                self.assertEqual(self.put(collection + "/" + uuid4().hex, {"shopId": "a"}, token)[0],
                                 403, (collection, label))
                if collection in ("booking_guards", "booking_requests", "booking_limits"):
                    self.assertEqual(call(self.base + path, "GET", token=token)[0], 403,
                                     (collection, label))

    def audited(self, status, label):
        return {"status": status, "statusChangedBy": self.people[label][0]}

    def test_status_changes_must_name_their_author(self):
        path = self.new_booking()
        barber_token = self.people['barber'][1]
        self.assertEqual(self.put(path, {"status": "confirmed"}, barber_token, True)[0], 403)
        self.assertEqual(self.put(path, {"status": "confirmed", "statusChangedBy": "someone-else"},
                                  barber_token, True)[0], 403)
        self.assertEqual(self.put(path, self.audited("noshow", "barber"), barber_token, True)[0], 200)
        # Non-status edits need no audit field.
        self.assertEqual(self.put(self.new_booking(), {"notes": "ok"}, barber_token, True)[0], 200)

    def test_schedule_blocks_are_server_written_but_deletable_by_owner(self):
        barber_uid, barber_token = self.people['barber']
        for label in ('barber', 'admin'):
            self.assertEqual(self.put("schedule_blocks/" + uuid4().hex,
                                      {"shopId": "a", "barberId": barber_uid},
                                      self.people[label][1])[0], 403, label)
        own = "schedule_blocks/" + uuid4().hex
        self.put(own, {"shopId": "a", "barberId": barber_uid}, "owner")
        self.assertEqual(self.put(own, {"endTime": "x"}, barber_token, True)[0], 403)
        self.assertEqual(call(self.base + own, "GET", token=barber_token)[0], 200)
        self.assertEqual(call(self.base + own, "DELETE", token=self.people['other'][1])[0], 403)
        self.assertEqual(call(self.base + own, "DELETE", token=barber_token)[0], 200)

    def test_reputation_is_server_only(self):
        for collection in ("reputation", "reputation_events"):
            path = collection + "/" + uuid4().hex
            self.put(path, {"shopId": "a", "noShowCount": "1"}, "owner")
            admin_token = self.people['admin'][1]
            self.assertEqual(self.put(path, {"noShowCount": "0"}, admin_token, True)[0], 403)
            self.assertEqual(call(self.base + path, "DELETE", token=admin_token)[0], 403)
        self.assertEqual(call(self.base + "reputation_events/" + uuid4().hex, "GET",
                              token=self.people['admin'][1])[0], 403)

    def test_public_directory(self):
        path = 'barber_directory/' + uuid4().hex
        self.put(path, {"shopId": "a", "name": "Barber"}, "owner")
        self.assertEqual(call(self.base + path, "GET")[0], 200)
        self.assertEqual(self.put(path, {"email": "private"}, self.people["admin"][1], True)[0], 403)


if __name__ == "__main__":
    unittest.main()
