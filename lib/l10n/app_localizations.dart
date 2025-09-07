import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @home_title.
  ///
  /// In en, this message translates to:
  /// **'Discover our services'**
  String get home_title;

  /// No description provided for @select_service_cta.
  ///
  /// In en, this message translates to:
  /// **'Book now'**
  String get select_service_cta;

  /// No description provided for @my_bookings_title.
  ///
  /// In en, this message translates to:
  /// **'My Appointments'**
  String get my_bookings_title;

  /// No description provided for @my_bookings_empty.
  ///
  /// In en, this message translates to:
  /// **'You have no appointments yet'**
  String get my_bookings_empty;

  /// No description provided for @my_bookings_empty_cta.
  ///
  /// In en, this message translates to:
  /// **'Book now'**
  String get my_bookings_empty_cta;

  /// No description provided for @service_duration_label.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get service_duration_label;

  /// No description provided for @appointment_rebook.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get appointment_rebook;

  /// No description provided for @appointment_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get appointment_cancel;

  /// No description provided for @appointment_status_past.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get appointment_status_past;

  /// No description provided for @appointment_status_upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get appointment_status_upcoming;

  /// No description provided for @details_client_title.
  ///
  /// In en, this message translates to:
  /// **'Client Details'**
  String get details_client_title;

  /// No description provided for @details_confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm Booking'**
  String get details_confirm;

  /// No description provided for @calendar_title.
  ///
  /// In en, this message translates to:
  /// **'Select Date & Time'**
  String get calendar_title;

  /// No description provided for @my_bookings_heading.
  ///
  /// In en, this message translates to:
  /// **'Your scheduled appointments'**
  String get my_bookings_heading;

  /// No description provided for @empty_no_bookings.
  ///
  /// In en, this message translates to:
  /// **'You have no appointments yet'**
  String get empty_no_bookings;

  /// No description provided for @empty_bookings_cta.
  ///
  /// In en, this message translates to:
  /// **'Book now'**
  String get empty_bookings_cta;

  /// No description provided for @appointment_badge_past.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get appointment_badge_past;

  /// No description provided for @appointment_badge_upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get appointment_badge_upcoming;

  /// No description provided for @appointment_badge_canceled.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get appointment_badge_canceled;

  /// No description provided for @appointment_rebook_soon.
  ///
  /// In en, this message translates to:
  /// **'Reschedule (soon)'**
  String get appointment_rebook_soon;

  /// No description provided for @appointment_cancel_soon.
  ///
  /// In en, this message translates to:
  /// **'Cancel (soon)'**
  String get appointment_cancel_soon;

  /// No description provided for @confirm_cancel_title.
  ///
  /// In en, this message translates to:
  /// **'Cancel appointment'**
  String get confirm_cancel_title;

  /// No description provided for @confirm_cancel_msg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this appointment?'**
  String get confirm_cancel_msg;

  /// No description provided for @confirm_cancel_yes.
  ///
  /// In en, this message translates to:
  /// **'Yes, cancel'**
  String get confirm_cancel_yes;

  /// No description provided for @confirm_cancel_no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get confirm_cancel_no;

  /// No description provided for @rebook_sheet_title.
  ///
  /// In en, this message translates to:
  /// **'Reschedule appointment'**
  String get rebook_sheet_title;

  /// No description provided for @rebook_pick_day.
  ///
  /// In en, this message translates to:
  /// **'Pick a day'**
  String get rebook_pick_day;

  /// No description provided for @rebook_pick_time.
  ///
  /// In en, this message translates to:
  /// **'Select a time'**
  String get rebook_pick_time;

  /// No description provided for @duration_label.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration_label;

  /// No description provided for @client_label.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get client_label;

  /// No description provided for @price_total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get price_total;

  /// No description provided for @currency_symbol_gtq.
  ///
  /// In en, this message translates to:
  /// **'Q'**
  String get currency_symbol_gtq;

  /// No description provided for @hero_title.
  ///
  /// In en, this message translates to:
  /// **'Your style, your time'**
  String get hero_title;

  /// No description provided for @hero_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Book in 3 steps. No signup.'**
  String get hero_subtitle;

  /// No description provided for @hero_cta_primary.
  ///
  /// In en, this message translates to:
  /// **'Book now'**
  String get hero_cta_primary;

  /// No description provided for @hero_cta_secondary.
  ///
  /// In en, this message translates to:
  /// **'View services'**
  String get hero_cta_secondary;

  /// No description provided for @home_popular_title.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get home_popular_title;

  /// No description provided for @price_from_prefix.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get price_from_prefix;

  /// No description provided for @hero_image_semantics.
  ///
  /// In en, this message translates to:
  /// **'Illustrative shop image'**
  String get hero_image_semantics;

  /// No description provided for @see_all.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get see_all;

  /// No description provided for @services_filter_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get services_filter_all;

  /// No description provided for @services_filter_hair.
  ///
  /// In en, this message translates to:
  /// **'Hair'**
  String get services_filter_hair;

  /// No description provided for @services_filter_beard.
  ///
  /// In en, this message translates to:
  /// **'Beard'**
  String get services_filter_beard;

  /// No description provided for @services_filter_combo.
  ///
  /// In en, this message translates to:
  /// **'Combo'**
  String get services_filter_combo;

  /// No description provided for @service_policy_rebook.
  ///
  /// In en, this message translates to:
  /// **'You can reschedule up to 3h before'**
  String get service_policy_rebook;

  /// No description provided for @service_choose_and_continue.
  ///
  /// In en, this message translates to:
  /// **'Choose & continue'**
  String get service_choose_and_continue;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
    case 'es':
      return SEs();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
