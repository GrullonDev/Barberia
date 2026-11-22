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

    - resetBarberPassword(data, context)
        Callable. Admin-only. Genera una contraseña temporal nueva para un
        barbero de su mismo shop y fuerza `mustChangePassword` — es el
        mecanismo real detrás del enlace "Forgot?" del login de staff.

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
from firebase_functions import firestore_fn, https_fn, options
from barber_directory import reconcile
from google.cloud.firestore_v1.base_query import FieldFilter
from google.cloud.firestore_v1.transaction import Transaction

from booking_api import availability, reserve

# Región: us-central1 es default de Firebase Functions. Para un negocio
# guatemalteco, us-east1 o southamerica-east1 serían marginalmente más
# rápidos; se puede cambiar en un segundo deploy.
options.set_global_options(region="us-central1", max_instances=10)

firebase_admin.initialize_app()


# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------


@https_fn.on_call()
def reserveSlot(req: https_fn.CallableRequest) -> dict[str, Any]:
    return reserve(req)


@https_fn.on_call()
def getAvailability(req: https_fn.CallableRequest) -> dict[str, Any]:
    return availability(req)


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
    caller_data = caller.to_dict() or {}
    if not caller.exists or caller_data.get("role") != "admin" or not caller_data.get("shopId"):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
            message="Solo administradores pueden invitar barberos.",
        )
    # El barbero invitado hereda el shopId del admin que invita — nunca se
    # acepta un shopId del payload, así un admin no puede sembrar staff en
    # el negocio de otro tenant.
    caller_shop_id = caller_data.get("shopId")

    data = req.data or {}
    name = (data.get("name") or "").strip()
    email = (data.get("email") or "").strip().lower()
    specialty = (data.get("specialty") or "").strip() or None
    bio = (data.get("bio") or "").strip() or None
    is_available = bool(data.get("isAvailable", True))

    if not name or not email:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="Nombre y email son requeridos.",
        )

    # Generar contraseña temporal con la que el barbero hará su primer login.
    temp_password = _generate_temp_password()

    # Crear cuenta Firebase Auth o re-invitar una cuenta existente con el mismo email.
    reused_auth_user = False
    try:
        user_record = fb_auth.create_user(
            email=email,
            password=temp_password,
            display_name=name,
            disabled=False,
        )
    except fb_auth.EmailAlreadyExistsError:
        user_record = fb_auth.get_user_by_email(email)
        previous = db.collection("users").document(user_record.uid).get().to_dict() or {}
        if previous.get("role") != "barber" or previous.get("shopId") != caller_shop_id:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.ALREADY_EXISTS,
                message="Ya existe una cuenta con ese correo.",
            )
        fb_auth.update_user(user_record.uid, password=temp_password, display_name=name, disabled=False)
        reused_auth_user = True
    except Exception as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"Error creando cuenta: {e}",
        )

    barber_id = user_record.uid
    # Nombre del negocio para el cuerpo del correo — del shop del admin que
    # invita, no de un doc global (cada tenant tiene su propio nombre).
    shop_snap = db.collection("shops").document(caller_shop_id).get() if caller_shop_id else None
    shop_name = (
        (shop_snap.to_dict() or {}).get("name", "La Barbería")
        if shop_snap is not None and shop_snap.exists
        else "La Barbería"
    )

    # Documento único users/{uid}: identidad + perfil de barbero.
    db.collection("users").document(barber_id).set(
        {
            "id": barber_id,
            "name": name,
            "email": email,
            "role": "barber",
            "shopId": caller_shop_id,
            "phone": None,
            "phoneNormalized": None,
            "photoUrl": None,
            "isAnonymous": False,
            "inviteStatus": "resent" if reused_auth_user else "pending",
            "mustChangePassword": True,
            "createdAt": firestore.SERVER_TIMESTAMP,
            "specialty": specialty,
            "bio": bio,
            "isAvailable": is_available,
            # Horario por defecto: lunes–sábado 9–19, domingo cerrado.
            "workingHours": {str(d): [9, 19] for d in range(1, 7)},
        }
    )

    # Vista pública denormalizada (ver firestore.rules: users ya no es
    # legible por anónimos) — solo los campos seguros para mostrar en el
    # picker de barberos de la app de reservas.
    db.collection("barber_directory").document(barber_id).set(
        {
            "name": name,
            "photoUrl": None,
            "specialty": specialty,
            "isAvailable": is_available,
            "shopId": caller_shop_id,
        }
    )

    # Enviar correo con credenciales vía SendGrid.
    email_sent = True
    try:
        _send_invitation_email(email, name, shop_name, temp_password)
    except Exception as e:
        email_sent = False
        print(f"[inviteBarber] Advertencia: no se pudo enviar correo a {email}: {e}")

    return {
        "barberId": barber_id,
        "reusedAuthUser": reused_auth_user,
        "temporaryPassword": temp_password,
        "emailSent": email_sent,
    }


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
    caller_data = caller.to_dict() or {}
    if not caller.exists or caller_data.get("role") != "admin" or not caller_data.get("shopId"):
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

    target_snap = db.collection("users").document(barber_id).get()
    target = target_snap.to_dict() or {}
    if target.get("role") != "barber" or target.get("shopId") != caller_data.get("shopId"):
        # Un admin no puede eliminar staff de otro negocio, aunque conozca
        # el uid (p.ej. probando IDs a mano).
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
            message="Ese barbero no pertenece a tu negocio.",
        )

    # Retain the tenant binding until Auth deletion succeeds so admins can retry.
    try:
        fb_auth.delete_user(barber_id)
    except fb_auth.UserNotFoundError:
        pass
    batch = db.batch()
    batch.delete(target_snap.reference)
    batch.delete(db.collection("barber_directory").document(barber_id))
    batch.commit()

    return {"success": True}


# -----------------------------------------------------------------------------
# resetBarberPassword
# -----------------------------------------------------------------------------


def _send_password_reset_email(
    to_email: str,
    barber_name: str,
    shop_name: str,
    temp_password: str,
) -> None:
    """Envía correo con una contraseña temporal nueva vía SendGrid.

    Mismas variables de entorno que `_send_invitation_email`.
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
        f"Un administrador de {shop_name} restableció tu contraseña.\n\n"
        f"Tu nueva contraseña temporal es:\n"
        f"  {temp_password}\n\n"
        f"Ingresa a la aplicación con esta contraseña; se te pedirá "
        f"cambiarla en tu próximo inicio de sesión.\n\n"
        f"Si no esperabas este cambio, contacta a tu administrador de inmediato."
    )

    html = f"""<!DOCTYPE html>
<html lang="es">
<body style="margin:0;padding:0;background:#f4f4f5;font-family:sans-serif">
<table width="100%" cellpadding="0" cellspacing="0">
  <tr><td align="center" style="padding:40px 16px">
    <table width="480" cellpadding="0" cellspacing="0"
           style="background:#fff;border-radius:12px;overflow:hidden;
                  box-shadow:0 2px 8px rgba(0,0,0,.08)">
      <tr><td style="background:#f59e0b;padding:28px 32px">
        <h1 style="margin:0;color:#fff;font-size:22px;font-weight:700">
          Contraseña restablecida
        </h1>
      </td></tr>
      <tr><td style="padding:32px">
        <p style="margin:0 0 16px;color:#111;font-size:15px">
          Hola <strong>{barber_name}</strong>,
        </p>
        <p style="margin:0 0 24px;color:#374151;font-size:15px;line-height:1.6">
          Un administrador de <strong>{shop_name}</strong> restableció tu
          contraseña. Esta es tu nueva contraseña temporal:
        </p>
        <table width="100%" cellpadding="0" cellspacing="0"
               style="background:#fffbeb;border:1px solid #fde68a;
                      border-radius:8px;margin-bottom:24px">
          <tr><td style="padding:20px 24px">
            <p style="margin:0;color:#111;font-size:15px">
              <span style="color:#6b7280">Contraseña:</span>&nbsp;
              <strong style="font-family:monospace;font-size:16px;
                             letter-spacing:.08em">{temp_password}</strong>
            </p>
          </td></tr>
        </table>
        <p style="margin:0 0 8px;color:#374151;font-size:14px;line-height:1.6">
          Se te pedirá cambiarla en tu próximo inicio de sesión.
          <br>
          <span style="color:#6b7280">
            Si no esperabas este cambio, contacta a tu administrador de inmediato.
          </span>
        </p>
      </td></tr>
      <tr><td style="padding:16px 32px;background:#f9fafb;border-top:1px solid #e5e7eb">
        <p style="margin:0;color:#9ca3af;font-size:12px">
          Este correo fue generado por una acción de un administrador de {shop_name}.
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
        subject=f"{shop_name} — Tu contraseña fue restablecida",
        plain_text_content=plain,
        html_content=html,
    )

    client = sg_module.SendGridAPIClient(api_key)
    response = client.send(message)
    if response.status_code >= 400:
        raise RuntimeError(
            f"SendGrid error {response.status_code}: {response.body}"
        )


@https_fn.on_call()
def resetBarberPassword(req: https_fn.CallableRequest) -> dict[str, Any]:
    """Restablece la contraseña de un barbero (rotación forzada por admin).

    Por seguridad (barbero olvidó su contraseña, o rotación periódica), el
    admin puede forzar una nueva contraseña temporal sin depender de un
    flujo de "forgot password" por correo del propio barbero — hoy esa
    pantalla solo muestra un mensaje pidiendo contactar al admin (ver
    `staff_login_page.dart`), así que esta función ES ese mecanismo.

    Input:
        barberId: str

    Output:
        { temporaryPassword: str, emailSent: bool }

    Errores:
        unauthenticated   → el llamador no tiene sesión
        permission-denied → el llamador no es admin, o el barbero no
                             pertenece a su shop
        not-found         → el barbero no existe
        invalid-argument  → barberId vacío
    """
    if req.auth is None:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
            message="Se requiere autenticación.",
        )

    db = firestore.client()

    caller = db.collection("users").document(req.auth.uid).get()
    caller_data = caller.to_dict() or {}
    if not caller.exists or caller_data.get("role") != "admin" or not caller_data.get("shopId"):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
            message="Solo administradores pueden restablecer contraseñas.",
        )

    barber_id = (req.data or {}).get("barberId", "").strip()
    if not barber_id:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="barberId es requerido.",
        )

    target_ref = db.collection("users").document(barber_id)
    target_snap = target_ref.get()
    if not target_snap.exists:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.NOT_FOUND,
            message=f"Barbero {barber_id} no existe.",
        )
    target_data = target_snap.to_dict() or {}
    if target_data.get("shopId") != caller_data.get("shopId"):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
            message="Ese barbero no pertenece a tu negocio.",
        )
    if target_data.get("role") != "barber":
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
            message="Solo se puede restablecer la contraseña de barberos.",
        )

    temp_password = _generate_temp_password()
    fb_auth.update_user(barber_id, password=temp_password)
    target_ref.update({"mustChangePassword": True})

    caller_shop_id = caller_data.get("shopId")
    shop_snap = (
        db.collection("shops").document(caller_shop_id).get()
        if caller_shop_id
        else None
    )
    shop_name = (
        (shop_snap.to_dict() or {}).get("name", "La Barbería")
        if shop_snap is not None and shop_snap.exists
        else "La Barbería"
    )

    email = target_data.get("email")
    email_sent = True
    if email:
        try:
            _send_password_reset_email(
                email, target_data.get("name", "Barbero"), shop_name, temp_password
            )
        except Exception as e:
            email_sent = False
            print(f"[resetBarberPassword] Advertencia: no se pudo enviar correo a {email}: {e}")
    else:
        email_sent = False

    return {"temporaryPassword": temp_password, "emailSent": email_sent}


# firebase-functions==0.4.1 (pinned) has no `retry` option on Firestore
# triggers. `reconcile` re-reads both documents and is idempotent, so a missed
# event is repaired by the next write to the profile or by
# backend/scripts/migrate_barber_directory.py (supports --dry-run).
@firestore_fn.on_document_written(document="users/{uid}")
def syncBarberDirectory(event):
    db = firestore.client()
    uid = event.params["uid"]
    reconcile(db.transaction(), db.collection("users").document(uid),
              db.collection("barber_directory").document(uid))
