/// Fade height options for the Custom Cut Personalizer.
enum FadeType { low, mid, high }

extension FadeTypeLabel on FadeType {
  String get label => switch (this) {
    FadeType.low => 'Fade Bajo',
    FadeType.mid => 'Fade Medio',
    FadeType.high => 'Fade Alto',
  };

  String get description => switch (this) {
    FadeType.low => 'Degradado sutil que comienza cerca de las orejas.',
    FadeType.mid => 'Degradado equilibrado que comienza a media altura.',
    FadeType.high => 'Degradado pronunciado que comienza cerca de la corona.',
  };
}

/// Beard styling options for the Custom Cut Personalizer.
enum BeardDetail { cleanShaven, lightStubble, fullBeard, goatee }

extension BeardDetailLabel on BeardDetail {
  String get label => switch (this) {
    BeardDetail.cleanShaven => 'Rostro Afeitado',
    BeardDetail.lightStubble => 'Barba Ligera',
    BeardDetail.fullBeard => 'Barba Completa',
    BeardDetail.goatee => 'Perilla',
  };
}
