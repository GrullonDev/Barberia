// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get home_title => 'Discover our services';

  @override
  String get select_service_cta => 'Book now';

  @override
  String get my_bookings_title => 'My Appointments';

  @override
  String get my_bookings_empty => 'You have no appointments yet';

  @override
  String get my_bookings_empty_cta => 'Book now';

  @override
  String get service_duration_label => 'Duration';

  @override
  String get appointment_rebook => 'Reschedule';

  @override
  String get appointment_cancel => 'Cancel';

  @override
  String get appointment_status_past => 'Past';

  @override
  String get appointment_status_upcoming => 'Upcoming';

  @override
  String get details_client_title => 'Client Details';

  @override
  String get details_confirm => 'Confirm Booking';

  @override
  String get calendar_title => 'Select Date & Time';

  @override
  String get my_bookings_heading => 'Your scheduled appointments';

  @override
  String get empty_no_bookings => 'You have no appointments yet';

  @override
  String get empty_bookings_cta => 'Book now';

  @override
  String get appointment_badge_past => 'Past';

  @override
  String get appointment_badge_upcoming => 'Upcoming';

  @override
  String get appointment_badge_canceled => 'Canceled';

  @override
  String get appointment_rebook_soon => 'Reschedule (soon)';

  @override
  String get appointment_cancel_soon => 'Cancel (soon)';

  @override
  String get confirm_cancel_title => 'Cancel appointment';

  @override
  String get confirm_cancel_msg =>
      'Are you sure you want to cancel this appointment?';

  @override
  String get confirm_cancel_yes => 'Yes, cancel';

  @override
  String get confirm_cancel_no => 'No';

  @override
  String get rebook_sheet_title => 'Reschedule appointment';

  @override
  String get rebook_pick_day => 'Pick a day';

  @override
  String get rebook_pick_time => 'Select a time';

  @override
  String get duration_label => 'Duration';

  @override
  String get client_label => 'Client';

  @override
  String get price_total => 'Total';

  @override
  String get currency_symbol_gtq => 'Q';

  @override
  String get hero_title => 'Your style, your time';

  @override
  String get hero_subtitle => 'Book in 3 steps. No signup.';

  @override
  String get hero_cta_primary => 'Book now';

  @override
  String get hero_cta_secondary => 'View services';

  @override
  String get home_popular_title => 'Popular';

  @override
  String get price_from_prefix => 'From';

  @override
  String get hero_image_semantics => 'Illustrative shop image';

  @override
  String get see_all => 'See all';

  @override
  String get services_filter_all => 'All';

  @override
  String get services_filter_hair => 'Hair';

  @override
  String get services_filter_beard => 'Beard';

  @override
  String get services_filter_combo => 'Combo';

  @override
  String get services_filter_facial => 'Facial';

  @override
  String get service_policy_rebook => 'You can reschedule up to 3h before';

  @override
  String get service_choose_and_continue => 'Choose & continue';

  @override
  String get cancel => 'Cancel';

  @override
  String calendar_schedule_range(String open, String close) {
    return 'Hours $open–$close';
  }

  @override
  String get calendar_quick_today => 'Today';

  @override
  String get calendar_quick_tomorrow => 'Tomorrow';

  @override
  String get calendar_quick_next_sat => 'Next Sat';

  @override
  String calendar_slots_title(String date, String range) {
    return 'Slots $date • $range';
  }

  @override
  String get calendar_morning => 'Morning';

  @override
  String get calendar_afternoon => 'Afternoon';

  @override
  String get calendar_legend_available => 'Available';

  @override
  String get calendar_legend_occupied => 'Busy';

  @override
  String get calendar_legend_hold => 'Hold';

  @override
  String get calendar_legend_off => 'Off hours';

  @override
  String get calendar_select_hour_label => 'Select a time';

  @override
  String get calendar_continue => 'Continue';

  @override
  String calendar_summary_semantics(String service, String date, String time) {
    return 'Summary: $service on $date at $time';
  }

  @override
  String get privacy_title => 'Privacy';

  @override
  String get privacy_prelim_header => 'Privacy Policy (preliminary)';

  @override
  String get privacy_prelim_body =>
      'This preliminary version is a placeholder. It will describe how the company collects, uses and protects personal data: name, phone, email and booking preferences.\n\nBy continuing you accept the use of this data to manage bookings and reminders. It won\'t be shared with unauthorized third parties.\n\nComing soon: legal basis, retention times, user rights and contact details of the controller.\n\nLast update: pending.';

  @override
  String get privacy_principles_title => 'Key Principles';

  @override
  String get privacy_principle_minimum =>
      'We only ask for the minimum info to manage the booking.';

  @override
  String get privacy_principle_opt_in =>
      'You can opt in/out of reminders (preference stored).';

  @override
  String get privacy_principle_erasure =>
      'You will be able to request deletion (future feature).';

  @override
  String get privacy_principle_security =>
      'Data will be transmitted securely (pending implementation).';

  @override
  String get privacy_note_title => 'Note';

  @override
  String get privacy_note_body =>
      'This screen is temporary and not legal advice. Final text must be reviewed and approved before publication.';

  @override
  String get privacy_acknowledge => 'Understood';

  @override
  String get details_form_intro => 'Complete your details';

  @override
  String get details_contact_hint =>
      'Name and at least one contact method (phone or email).';

  @override
  String get details_reminders_label => 'Receive reminders ';

  @override
  String privacy_version_label(String version, String date) {
    return 'Version $version • Updated $date';
  }

  @override
  String get confirm_title => 'Booking Confirmation';

  @override
  String get confirm_incomplete => 'Incomplete booking';

  @override
  String get confirm_copy_link => 'Copy link';

  @override
  String get confirm_share_link => 'Share';

  @override
  String get confirm_link_copied => 'Link copied';

  @override
  String get confirm_open_in_maps => 'Open in Maps / Waze';

  @override
  String get confirm_home => 'Home';

  @override
  String get confirm_add_calendar => 'Add to calendar';

  @override
  String get confirm_add_calendar_subject => 'Add appointment to calendar';

  @override
  String get confirm_add_calendar_body =>
      '.ics file attached with your appointment';

  @override
  String get confirm_qr_semantics =>
      'Location QR code with appointment metadata';

  @override
  String get confirm_scan_qr_for_directions => 'Scan QR for directions';

  @override
  String get confirm_get_directions => 'Get directions';

  @override
  String confirm_code_suffix(String code) {
    return '$code';
  }
}
