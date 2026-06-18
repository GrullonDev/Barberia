"""Migración one-shot: fusiona `barbers/{id}` dentro de `users/{id}`.

Contexto: el modelo viejo tenía dos colecciones (`users` con el rol, y
`barbers` como catálogo de perfil). El modelo nuevo tiene una sola
colección `users`, con los campos de perfil de barbero (specialty,
isAvailable, workingHours, bio, title, specialties, photoUrl) viviendo
directamente en el doc del usuario. Ver `backend/functions/main.py`
(inviteBarber, removeBarber, _load_barber_working_hours) y
`firestore.rules` para el código que ya asume el modelo nuevo.

Por cada doc en `barbers/{id}`:
    - Si existe `users/{id}`: se le mergean los campos de perfil de
      barbero (sin pisar campos ya presentes salvo que falten), y se
      fuerza `role = "barber"` si no estaba seteado.
    - Si NO existe `users/{id}`: se verifica si existe una cuenta de
      Firebase Auth con ese uid. Si existe, se crea el doc `users/{id}`
      con los datos disponibles (email del registro de Auth, o
      `inviteEmail` del doc de barbero como respaldo) y role: "barber".
      Si NO existe cuenta de Auth, se reporta como huérfano y se
      SALTA — no se puede loguear de todas formas sin una cuenta, así
      que crear el doc no resuelve nada por sí solo.
    - Al terminar de procesar un barbero (mergeado o creado), se borra
      `barbers/{id}`.

Es idempotente: si `barbers` ya está vacía, no hace nada.

Uso:
    cd backend/scripts
    pip install firebase-admin   # si no está ya instalado
    GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json \\
        python migrate_barbers_to_users.py [--dry-run]

`--dry-run` imprime lo que haría sin escribir ni borrar nada.
"""

from __future__ import annotations

import argparse
import sys

import firebase_admin
from firebase_admin import auth as fb_auth
from firebase_admin import firestore

# Campos de perfil de barbero que se fusionan dentro de users/{id}.
_BARBER_PROFILE_FIELDS = (
    "specialty",
    "specialties",
    "isAvailable",
    "workingHours",
    "bio",
    "title",
    "photoUrl",
)


def migrate(dry_run: bool) -> None:
    firebase_admin.initialize_app()
    db = firestore.client()

    barbers = db.collection("barbers").stream()

    merged = 0
    created = 0
    orphaned = 0
    errors = 0

    for barber_doc in barbers:
        barber_id = barber_doc.id
        barber_data = barber_doc.to_dict() or {}

        try:
            user_ref = db.collection("users").document(barber_id)
            user_snap = user_ref.get()

            profile_update = {
                field: barber_data[field]
                for field in _BARBER_PROFILE_FIELDS
                if field in barber_data
            }
            # El inviteStatus del doc de barbero es el que de verdad se
            # actualiza al aceptar la invitación (ver regla vieja de
            # firestore.rules); preferirlo sobre el de users si ambos existen.
            if "inviteStatus" in barber_data:
                profile_update["inviteStatus"] = barber_data["inviteStatus"]

            if user_snap.exists:
                user_data = user_snap.to_dict() or {}
                if not user_data.get("role"):
                    profile_update["role"] = "barber"
                print(
                    f"[merge] users/{barber_id} <- barbers/{barber_id} "
                    f"({sorted(profile_update.keys())})"
                )
                if not dry_run:
                    user_ref.set(profile_update, merge=True)
                merged += 1
            else:
                try:
                    auth_user = fb_auth.get_user(barber_id)
                except fb_auth.UserNotFoundError:
                    auth_user = None

                if auth_user is None:
                    print(
                        f"[skip] barbers/{barber_id} no tiene cuenta de Auth "
                        f"ni users/{barber_id} — huérfano, requiere decisión manual."
                    )
                    orphaned += 1
                    continue

                new_user_data = {
                    "id": barber_id,
                    "name": barber_data.get("name") or auth_user.display_name or "",
                    "email": auth_user.email or barber_data.get("inviteEmail"),
                    "role": "barber",
                    "phone": None,
                    "phoneNormalized": None,
                    "isAnonymous": False,
                    "createdAt": firestore.SERVER_TIMESTAMP,
                    **profile_update,
                }
                print(f"[create] users/{barber_id} <- barbers/{barber_id} (sin users previo)")
                if not dry_run:
                    user_ref.set(new_user_data)
                created += 1

            if not dry_run:
                db.collection("barbers").document(barber_id).delete()
        except Exception as e:  # noqa: BLE001
            errors += 1
            print(f"[error] {barber_id}: {e}", file=sys.stderr)

    print("=" * 50)
    print("Migración barbers -> users completada" + (" (dry-run)" if dry_run else ""))
    print(f"  Mergeados: {merged}")
    print(f"  Creados:   {created}")
    print(f"  Huérfanos (sin cuenta Auth, sin tocar): {orphaned}")
    print(f"  Errores:   {errors}")
    print("=" * 50)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    migrate(dry_run=args.dry_run)
