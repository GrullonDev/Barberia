import 'package:cloud_firestore/cloud_firestore.dart';

/// Configuración global de la barbería — un único documento `config/barberia`.
///
/// Esto sustituye los valores hardcoded que hoy viven dispersos en:
///   - calendar_page.dart (openHour/closeHour)
///   - location_config.dart (dirección, coords)
///   - settings_page.dart (whatsapp)
///
/// El admin edita este doc desde el panel admin (pantalla de Fase 3+).
/// Lectura pública (las reglas lo permiten) para que el sitio web cliente
/// muestre horarios, dirección, etc. sin login.
class BarberiaConfig {
  final String businessName;
  final int openHour; // 0–23
  final int closeHour; // 0–23
  final int slotMinutes; // granularidad de slots (15/20/30)
  final String address;
  final double? lat;
  final double? lng;
  final String? phone;
  final String? whatsappPhone;
  final String? logoUrl;
  final String? landingBaseUrl; // Custom web domain URL

  // Política anti no-show
  final int autoReleaseHours; // horas antes sin confirmar para liberar
  final int maxNoShows; // nº de no-shows antes de bloquear
  final bool requireConfirmation;

  const BarberiaConfig({
    this.businessName = 'Barbería',
    this.openHour = 9,
    this.closeHour = 19,
    this.slotMinutes = 30,
    this.address = '',
    this.lat,
    this.lng,
    this.phone,
    this.whatsappPhone,
    this.logoUrl,
    this.landingBaseUrl,
    this.autoReleaseHours = 4,
    this.maxNoShows = 3,
    this.requireConfirmation = true,
  });

  BarberiaConfig copyWith({
    String? businessName,
    int? openHour,
    int? closeHour,
    int? slotMinutes,
    String? address,
    double? lat,
    double? lng,
    String? phone,
    String? whatsappPhone,
    String? logoUrl,
    String? landingBaseUrl,
    int? autoReleaseHours,
    int? maxNoShows,
    bool? requireConfirmation,
  }) => BarberiaConfig(
    businessName: businessName ?? this.businessName,
    openHour: openHour ?? this.openHour,
    closeHour: closeHour ?? this.closeHour,
    slotMinutes: slotMinutes ?? this.slotMinutes,
    address: address ?? this.address,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    phone: phone ?? this.phone,
    whatsappPhone: whatsappPhone ?? this.whatsappPhone,
    logoUrl: logoUrl ?? this.logoUrl,
    landingBaseUrl: landingBaseUrl ?? this.landingBaseUrl,
    autoReleaseHours: autoReleaseHours ?? this.autoReleaseHours,
    maxNoShows: maxNoShows ?? this.maxNoShows,
    requireConfirmation: requireConfirmation ?? this.requireConfirmation,
  );

  Map<String, dynamic> toFirestore() => <String, dynamic>{
    'businessName': businessName,
    'openHour': openHour,
    'closeHour': closeHour,
    'slotMinutes': slotMinutes,
    'address': address,
    'lat': lat,
    'lng': lng,
    'phone': phone,
    'whatsappPhone': whatsappPhone,
    'logoUrl': logoUrl,
    'landingBaseUrl': landingBaseUrl,
    'autoReleaseHours': autoReleaseHours,
    'maxNoShows': maxNoShows,
    'requireConfirmation': requireConfirmation,
  };

  factory BarberiaConfig.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data =
        (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
    return BarberiaConfig(
      businessName: data['businessName'] as String? ?? 'Barbería',
      openHour: (data['openHour'] as num?)?.toInt() ?? 9,
      closeHour: (data['closeHour'] as num?)?.toInt() ?? 19,
      slotMinutes: (data['slotMinutes'] as num?)?.toInt() ?? 30,
      address: data['address'] as String? ?? '',
      lat: (data['lat'] as num?)?.toDouble(),
      lng: (data['lng'] as num?)?.toDouble(),
      phone: data['phone'] as String?,
      whatsappPhone: data['whatsappPhone'] as String?,
      logoUrl: data['logoUrl'] as String?,
      landingBaseUrl: data['landingBaseUrl'] as String?,
      autoReleaseHours: (data['autoReleaseHours'] as num?)?.toInt() ?? 4,
      maxNoShows: (data['maxNoShows'] as num?)?.toInt() ?? 3,
      requireConfirmation: data['requireConfirmation'] as bool? ?? true,
    );
  }
}
