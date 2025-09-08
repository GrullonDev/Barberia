// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class SEs extends S {
  SEs([String locale = 'es']) : super(locale);

  @override
  String get home_title => 'Descubre nuestros servicios';

  @override
  String get select_service_cta => 'Reservar ahora';

  @override
  String get my_bookings_title => 'Mis Citas';

  @override
  String get my_bookings_empty => 'No tienes citas aún';

  @override
  String get my_bookings_empty_cta => 'Reservar ahora';

  @override
  String get service_duration_label => 'Duración';

  @override
  String get appointment_rebook => 'Reprogramar';

  @override
  String get appointment_cancel => 'Cancelar';

  @override
  String get appointment_status_past => 'Pasada';

  @override
  String get appointment_status_upcoming => 'Próxima';

  @override
  String get details_client_title => 'Datos del Cliente';

  @override
  String get details_confirm => 'Confirmar Reserva';

  @override
  String get calendar_title => 'Seleccionar Fecha y Hora';

  @override
  String get my_bookings_heading => 'Tus citas programadas';

  @override
  String get empty_no_bookings => 'No tienes citas aún';

  @override
  String get empty_bookings_cta => 'Reservar ahora';

  @override
  String get appointment_badge_past => 'Pasada';

  @override
  String get appointment_badge_upcoming => 'Próxima';

  @override
  String get appointment_badge_canceled => 'Cancelada';

  @override
  String get appointment_rebook_soon => 'Reprogramar (próximamente)';

  @override
  String get appointment_cancel_soon => 'Cancelar (próximamente)';

  @override
  String get confirm_cancel_title => 'Cancelar cita';

  @override
  String get confirm_cancel_msg => '¿Seguro que deseas cancelar esta cita?';

  @override
  String get confirm_cancel_yes => 'Sí, cancelar';

  @override
  String get confirm_cancel_no => 'No';

  @override
  String get rebook_sheet_title => 'Reprogramar cita';

  @override
  String get rebook_pick_day => 'Elige un día';

  @override
  String get rebook_pick_time => 'Selecciona una hora';

  @override
  String get duration_label => 'Duración';

  @override
  String get client_label => 'Cliente';

  @override
  String get price_total => 'Total';

  @override
  String get currency_symbol_gtq => 'Q';

  @override
  String get hero_title => 'Tu corte, a tu hora';

  @override
  String get hero_subtitle => 'Reserva en 3 pasos sin registro.';

  @override
  String get hero_cta_primary => 'Reservar ahora';

  @override
  String get hero_cta_secondary => 'Ver servicios';

  @override
  String get home_popular_title => 'Populares';

  @override
  String get price_from_prefix => 'Desde';

  @override
  String get hero_image_semantics => 'Imagen ilustrativa del local';

  @override
  String get see_all => 'Ver todos';

  @override
  String get services_filter_all => 'Todo';

  @override
  String get services_filter_hair => 'Cabello';

  @override
  String get services_filter_beard => 'Barba';

  @override
  String get services_filter_combo => 'Combo';

  @override
  String get service_policy_rebook => 'Puedes reprogramar hasta 3 h antes';

  @override
  String get service_choose_and_continue => 'Elegir y continuar';

  @override
  String get cancel => 'Cancelar';

  @override
  String calendar_schedule_range(String open, String close) {
    return 'Horario $open–$close';
  }

  @override
  String get calendar_quick_today => 'Hoy';

  @override
  String get calendar_quick_tomorrow => 'Mañana';

  @override
  String get calendar_quick_next_sat => 'Próx. Sáb';

  @override
  String calendar_slots_title(String date, String range) {
    return 'Slots $date • $range';
  }

  @override
  String get calendar_morning => 'Mañana';

  @override
  String get calendar_afternoon => 'Tarde';

  @override
  String get calendar_legend_available => 'Disponible';

  @override
  String get calendar_legend_occupied => 'Ocupado';

  @override
  String get calendar_legend_hold => 'Hold';

  @override
  String get calendar_legend_off => 'Fuera de horario';

  @override
  String get calendar_select_hour_label => 'Selecciona una hora';

  @override
  String get calendar_continue => 'Continuar';

  @override
  String calendar_summary_semantics(String service, String date, String time) {
    return 'Resumen: $service el $date a las $time';
  }

  @override
  String get privacy_title => 'Privacidad';

  @override
  String get privacy_prelim_header =>
      'Política de Privacidad (versión preliminar)';

  @override
  String get privacy_prelim_body =>
      'Esta versión preliminar sirve como marcador de posición. Aquí se describirá cómo la empresa recopila, utiliza y protege los datos personales de los usuarios: nombre, teléfono, email y preferencias de reserva.\n\nAl continuar aceptas que tu información será usada para gestionar reservas y recordatorios. No se compartirá con terceros no autorizados.\n\nPróximamente: base legal del tratamiento, tiempos de retención, derechos del usuario y datos de contacto del responsable.\n\nÚltima actualización: pendiente.';

  @override
  String get privacy_principles_title => 'Principios Clave';

  @override
  String get privacy_principle_minimum =>
      'Sólo pedimos la información mínima para gestionar la reserva.';

  @override
  String get privacy_principle_opt_in =>
      'Puedes decidir si recibir recordatorios (se guarda tu preferencia).';

  @override
  String get privacy_principle_erasure =>
      'Podrás solicitar la eliminación de tus datos (función futura).';

  @override
  String get privacy_principle_security =>
      'La información se transmitirá de forma segura (pendiente).';

  @override
  String get privacy_note_title => 'Nota';

  @override
  String get privacy_note_body =>
      'Esta pantalla es temporal y no constituye asesoría legal. El texto definitivo debe ser revisado y aprobado antes de su publicación.';

  @override
  String get privacy_acknowledge => 'Entendido';

  @override
  String get details_form_intro => 'Completa tus datos';

  @override
  String get details_contact_hint =>
      'Nombre y al menos un medio de contacto (teléfono o email).';

  @override
  String get details_reminders_label => 'Recibir recordatorios ';

  @override
  String privacy_version_label(String version, String date) {
    return 'Versión $version • Actualizado $date';
  }

  @override
  String get confirm_title => 'Confirmación de Reserva';

  @override
  String get confirm_incomplete => 'Reserva incompleta';

  @override
  String get confirm_copy_link => 'Copiar enlace';

  @override
  String get confirm_share_link => 'Compartir';

  @override
  String get confirm_link_copied => 'Enlace copiado';

  @override
  String get confirm_open_in_maps => 'Abrir en Maps / Waze';

  @override
  String get confirm_home => 'Inicio';

  @override
  String get confirm_add_calendar => 'Añadir al calendario';

  @override
  String get confirm_add_calendar_subject => 'Añadir cita al calendario';

  @override
  String get confirm_add_calendar_body => 'Adjuntamos archivo .ics con tu cita';

  @override
  String get confirm_qr_semantics =>
      'Código QR de la ubicación con datos de la cita';

  @override
  String confirm_code_suffix(String code) {
    return '$code';
  }
}
