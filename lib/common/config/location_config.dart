import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Global location configuration for the barbershop.
/// Centralizes address & coordinates so they can be reused and modified easily.
/// Values are read from the .env file.
class LocationConfig {
  static String get address =>
      dotenv.get('APP_ADDRESS', fallback: 'Av. Principal 123, Ciudad');

  static double get latitude =>
      double.tryParse(dotenv.get('APP_LATITUDE', fallback: '14.503056')) ??
      14.503056;

  static double get longitude =>
      double.tryParse(dotenv.get('APP_LONGITUDE', fallback: '-90.577228')) ??
      -90.577228;

  /// Base URL for the web landing page (Firebase Hosting)
  static String get landingBaseUrl => dotenv.get(
    'APP_LANDING_BASE_URL',
    fallback: 'https://barbershop-ee9c0.web.app',
  );

  /// Google Maps base search URL with coordinates + query.
  static String googleMapsBaseUrl() {
    final String encodedAddress = Uri.encodeComponent(address);
    return 'https://www.google.com/maps/search/?api=1&query=$encodedAddress&ll=$latitude,$longitude';
  }

  /// Build the URL for a specific booking to be used in QR codes
  static String buildBookingUrl(String bookingId, {String? baseUrl}) {
    final String base = baseUrl ?? landingBaseUrl;
    return '$base/booking/$bookingId';
  }

  /// Build Waze deep link.
  static Uri wazeUri() =>
      Uri.parse('waze://?ll=$latitude,$longitude&navigate=yes');

  /// Build Google Maps Uri.
  static Uri googleMapsUri() => Uri.parse(googleMapsBaseUrl());
}
