import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:barberia/app/router.dart';

const Color _ink = Color(0xFF101312);
const Color _inkDeep = Color(0xFF0B0F0E);
const Color _section = Color(0xFF171A19);
const Color _panel = Color(0xFF202221);
const Color _line = Color(0xFF3A3D39);
const Color _gold = Color(0xFFE8C84E);
const Color _muted = Color(0xFFC7C7C2);

class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: _ink,
        textTheme: Theme.of(
          context,
        ).textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
      ),
      child: Scaffold(
        backgroundColor: _ink,
        appBar: isDesktop
            ? null
            : AppBar(
                backgroundColor: _ink,
                title: Text(
                  'THE GENTLEMAN',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
        body: CustomScrollView(
          slivers: <Widget>[
            if (isDesktop)
              SliverToBoxAdapter(
                child: _TopNav(
                  onBook: () => context.goNamed(RouteNames.services),
                ),
              ),
            SliverToBoxAdapter(
              child: _GalleryContent(
                compact: !isDesktop,
                onBook: () => context.goNamed(RouteNames.personalizer),
              ),
            ),
            SliverToBoxAdapter(
              child: _ExclusiveCta(
                compact: !isDesktop,
                onConsult: () => context.goNamed(RouteNames.personalizer),
                onPortfolio: () => context.goNamed(RouteNames.gallery),
              ),
            ),
            if (isDesktop) const SliverToBoxAdapter(child: _Footer()),
          ],
        ),
      ),
    );
  }
}

class _TopNav extends StatelessWidget {
  const _TopNav({required this.onBook});

  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      decoration: const BoxDecoration(
        color: _ink,
        border: Border(bottom: BorderSide(color: _line)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              children: <Widget>[
                Text(
                  'THE GENTLEMAN',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                _NavLink(label: 'Services', onTap: onBook),
                _NavLink(
                  label: 'Gallery',
                  selected: true,
                  onTap: () => context.goNamed(RouteNames.gallery),
                ),
                _NavLink(label: 'Barbers', onTap: onBook),
                _NavLink(label: 'Membership', onTap: onBook),
                const SizedBox(width: 42),
                _GoldButton(label: 'BOOK NOW', onTap: onBook),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: selected ? _gold : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: selected ? 48 : 0,
            height: 1,
            color: _gold,
          ),
        ],
      ),
    );
  }
}

class _GalleryContent extends StatelessWidget {
  const _GalleryContent({required this.compact, required this.onBook});

  final bool compact;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _ink,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 18 : 32,
              compact ? 46 : 94,
              compact ? 18 : 32,
              compact ? 74 : 118,
            ),
            child: Column(
              children: <Widget>[
                Text(
                  'Nuestros Estilos de Firma',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: compact ? 36 : 48,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                    shadows: const <Shadow>[
                      Shadow(
                        color: Colors.black,
                        blurRadius: 0,
                        offset: Offset(1.5, 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: const Text(
                    'Una seleccion curada de cortes clasicos y modernos, disenados para el hombre que valora la precision y el caracter.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _muted, fontSize: 16, height: 1.55),
                  ),
                ),
                SizedBox(height: compact ? 44 : 76),
                const _FilterBar(),
                const SizedBox(height: 44),
                _StyleGrid(compact: compact, onBook: onBook),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context) {
    const List<String> filters = <String>[
      'TODOS',
      'CLASICOS',
      'MODERNOS',
      'CORTOS',
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      runSpacing: 12,
      children: <Widget>[
        for (int i = 0; i < filters.length; i++)
          _FilterButton(label: filters[i], selected: i == 0),
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? _gold : Colors.transparent,
        border: Border.all(color: selected ? _gold : _line),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.black : Colors.white,
          fontSize: 10,
          letterSpacing: 1.6,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StyleGrid extends StatelessWidget {
  const _StyleGrid({required this.compact, required this.onBook});

  final bool compact;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Column(
        children: _styles
            .map(
              (_StyleEntry style) => Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: _StyleCard(style: style, onBook: onBook),
              ),
            )
            .toList(),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _styles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 22,
        mainAxisSpacing: 22,
        childAspectRatio: 0.61,
      ),
      itemBuilder: (BuildContext context, int index) {
        return _StyleCard(style: _styles[index], onBook: onBook);
      },
    );
  }
}

class _StyleCard extends StatelessWidget {
  const _StyleCard({required this.style, required this.onBook});

  final _StyleEntry style;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _panel,
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AspectRatio(
            aspectRatio: 0.92,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Image.asset(style.asset, fit: BoxFit.cover),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.82),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 22,
                  right: 22,
                  bottom: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _Badge(label: style.badge),
                      const SizedBox(height: 10),
                      Text(
                        style.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.white,
                          fontSize: 24,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      style.description,
                      style: const TextStyle(
                        color: Color(0xFFE4E4E0),
                        fontSize: 15,
                        height: 1.58,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _OutlineGoldButton(
                    label: 'PERSONALIZAR ESTE ESTILO',
                    onTap: onBook,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: const Color(0xFF32342F).withValues(alpha: 0.92),
      child: Text(
        label,
        style: const TextStyle(
          color: _gold,
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ExclusiveCta extends StatelessWidget {
  const _ExclusiveCta({
    required this.compact,
    required this.onConsult,
    required this.onPortfolio,
  });

  final bool compact;
  final VoidCallback onConsult;
  final VoidCallback onPortfolio;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _section,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 22 : 32,
              vertical: compact ? 62 : 82,
            ),
            child: Column(
              children: <Widget>[
                Text(
                  '\u00bfBUSCAS ALGO EXCLUSIVO?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: compact ? 27 : 32,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    shadows: const <Shadow>[
                      Shadow(
                        color: Colors.black,
                        blurRadius: 0,
                        offset: Offset(1.2, 1.2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Nuestros maestros barberos pueden crear una version personalizada que se adapte perfectamente a tu tipo de cabello y estructura facial.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFE1E1DD),
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 14,
                  runSpacing: 14,
                  children: <Widget>[
                    SizedBox(
                      width: compact ? double.infinity : 252,
                      child: _GoldButton(
                        label: 'RESERVA UNA CONSULTA',
                        onTap: onConsult,
                      ),
                    ),
                    SizedBox(
                      width: compact ? double.infinity : 282,
                      child: _OutlineWhiteButton(
                        label: 'VER PORTAFOLIO COMPLETO',
                        onTap: onPortfolio,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoldButton extends StatelessWidget {
  const _GoldButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: _gold,
        foregroundColor: Colors.black,
        shape: const RoundedRectangleBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          letterSpacing: 1.8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _OutlineGoldButton extends StatelessWidget {
  const _OutlineGoldButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: _gold,
        side: const BorderSide(color: _gold),
        shape: const RoundedRectangleBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 12,
          height: 1.15,
          letterSpacing: 1.8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _OutlineWhiteButton extends StatelessWidget {
  const _OutlineWhiteButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white70),
        shape: const RoundedRectangleBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          letterSpacing: 1.8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _inkDeep,
        border: Border(top: BorderSide(color: _line)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 42),
            child: Row(
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "THE GENTLEMAN'S LOUNGE",
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "© 2024 THE GENTLEMAN'S LOUNGE. ALL RIGHTS RESERVED.",
                      style: TextStyle(
                        color: Color(0xFF9D9D98),
                        fontSize: 11,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Text(
                  'PRIVACY POLICY      TERMS OF SERVICE      CAREERS      CONTACT',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StyleEntry {
  const _StyleEntry({
    required this.name,
    required this.badge,
    required this.description,
    required this.asset,
  });

  final String name;
  final String badge;
  final String description;
  final String asset;
}

const List<_StyleEntry> _styles = <_StyleEntry>[
  _StyleEntry(
    name: 'Modern Fade',
    badge: 'POPULAR',
    description:
        'Un degradado impecable que fusiona la piel con una transicion suave hacia un cabello mas largo y texturizado en la parte superior.',
    asset: 'assets/images/style_modern_fade.png',
  ),
  _StyleEntry(
    name: 'Pompadour',
    badge: 'ELEGANTE',
    description:
        'El epitome de la sofisticacion. Volumen alto en la parte superior con un acabado pulido y laterales perfectamente perfilados.',
    asset: 'assets/images/style_pompadour.png',
  ),
  _StyleEntry(
    name: 'Buzz Cut',
    badge: 'MINIMALISTA',
    description:
        'Simplicidad y fuerza. Un corte uniforme y preciso que resalta las facciones del rostro con un perfilado milimetrico.',
    asset: 'assets/images/style_buzz_cut.png',
  ),
  _StyleEntry(
    name: 'Executive',
    badge: 'CLASSIC',
    description:
        'El estandar del profesionalismo. Raya lateral marcada y longitud moderada para un estilo versatil que nunca pasa de moda.',
    asset: 'assets/images/style_executive.png',
  ),
];
