import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:barberia/app/router.dart';

const Color _ink = Color(0xFF101312);
const Color _inkDeep = Color(0xFF0B0F0E);
const Color _panel = Color(0xFF202221);
const Color _line = Color(0xFF3A3D39);
const Color _gold = Color(0xFFE8C84E);

class BookingExperiencePage extends StatefulWidget {
  const BookingExperiencePage({super.key});

  @override
  State<BookingExperiencePage> createState() => _BookingExperiencePageState();
}

class _BookingExperiencePageState extends State<BookingExperiencePage> {
  int _selectedBarber = 0;

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.sizeOf(context).width >= 960;

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
              SliverToBoxAdapter(child: _TopNav(onBook: _continueBooking)),
            SliverToBoxAdapter(
              child: _HeroIntro(compact: !isDesktop),
            ),
            SliverToBoxAdapter(
              child: _BarberSection(
                compact: !isDesktop,
                selectedIndex: _selectedBarber,
                onSelected: (int index) {
                  setState(() => _selectedBarber = index);
                },
                onContinue: _continueBooking,
              ),
            ),
            SliverToBoxAdapter(child: _Footer(compact: !isDesktop)),
          ],
        ),
      ),
    );
  }

  void _continueBooking() {
    context.goNamed(RouteNames.services);
  }
}

class _TopNav extends StatelessWidget {
  const _TopNav({required this.onBook});

  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
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
                GestureDetector(
                  onTap: () => context.goNamed(RouteNames.home),
                  child: Text(
                    'THE GENTLEMAN',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                _NavLink(label: 'Services', onTap: onBook),
                _NavLink(
                  label: 'Gallery',
                  onTap: () => context.goNamed(RouteNames.gallery),
                ),
                _NavLink(label: 'Barbers', selected: true, onTap: () {}),
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
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HeroIntro extends StatelessWidget {
  const _HeroIntro({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _ink,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 18 : 32,
              compact ? 48 : 70,
              compact ? 18 : 32,
              compact ? 38 : 54,
            ),
            child: Column(
              children: <Widget>[
                Text(
                  'Reserva tu Experiencia',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: compact ? 42 : 58,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    shadows: const <Shadow>[
                      Shadow(
                        color: Colors.black,
                        blurRadius: 0,
                        offset: Offset(1.4, 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: const Text(
                    "Precision, tradicion y el estilo que mereces. Sigue los pasos para agendar tu cita en The Gentleman's Lounge.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFE1E1DD),
                      fontSize: 17,
                      height: 1.55,
                    ),
                  ),
                ),
                SizedBox(height: compact ? 46 : 76),
                _StepIndicator(compact: compact),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Widget content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const _StepNode(number: '1', label: 'BARBERO', active: true),
        _StepLine(width: compact ? 42 : 80),
        const _StepNode(number: '2', label: 'AGENDA'),
        _StepLine(width: compact ? 42 : 80),
        const _StepNode(number: '3', label: 'RESUMEN'),
      ],
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: content,
      ),
    );
  }
}

class _StepNode extends StatelessWidget {
  const _StepNode({
    required this.number,
    required this.label,
    this.active = false,
  });

  final String number;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 102,
      child: Column(
        children: <Widget>[
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: active ? _gold : _line, width: 2),
              color: active ? _gold.withValues(alpha: 0.08) : _panel,
            ),
            child: Text(
              number,
              style: TextStyle(
                color: active ? _gold : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: active ? _gold : Colors.white,
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 2,
      margin: const EdgeInsets.only(bottom: 30),
      color: _line,
    );
  }
}

class _BarberSection extends StatelessWidget {
  const _BarberSection({
    required this.compact,
    required this.selectedIndex,
    required this.onSelected,
    required this.onContinue,
  });

  final bool compact;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _ink,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 18 : 32,
              compact ? 24 : 18,
              compact ? 18 : 32,
              compact ? 76 : 112,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Selecciona tu Barbero',
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: compact ? 34 : 42,
                    height: 1.05,
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
                const SizedBox(height: 14),
                const Text(
                  'Cada uno de nuestros expertos tiene un estilo unico de maestria.',
                  style: TextStyle(color: Color(0xFFE1E1DD), fontSize: 17),
                ),
                SizedBox(height: compact ? 28 : 42),
                if (compact)
                  Column(
                    children: <Widget>[
                      for (int i = 0; i < _barbers.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: _BarberCard(
                            barber: _barbers[i],
                            selected: selectedIndex == i,
                            onTap: () => onSelected(i),
                            onDoubleTap: onContinue,
                          ),
                        ),
                    ],
                  )
                else
                  Row(
                    children: <Widget>[
                      for (int i = 0; i < _barbers.length; i++) ...<Widget>[
                        Expanded(
                          child: _BarberCard(
                            barber: _barbers[i],
                            selected: selectedIndex == i,
                            onTap: () => onSelected(i),
                            onDoubleTap: onContinue,
                          ),
                        ),
                        if (i != _barbers.length - 1) const SizedBox(width: 26),
                      ],
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

class _BarberCard extends StatelessWidget {
  const _BarberCard({
    required this.barber,
    required this.selected,
    required this.onTap,
    required this.onDoubleTap,
  });

  final _BarberEntry barber;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _panel,
          border: Border.all(color: selected ? _gold : _line, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AspectRatio(
              aspectRatio: 0.8,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Image.asset(barber.asset, fit: BoxFit.cover),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.12),
                          Colors.black.withValues(alpha: 0.86),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    bottom: 20,
                    child: _Badge(label: barber.rank),
                  ),
                  if (selected)
                    Positioned(
                      right: 18,
                      bottom: 18,
                      child: Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _ink.withValues(alpha: 0.72),
                          border: Border.all(color: _gold),
                        ),
                        child: const Icon(Icons.check, color: _gold, size: 20),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        barber.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.white,
                          fontSize: 28,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          shadows: const <Shadow>[
                            Shadow(
                              color: Colors.black,
                              blurRadius: 0,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        barber.specialty,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE2E2DE),
                          fontSize: 15,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Icon(Icons.star, color: _gold, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          barber.rating,
                          style: const TextStyle(
                            color: _gold,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${barber.reviews} resenas',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      color: _gold,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 12,
          letterSpacing: 0.7,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.compact});

  final bool compact;

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
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 18 : 32,
              vertical: compact ? 38 : 54,
            ),
            child: compact
                ? const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _FooterBrand(),
                      SizedBox(height: 22),
                      _FooterLinks(),
                    ],
                  )
                : const Row(
                    children: <Widget>[
                      _FooterBrand(),
                      Spacer(),
                      _FooterLinks(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _FooterBrand extends StatelessWidget {
  const _FooterBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'THE GENTLEMAN',
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "© 2024 THE GENTLEMAN'S LOUNGE. ALL RIGHTS RESERVED.",
          style: TextStyle(
            color: Color(0xFFE0E0DC),
            fontSize: 12,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _FooterLinks extends StatelessWidget {
  const _FooterLinks();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'PRIVACY POLICY      TERMS OF SERVICE      CAREERS      CONTACT',
      style: TextStyle(color: Colors.white, fontSize: 12, letterSpacing: 1.5),
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
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          letterSpacing: 2.2,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _BarberEntry {
  const _BarberEntry({
    required this.name,
    required this.specialty,
    required this.rank,
    required this.rating,
    required this.reviews,
    required this.asset,
  });

  final String name;
  final String specialty;
  final String rank;
  final String rating;
  final int reviews;
  final String asset;
}

const List<_BarberEntry> _barbers = <_BarberEntry>[
  _BarberEntry(
    name: 'Julian Vance',
    specialty: 'Especialista en Navaja',
    rank: 'MASTER',
    rating: '4.9',
    reviews: 124,
    asset: 'assets/images/barber_julian_vance.png',
  ),
  _BarberEntry(
    name: 'Marcus Reed',
    specialty: 'Cortes Clasicos',
    rank: 'SENIOR',
    rating: '5.0',
    reviews: 98,
    asset: 'assets/images/barber_marcus_reed.png',
  ),
  _BarberEntry(
    name: 'Dorian Grey',
    specialty: 'Barba y Cuidado Facial',
    rank: 'ELITE',
    rating: '4.8',
    reviews: 215,
    asset: 'assets/images/barber_dorian_grey.png',
  ),
];
