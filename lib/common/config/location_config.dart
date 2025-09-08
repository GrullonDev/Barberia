/// Global location configuration for the barbershop.
/// Centralizes address & coordinates so they can be reused and modified easily
/// (or later fetched from a backend / remote config).
class LocationConfig {
  static const String address = 'Av. Principal 123, Ciudad';
  static const double latitude = 14.503056; // Test LAT
  static const double longitude = -90.577228; // Test LNG

  /// Google Maps base search URL with coordinates + query.
  static String googleMapsBaseUrl() {
    final String encodedAddress = Uri.encodeComponent(address);
    return 'https://www.google.com/maps/search/?api=1&query=$encodedAddress&ll=$latitude,$longitude';
  }

  /// Build Waze deep link.
  static Uri wazeUri() =>
      Uri.parse('waze://?ll=$latitude,$longitude&navigate=yes');

  /// Build Google Maps Uri.
  static Uri googleMapsUri() => Uri.parse(googleMapsBaseUrl());
}
