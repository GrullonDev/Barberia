import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color barberBg = Color(0xFF0B0B0B);
const Color barberSurface = Color(0xFF1B1C1C);
const Color barberSurfaceRaised = Color(0xFF262828);
const Color barberGold = Color(0xFFD4AF37);
const Color barberText = Color(0xFFFFFFFF);
const Color barberMuted = Color(0xFFC7C7C7);
const Color barberDim = Color(0xFF888888);
const Color barberBorder = Color(0xFF343737);

TextStyle barberBrandStyle({
  double fontSize = 28,
  double height = 0.92,
  double letterSpacing = 2,
}) {
  return GoogleFonts.cinzel(
    color: barberGold,
    fontSize: fontSize,
    height: height,
    fontWeight: FontWeight.w900,
    letterSpacing: letterSpacing,
  );
}

TextStyle barberHeadingStyle({double fontSize = 28}) {
  return GoogleFonts.cormorantGaramond(
    color: barberText,
    fontSize: fontSize,
    height: 1,
    fontWeight: FontWeight.w800,
  );
}

class BarberTopBar extends StatelessWidget {
  const BarberTopBar({
    required this.name,
    this.photoUrl,
    this.compact = false,
    this.centerBrand = false,
    this.menuLabel,
    super.key,
  });

  final String name;
  final String? photoUrl;
  final bool compact;
  final bool centerBrand;
  final String? menuLabel;

  @override
  Widget build(BuildContext context) {
    final double height = compact ? 64 : 86;
    final double avatarRadius = compact ? 18 : 22;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: barberBg,
        border: Border(bottom: BorderSide(color: barberBorder)),
      ),
      padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 20),
      child: Row(
        children: <Widget>[
          if (menuLabel == null)
            const Icon(Icons.menu, color: barberGold, size: 26)
          else
            Text(
              menuLabel!,
              style: barberBrandStyle(fontSize: compact ? 22 : 24),
            ),
          SizedBox(width: compact ? 12 : 18),
          Expanded(
            child: Text(
              compact || centerBrand ? 'THE\nGENTLEMAN' : 'THE GENTLEMAN',
              textAlign: centerBrand ? TextAlign.center : TextAlign.start,
              maxLines: 2,
              overflow: TextOverflow.visible,
              style: barberBrandStyle(
                fontSize: compact ? 25 : 32,
                height: compact ? 0.82 : 0.9,
              ),
            ),
          ),
          SizedBox(width: compact ? 10 : 14),
          CircleAvatar(
            radius: avatarRadius,
            backgroundColor: barberGold,
            child: CircleAvatar(
              radius: avatarRadius - 2,
              backgroundColor: barberSurface,
              backgroundImage: photoUrl == null ? null : NetworkImage(photoUrl!),
              child: photoUrl != null
                  ? null
                  : Text(
                      name.isEmpty ? '?' : name[0].toUpperCase(),
                      style: const TextStyle(
                        color: barberGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

