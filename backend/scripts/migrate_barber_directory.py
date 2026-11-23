"""Migración one-shot: backfill de `barber_directory` para barberos existentes.

Contexto: `barber_directory` es la vista pública denormalizada que lee la app
de reservas (clientes sin sesión de staff no pueden leer `users` bajo las
reglas multi-tenant actuales — ver firestore.rules). Solo `inviteBarber` y
`removeBarber` (backend/functions/main.py) escriben ahí, así que cualquier
barbero creado ANTES de que existiera esa colección no tiene doc en
`barber_directory` y no aparece en el picker de la app de reservas hasta
correr este backfill.

Qué hace:
    - Por cada `users/{uid}` con role == "barber", escribe (merge) el doc
      equivalente en `barber_directory/{uid}` con los mismos campos seguros
      que escribe `inviteBarber`: name, photoUrl, specialty, isAvailable,
      shopId.
    - Salta barberos sin `shopId` (todavía no corrieron migrate_add_shopid.py)
      y avisa, porque `barber_directory` sin shopId rompería el filtrado por
      tenant en la app de reservas.

Es idempotente: usa `set(..., merge=True)`, así que correrlo varias veces
solo re-sincroniza los campos seguros — no hay estado a medio migrar que
rompa algo.

Uso:
    cd backend/scripts
    pip install firebase-admin   # si no está ya instalado
    GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json \
        python migrate_barber_directory.py [--dry-run]
"""

from __future__ import annotations

import argparse

import firebase_admin
from firebase_admin import firestore


def _migrate_barber_directory(db, dry_run: bool) -> None:
    query = db.collection("users").where(
        filter=firestore.FieldFilter("role", "==", "barber")
    )

    stamped = 0
    skipped_no_shop = 0

    for doc in query.stream():
        data = doc.to_dict() or {}
        shop_id = data.get("shopId")
        if not shop_id:
            skipped_no_shop += 1
            print(
                f"[barber_directory] SALTADO {doc.id}: sin shopId "
                "(correr migrate_add_shopid.py primero)"
            )
            continue

        entry = {
            "name": data.get("name"),
            "photoUrl": data.get("photoUrl"),
            "specialty": data.get("specialty"),
            "isAvailable": data.get("isAvailable", True),
            "shopId": shop_id,
        }

        stamped += 1
        if not dry_run:
            db.collection("barber_directory").document(doc.id).set(
                entry, merge=True
            )

    tag = "would be written" if dry_run else "written"
    print(f"[barber_directory] {stamped} barber docs {tag}")
    if skipped_no_shop:
        print(f"[barber_directory] {skipped_no_shop} docs skipped (no shopId)")


def main(dry_run: bool) -> None:
    firebase_admin.initialize_app()
    db = firestore.client()

    _migrate_barber_directory(db, dry_run)

    if dry_run:
        print("\nDry-run completo. Nada fue escrito. Corre sin --dry-run para aplicar.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--dry-run", action="store_true", help="Imprime lo que haría sin escribir nada."
    )
    main(parser.parse_args().dry_run)
