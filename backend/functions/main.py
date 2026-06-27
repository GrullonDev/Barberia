"""Cloud Functions (Python v2) del backend de Barbería.

Funciones disponibles:
    - reserveSlot(data, context)
        Callable. Crea una reserva atómicamente (transacción Firestore).
        Valida contra bookings existentes, schedule_blocks, working_hours,
        reputación del teléfono y existencia del servicio.
        Usa el Admin SDK, bypass de Firestore rules — las reglas bloquean
        la creación directa por cliente, así que esta es la única puerta.

    - getAvailability(data, context)
        Callable read-only. Dada (barberId, dateIsoUtc, serviceId) devuelve
        la lista de horarios libres (ISO UTC) que el cliente puede pintar
        en el calendario.

Convenciones:
    - Todas las fechas se transportan en ISO 8601 UTC (sufijo "Z" o "+00:00").
    - El cliente manda `customerPhone` crudo; la función normaliza a E.164.
    - El booking se escribe con TODOS los campos v2 (startAt, endAt,
      serviceDurationMinutes, servicePrice, phoneNormalized, createdAt,
      updatedAt, status='pending').
"""

from __future__ import annotations

import os
import re
import secrets
import string
from datetime import datetime, timedelta, timezone
from typing import Any

import firebase_admin
from firebase_admin import auth as fb_auth
from firebase_admin import firestore
from firebase_functions import https_fn, options
from google.cloud.firestore_v1.base_query import FieldFilter
from google.cloud.firestore_v1.transaction import Transaction

from slot_engine import (
    OCCUPYING_STATUSES,
    TimeRange,
    blocks_to_ranges,
    bookings_to_ranges,
    generate_candidates,
    has_conflict,
    is_within_working_hours,
)

# Región: us-central1 es default de Firebase Functions. Para un negocio
# guatemalteco, us-east1 o southamerica-east1 serían marginalmente más
# rápidos; se puede cambiar en un segundo deploy.
options.set_global_options(region="us-central1", max_instances=10)

firebase_admin.initialize_app()


# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------


_PHONE_DIGITS = re.compile(r"\D+")


def normalize_phone(raw: str | None) -> str | None:
    """Replica el comportamiento de Dart `phone_normalizer.dart`.

    Acepta entradas como '+502 1234 5678', '12345678', '50212345678'
    y devuelve '+50212345678' si hay 8 dígitos locales.
    """
    if not raw:
        return None
    digits = _PHONE_DIGITS.sub("", raw)
    if digits.startswith("502") and len(digits) == 11:
        return "+" + digits
    if len(digits) == 8:
        return "+502" + digits
    if digits.startswith("00"):
        digits = digits[2:]
        return "+" + digits if len(digits) >= 10 else None
    if len(digits) >= 10:
        return "+" + digits
    return None


def _parse_iso_utc(value: str) -> datetime:
    """Parsea ISO 8601; acepta sufijo Z."""
    if value.endswith("Z"):
        value = value[:-1] + "+00:00"
    dt = datetime.fromisoformat(value)
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def _require(data: dict[str, Any], keys: list[str]) -> None:
    missing = [k for k in keys if data.get(k) in (None, "")]
    if missing:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message=f"Campos requeridos: {', '.join(missing)}",
        )


def _load_barber_working_hours(
    db, barber_id: str, iso_weekday: int
) -> list[int] | None:
    """Lee workingHours del barbero para el día de la semana dado.

    `iso_weekday` sigue la convención ISO/Dart (1=Mon .. 7=Sun) para
    coincidir con el modelo Barber de Flutter y con el persistido en
    Firestore (keys string "1".."7"). El caller se encarga de convertir
    desde `datetime.weekday()` (0..6) haciendo `+1`.

    Estructura esperada: {"1": [9, 19], "2": [9, 19], ..., "7": null}

    El perfil de barbero vive en `users/{uid}` (no hay colección `barbers`
    separada — ver inviteBarber).
    """
    snap = db.collection("users").document(barber_id).get()
    if not snap.exists:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.NOT_FOUND,
            message=f"Barbero {barber_id} no existe.",
        )
    data = snap.to_dict() or {}
    if not data.get("isAvailable", True):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
            message="Barbero no disponible.",
        )
    wh = (data.get("workingHours") or {}).get(str(iso_weekday))
    return wh if isinstance(wh, list) else None


def _load_service(db, service_id: str) -> dict[str, Any]:
    snap = db.collection("services").document(service_id).get()
    if not snap.exists:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.NOT_FOUND,
            message=f"Servicio {service_id} no existe.",
        )
    data = snap.to_dict() or {}
    if not data.get("isActive", True):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
            message="Servicio inactivo.",
        )
    return data


def _load_config(db) -> dict[str, Any]:
    snap = db.collection("config").document("barberia").get()
    return snap.to_dict() or {
        "slotMinutes": 30,
        "maxNoShows": 3,
        "timezoneOffsetHours": -6,
        "name": "La Barbería",
    }


def _reputation_blocked(db, phone_normalized: str | None, max_no_shows: int) -> bool:
    if not phone_normalized:
        return False
    snap = db.collection("reputation").document(phone_normalized).get()
    if not snap.exists:
        return False
    data = snap.to_dict() or {}
    if data.get("blocked") is True:
        return True
    return int(data.get("noShowCount") or 0) >= max_no_shows


# -----------------------------------------------------------------------------
# reserveSlot
# -----------------------------------------------------------------------------


@https_fn.on_call()
def reserveSlot(req: https_fn.CallableRequest) -> dict[str, Any]:
    """Crea atómicamente un booking v2 validando contra colisiones.

    Input:
        barberId: str
        serviceId: str
        startAtIso: str  (ISO 8601 UTC)
        customerName: str
        customerPhone: str | None
        customerEmail: str | None
        notes: str | None
        userId: str | None   (si es None, se usa req.auth.uid o 'guest')

    Output:
        { bookingId: str, endAtIso: str }

    Errores:
        invalid-argument   → payload incompleto o mal formado
        not-found          → barber o service no existen
        failed-precondition→ barber no disponible, servicio inactivo, fuera
                             de horario, o cliente bloqueado por reputación
        already-exists     → colisión con otro booking en ese slot
    """
    data = req.data or {}
    _require(
        data,
        [
            "barberId",
            "serviceId",
            "startAtIso",
            "customerName",
        ],
    )

    barber_id: str = data["barberId"]
    service_id: str = data["serviceId"]
    start_at: datetime = _parse_iso_utc(data["startAtIso"])
    customer_name: str = data["customerName"]
    customer_phone: str | None = data.get("customerPhone")
    customer_email: str | None = data.get("customerEmail")
    notes: str | None = data.get("notes")
    user_id: str = data.get("userId") or (
        req.auth.uid if req.auth else "guest"
    )

    db = firestore.client()

    # Lecturas previas a la transacción (seguras de cachear).
    service = _load_service(db, service_id)
    duration = int(service.get("durationMinutes") or 30)
    price = float(service.get("priceCents", 0)) / 100 if service.get(
        "priceCents"
    ) is not None else float(service.get("price") or 0)
    end_at = start_at + timedelta(minutes=duration)

    config = _load_config(db)
    tz_offset = int(config.get("timezoneOffsetHours", -6))

    # Python datetime.weekday() devuelve 0..6 (lunes=0); convertimos a ISO
    # (1..7) para coincidir con Dart/Barber model.
    wh = _load_barber_working_hours(db, barber_id, start_at.weekday() + 1)
    candidate = TimeRange(start=start_at, end=end_at)
    if not is_within_working_hours(candidate, wh, tz_offset):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
            message="Horario fuera del turno del barbero.",
        )

    phone_normalized = normalize_phone(customer_phone)
    if _reputation_blocked(
        db, phone_normalized, int(config.get("maxNoShows", 3))
    ):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
            message="Cliente bloqueado por historial de no-shows.",
        )

    # Ventana de consulta de conflictos: +/- duración del día.
    day_start = start_at.replace(hour=0, minute=0, second=0, microsecond=0)
    day_end = day_start + timedelta(days=1)

    barber_snap = db.collection("users").document(barber_id).get()
    barber_name = (barber_snap.to_dict() or {}).get("name", "Barbero") if barber_snap.exists else "Barbero"

    booking_ref = db.collection("bookings").document()
    notification_ref = db.collection("notifications").document()
    transaction = db.transaction()

    @firestore.transactional
    def _txn(tx: Transaction) -> None:
        # Releer bookings activos del barbero para este día.
        overlapping_q = (
            db.collection("bookings")
            .where(filter=FieldFilter("barberId", "==", barber_id))
            .where(filter=FieldFilter("startAt", ">=", day_start))
            .where(filter=FieldFilter("startAt", "<", day_end))
        )
        booking_docs = [d.to_dict() for d in overlapping_q.stream(transaction=tx)]

        blocks_q = (
            db.collection("schedule_blocks")
            .where(filter=FieldFilter("barberId", "==", barber_id))
            .where(filter=FieldFilter("startTime", ">=", day_start))
            .where(filter=FieldFilter("startTime", "<", day_end))
        )
        block_docs = [d.to_dict() for d in blocks_q.stream(transaction=tx)]

        if has_conflict(
            candidate,
            bookings_to_ranges(booking_docs),
            blocks_to_ranges(block_docs),
        ):
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.ALREADY_EXISTS,
                message="Ese horario ya fue reservado. Intenta con otro.",
            )

        tx.set(
            booking_ref,
            {
                "userId": user_id,
                "barberId": barber_id,
                "serviceId": service_id,
                "serviceName": service.get("name", ""),
                "serviceDurationMinutes": duration,
                "servicePrice": price,
                "startAt": start_at,
                "endAt": end_at,
                # Retro-compat: campos viejos que Flutter todavía lee.
                "date": start_at,
                "status": "pending",
                "customerName": customer_name,
                "customerEmail": customer_email,
                "customerPhone": customer_phone,
                "phoneNormalized": phone_normalized,
                "notes": notes,
                "cancelReason": None,
                "confirmationSentAt": None,
                "confirmedAt": None,
                "createdAt": firestore.SERVER_TIMESTAMP,
                "updatedAt": firestore.SERVER_TIMESTAMP,
            },
        )

        # La notificación se crea server-side, en la misma transacción que el
        # booking. El cliente ya no escribe en `notifications` (ver
        # firestore.rules: create está denegado para el SDK de cliente).
        tx.set(
            notification_ref,
            {
                "title": "Nueva Cita Solicitada",
                "message": (
                    f"{customer_name} ha agendado {service.get('name', '')} "
                    f"con {barber_name}."
                ),
                "barberId": barber_id,
                "barberName": barber_name,
                "clientName": customer_name,
                "service": service.get("name", ""),
                "bookingId": booking_ref.id,
                "createdAt": firestore.SERVER_TIMESTAMP,
                "read": False,
            },
        )

    _txn(transaction)

    return {
        "bookingId": booking_ref.id,
        "endAtIso": end_at.isoformat().replace("+00:00", "Z"),
    }


# -----------------------------------------------------------------------------
# getAvailability
# -----------------------------------------------------------------------------


@https_fn.on_call()
def getAvailability(req: https_fn.CallableRequest) -> dict[str, Any]:
    """Lista slots libres de un barbero para una fecha y servicio.

    Input:
        barberId: str
        dateIso: str         (ISO 8601 — se usa solo la parte de fecha)
        serviceId: str

    Output:
        { slots: [startIsoUtc, ...], slotMinutes: int, durationMinutes: int }
    """
    data = req.data or {}
    _require(data, ["barberId", "dateIso", "serviceId"])

    barber_id: str = data["barberId"]
    date_input: datetime = _parse_iso_utc(data["dateIso"])
    service_id: str = data["serviceId"]

    db = firestore.client()
    service = _load_service(db, service_id)
    duration = int(service.get("durationMinutes") or 30)
    config = _load_config(db)
    slot_minutes = int(config.get("slotMinutes") or 30)
    tz_offset = int(config.get("timezoneOffsetHours", -6))

    wh = _load_barber_working_hours(db, barber_id, date_input.weekday() + 1)

    candidates = generate_candidates(
        date=date_input,
        duration_minutes=duration,
        slot_minutes=slot_minutes,
        working_hours_for_weekday=wh,
        business_tz_offset_hours=tz_offset,
    )

    day_start = date_input.replace(hour=0, minute=0, second=0, microsecond=0)
    day_end = day_start + timedelta(days=1)

    bookings_q = (
        db.collection("bookings")
        .where(filter=FieldFilter("barberId", "==", barber_id))
        .where(filter=FieldFilter("startAt", ">=", day_start))
        .where(filter=FieldFilter("startAt", "<", day_end))
    )
    active_bookings = [
        d.to_dict()
        for d in bookings_q.stream()
        if (d.to_dict() or {}).get("status") in OCCUPYING_STATUSES
    ]
    blocks_q = (
        db.collection("schedule_blocks")
        .where(filter=FieldFilter("barberId", "==", barber_id))
        .where(filter=FieldFilter("startTime", ">=", day_start))
        .where(filter=FieldFilter("startTime", "<", day_end))
    )
    blocks = [d.to_dict() for d in blocks_q.stream()]

    booking_ranges = bookings_to_ranges(active_bookings)
    block_ranges = blocks_to_ranges(blocks)

    free_slots: list[str] = []
    for c in candidates:
        if has_conflict(c, booking_ranges, block_ranges):
            continue
        free_slots.append(c.start.isoformat().replace("+00:00", "Z"))

    return {
        "slots": free_slots,
        "slotMinutes": slot_minutes,
        "durationMinutes": duration,
    }


# -----------------------------------------------------------------------------
# Helpers de invitación
# -----------------------------------------------------------------------------


def _generate_temp_password(length: int = 12) -> str:
    """Genera una contraseña temporal segura con al menos una mayúscula,
    minúscula, dígito y símbolo."""
    alphabet = string.ascii_letters + string.digits + "!@#$%"
    guaranteed = [
        secrets.choice(string.ascii_uppercase),
        secrets.choice(string.ascii_lowercase),
        secrets.choice(string.digits),
        secrets.choice("!@#$%"),
    ]
    rest = [secrets.choice(alphabet) for _ in range(length - 4)]
    chars = guaranteed + rest
    secrets.SystemRandom().shuffle(chars)
    return "".join(chars)


def _send_invitation_email(
    to_email: str,
    barber_name: str,
    shop_name: str,
    temp_password: str,
) -> None:
    """Envía correo de bienvenida con credenciales vía SendGrid.

    Variables de entorno requeridas:
        SENDGRID_API_KEY    — clave API de SendGrid
        SENDGRID_FROM_EMAIL — dirección verificada del remitente
    Opcional:
        SENDGRID_FROM_NAME  (default: shop_name)
    """
    import sendgrid as sg_module
    from sendgrid.helpers.mail import Mail

    api_key = os.environ.get("SENDGRID_API_KEY", "")
    from_email = os.environ.get("SENDGRID_FROM_EMAIL", "")
    from_name = os.environ.get("SENDGRID_FROM_NAME", shop_name)

    if not api_key or not from_email:
        raise ValueError(
            "SENDGRID_API_KEY y SENDGRID_FROM_EMAIL son requeridos en las "
            "variables de entorno."
        )

    plain = (
        f"Hola {barber_name},\n\n"
        f"¡Felicidades! Has sido contratado como barbero en {shop_name}.\n\n"
        f"Estas son tus credenciales de acceso:\n"
        f"  Correo:      {to_email}\n"
        f"  Contraseña:  {temp_password}\n\n"
        f"Ingresa a la aplicación con estos datos y completa tu perfil.\n"
        f"Te recomendamos cambiar tu contraseña después del primer inicio de sesión.\n\n"
        f"Si no esperabas esta invitación, puedes ignorar este correo."
    )

    html = f"""<!DOCTYPE html>
<html lang="es">
<body style="margin:0;padding:0;background:#f4f4f5;font-family:sans-serif">
<table width="100%" cellpadding="0" cellspacing="0">
  <tr><td align="center" style="padding:40px 16px">
    <table width="480" cellpadding="0" cellspacing="0"
           style="background:#fff;border-radius:12px;overflow:hidden;
                  box-shadow:0 2px 8px rgba(0,0,0,.08)">
      <!-- header -->
      <tr><td style="background:#22c55e;padding:28px 32px">
        <h1 style="margin:0;color:#fff;font-size:22px;font-weight:700">
          ¡Bienvenido a {shop_name}!
        </h1>
      </td></tr>
      <!-- body -->
      <tr><td style="padding:32px">
        <p style="margin:0 0 16px;color:#111;font-size:15px">
          Hola <strong>{barber_name}</strong>,
        </p>
        <p style="margin:0 0 24px;color:#374151;font-size:15px;line-height:1.6">
          ¡Felicidades! Has sido <strong>contratado como barbero</strong>
          en <strong>{shop_name}</strong>. A continuación encontrarás tus
          credenciales para acceder a la aplicación:
        </p>
        <!-- credentials box -->
        <table width="100%" cellpadding="0" cellspacing="0"
               style="background:#f0fdf4;border:1px solid #bbf7d0;
                      border-radius:8px;margin-bottom:24px">
          <tr><td style="padding:20px 24px">
            <p style="margin:0 0 8px;color:#166534;font-size:13px;
                      font-weight:600;text-transform:uppercase;
                      letter-spacing:.05em">
              Tus credenciales
            </p>
            <p style="margin:0 0 6px;color:#111;font-size:15px">
              <span style="color:#6b7280">Correo:</span>&nbsp;
              <strong>{to_email}</strong>
            </p>
            <p style="margin:0;color:#111;font-size:15px">
              <span style="color:#6b7280">Contraseña:</span>&nbsp;
              <strong style="font-family:monospace;font-size:16px;
                             letter-spacing:.08em">{temp_password}</strong>
            </p>
          </td></tr>
        </table>
        <p style="margin:0 0 8px;color:#374151;font-size:14px;line-height:1.6">
          Ingresa a la app con estos datos y completa tu perfil.
          <br>
          <span style="color:#6b7280">
            Por seguridad, cambia tu contraseña después del primer inicio de sesión.
          </span>
        </p>
      </td></tr>
      <!-- footer -->
      <tr><td style="padding:16px 32px;background:#f9fafb;border-top:1px solid #e5e7eb">
        <p style="margin:0;color:#9ca3af;font-size:12px">
          Si no esperabas esta invitación, ignora este correo.
        </p>
      </td></tr>
    </table>
  </td></tr>
</table>
</body>
</html>"""

    message = Mail(
        from_email=(from_email, from_name),
        to_emails=to_email,
        subject=f"¡Bienvenido a {shop_name} — Tus credenciales de acceso!",
        plain_text_content=plain,
        html_content=html,
    )

    client = sg_module.SendGridAPIClient(api_key)
    response = client.send(message)
    if response.status_code >= 400:
        raise RuntimeError(
            f"SendGrid error {response.status_code}: {response.body}"
        )


# -----------------------------------------------------------------------------
# inviteBarber
# -----------------------------------------------------------------------------


@https_fn.on_call()
def inviteBarber(req: https_fn.CallableRequest) -> dict[str, Any]:
    """Invita a un barbero por correo electrónico.

    Crea una cuenta de Firebase Auth para el barbero, genera un enlace para
    que establezca su contraseña y envía un correo de invitación. También
    crea el documento `users/{uid}` en Firestore con role: "barber" y los
    campos de perfil de barbero (specialty, isAvailable, workingHours).

    Input:
        name: str
        email: str
        specialty: str | None

    Output:
        { barberId: str }

    Errores:
        unauthenticated    → el llamador no tiene sesión
        permission-denied  → el llamador no es admin
        invalid-argument   → name o email vacíos
        already-exists     → ya existe una cuenta con ese email
    """
    if req.auth is None:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
            message="Se requiere autenticación.",
        )

    db = firestore.client()

    caller = db.collection("users").document(req.auth.uid).get()
    if not caller.exists or (caller.to_dict() or {}).get("role") != "admin":
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
            message="Solo administradores pueden invitar barberos.",
        )

    data = req.data or {}
    name = (data.get("name") or "").strip()
    email = (data.get("email") or "").strip().lower()
    specialty = (data.get("specialty") or "").strip() or None

    if not name or not email:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="Nombre y email son requeridos.",
        )

    # Generar contraseña temporal con la que el barbero hará su primer login.
    temp_password = _generate_temp_password()

    # Crear cuenta de Firebase Auth con la contraseña generada.
    try:
        user_record = fb_auth.create_user(
            email=email,
            password=temp_password,
            display_name=name,
            disabled=False,
        )
    except fb_auth.EmailAlreadyExistsError:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.ALREADY_EXISTS,
            message="Ya existe una cuenta con ese correo electrónico.",
        )
    except Exception as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Error creando cuenta: {e}",
        )

    barber_id = user_record.uid

    # Nombre del negocio para el cuerpo del correo.
    config_snap = db.collection("config").document("barberia").get()
    shop_name = (
        (config_snap.to_dict() or {}).get("name", "La Barbería")
        if config_snap.exists
        else "La Barbería"
    )

    # Documento único users/{uid}: identidad + perfil de barbero.
    db.collection("users").document(barber_id).set(
        {
            "id": barber_id,
            "name": name,
            "email": email,
            "role": "barber",
            "phone": None,
            "phoneNormalized": None,
            "photoUrl": None,
            "isAnonymous": False,
            "inviteStatus": "pending",
            "createdAt": firestore.SERVER_TIMESTAMP,
            "specialty": specialty,
            "isAvailable": True,
            # Horario por defecto: lunes–sábado 9–19, domingo cerrado.
            "workingHours": {str(d): [9, 19] for d in range(1, 7)},
        }
    )

    # Enviar correo con credenciales vía SendGrid.
    # Si las variables de entorno no están configuradas se imprime la
    # contraseña en los logs para que el admin la entregue manualmente.
    try:
        _send_invitation_email(email, name, shop_name, temp_password)
    except Exception as e:
        print(f"[inviteBarber] Advertencia: no se pudo enviar correo a {email}: {e}")
        print(f"[inviteBarber] Contraseña temporal para {email}: {temp_password}")

    return {"barberId": barber_id}


# -----------------------------------------------------------------------------
# removeBarber
# -----------------------------------------------------------------------------


@https_fn.on_call()
def removeBarber(req: https_fn.CallableRequest) -> dict[str, Any]:
    """Elimina un barbero: borra sus documentos Firestore y su cuenta Auth.

    Input:
        barberId: str

    Output:
        { success: bool }

    Errores:
        unauthenticated   → el llamador no tiene sesión
        permission-denied → el llamador no es admin
        invalid-argument  → barberId vacío
    """
    if req.auth is None:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
            message="Se requiere autenticación.",
        )

    db = firestore.client()

    caller = db.collection("users").document(req.auth.uid).get()
    if not caller.exists or (caller.to_dict() or {}).get("role") != "admin":
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
            message="Solo administradores pueden eliminar barberos.",
        )

    barber_id = (req.data or {}).get("barberId", "").strip()
    if not barber_id:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="barberId es requerido.",
        )

    # Borrar documento Firestore.
    db.collection("users").document(barber_id).delete()

    # Eliminar cuenta Firebase Auth (puede no existir para barberos creados
    # manualmente antes de este flujo).
    try:
        fb_auth.delete_user(barber_id)
    except fb_auth.UserNotFoundError:
        pass
    except Exception as e:
        print(f"[removeBarber] Advertencia al eliminar Auth user {barber_id}: {e}")

    return {"success": True}
