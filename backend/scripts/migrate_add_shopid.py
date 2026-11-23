"""Migración one-shot: añade `shopId` a todos los docs existentes.

Contexto: hasta ahora el negocio vivía implícito en `config/barberia`
(un solo doc global). Para soportar multi-tenant, cada doc operativo
necesita un `shopId` explícito. En vez de inventar un ID nuevo para el
tenant actual (y tener que reescribir/renombrar todo), este script
reutiliza "barberia" como shopId del tenant existente — así el 100% de
los datos actuales queda "correcto" apenas se les estampa el campo, sin
downtime ni reindexado.

Qué hace:
    - Crea `shops/barberia` a partir de `config/barberia`.
    - Estampa `shopId="barberia"` en cada doc de users (solo role
      admin/barber — los clients no llevan shopId, ver diseño en el
      chat), bookings, services, schedule_blocks, walkins, reputation,
      clients, notifications, admin_notifications.

Es idempotente: cualquier doc que ya tenga `shopId` se salta, así que
correrlo dos veces (o interrumpirlo a la mitad y volver a correrlo) es
seguro — no hay estado a medio migrar que rompa algo.

Notas sobre límites de Firestore (relevante si la base crece):
    - Un WriteBatch soporta como máximo 500 mutaciones; usamos 400 de
      margen. Si algún día una sola colección supera varios cientos de
      miles de docs, este script seguiría funcionando (solo tardaría
      más), porque itera el generador de `.stream()` directamente en
      vez de materializarlo con `list(...)` — la memoria usada es
      constante, no crece con el tamaño de la colección.
    - Firestore recomienda no saltar de golpe a >500 escrituras/segundo
      sostenidas contra una colección nueva (ramp-up gradual). Para el
      volumen de un backfill de un solo tenant esto no aplica, pero si
      se reutiliza este script más adelante para una colección muy
      grande, considera bajar BATCH_SIZE y/o insertar una pausa corta
      entre `batch.commit()` sucesivos.
    - No hay límite de tiempo de ejecución (es un script local, no una
      Cloud Function) — para colecciones enormes, el cuello de botella
      real sería la latencia de red, no un timeout.

Uso:
    cd backend/scripts
    pip install firebase-admin   # si no está ya instalado
    GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json \
        python migrate_add_shopid.py [--dry-run]
"""

from __future__ import annotations

import argparse

import firebase_admin
from firebase_admin import firestore

DEFAULT_SHOP_ID = "barberia"
BATCH_SIZE = 400  # margen bajo el límite de 500 mutaciones/batch de Firestore

SCOPED_COLLECTIONS = [
    "bookings",
    "services",
    "schedule_blocks",
    "walkins",
    "reputation",
    "clients",
    "notifications",
    "admin_notifications",
]


def _migrate_shop_doc(db, dry_run: bool) -> None:
    config_snap = db.collection("config").document("barberia").get()
    config_data = config_snap.to_dict() or {}
    if not dry_run:
        db.collection("shops").document(DEFAULT_SHOP_ID).set(
            {**config_data, "status": "active"}, merge=True
        )
    tag = "dry-run" if dry_run else "written"
    print(f"[shops] shops/{DEFAULT_SHOP_ID} <- config/barberia ({tag})")


def _migrate_staff_users(db, dry_run: bool) -> None:
    query = db.collection("users").where(
        filter=firestore.FieldFilter("role", "in", ["admin", "barber"])
    )
    count = 0
    for doc in query.stream():
        if doc.to_dict().get("shopId"):
            continue
        count += 1
        if not dry_run:
            doc.reference.update({"shopId": DEFAULT_SHOP_ID})
    tag = "would be stamped" if dry_run else "stamped"
    print(f"[users] {count} staff docs {tag}")


def _migrate_collection(db, coll_name: str, dry_run: bool) -> None:
    batch = db.batch()
    ops = 0
    stamped = 0

    # Iteramos el generador de .stream() directamente (no list(...)):
    # memoria constante sin importar cuántos docs tenga la colección.
    for doc in db.collection(coll_name).stream():
        if doc.to_dict().get("shopId"):
            continue
        stamped += 1
        ops += 1
        if not dry_run:
            batch.update(doc.reference, {"shopId": DEFAULT_SHOP_ID})
        if ops == BATCH_SIZE:
            if not dry_run:
                batch.commit()
            batch = db.batch()
            ops = 0

    if ops and not dry_run:
        batch.commit()

    tag = "would be stamped" if dry_run else "stamped"
    print(f"[{coll_name}] {stamped} docs {tag}")


def main(dry_run: bool) -> None:
    firebase_admin.initialize_app()
    db = firestore.client()

    _migrate_shop_doc(db, dry_run)
    _migrate_staff_users(db, dry_run)
    for coll_name in SCOPED_COLLECTIONS:
        _migrate_collection(db, coll_name, dry_run)

    if dry_run:
        print("\nDry-run completo. Nada fue escrito. Corre sin --dry-run para aplicar.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--dry-run", action="store_true", help="Imprime lo que haría sin escribir nada."
    )
    main(parser.parse_args().dry_run)
