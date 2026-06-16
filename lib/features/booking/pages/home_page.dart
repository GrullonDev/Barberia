import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:barberia/app/router.dart';
import 'package:barberia/features/auth/models/user.dart';
import 'package:barberia/features/auth/providers/auth_providers.dart';
import 'package:barberia/features/booking/models/service.dart';
import 'package:barberia/features/booking/providers/booking_providers.dart';

const Color _ink = Color(0xFF101312);
const Color _panel = Color(0xFF1C1F1E);
const Color _panelAlt = Color(0xFF242725);
const Color _line = Color(0xFF3A3D39);
const Color _gold = Color(0xFFE8C84E);
const Color _muted = Color(0xFFB8B8B2);
const String _patternAsset = 'assets/images/barber_bg_pattern.png';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Service>> asyncServices = ref.watch(
      servicesAsyncProvider,
    );
    final User? user = ref.watch(authStateProvider);
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
                actions: _adminActions(context, user),
              ),
        body: asyncServices.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: _gold)),
          error: (Object e, StackTrace st) =>
              const Center(child: Text('No se pudieron cargar los servicios.')),
          data: (List<Service> services) => isDesktop
              ? _DesktopHome(services: services, user: user)
              : _MobileHome(services: services, user: user),
        ),
      ),
    );
  }

  List<Widget> _adminActions(BuildContext context, User? user) {
    if (user?.role != UserRole.admin) {
      return const <Widget>[];
    }
    return <Widget>[
      IconButton(
        icon: const Icon(Icons.add),
        onPressed: () => context.pushNamed(RouteNames.addService),
      ),
      IconButton(
        icon: const Icon(Icons.admin_panel_settings),
        onPressed: () => context.pushNamed(RouteNames.admin),
      ),
    ];
  }
}

class _DesktopHome extends StatelessWidget {
  const _DesktopHome({required this.services, required this.user});

  final List<Service> services;
  final User? user;

  @override
  Widget build(BuildContext context) {
    final List<Service> shown = services.take(3).toList();

    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: _TopNav(
            user: user,
            onBook: () => context.goNamed(RouteNames.services),
          ),
        ),
        SliverToBoxAdapter(
          child: _Hero(
            onBook: () => context.goNamed(RouteNames.services),
            onServices: () => context.goNamed(RouteNames.services),
          ),
        ),
        SliverToBoxAdapter(
          child: _SectionShell(
            child: Column(
              children: <Widget>[
                const _SectionHeading(
                  title: 'Nuestros Servicios',
                  subtitle:
                      'Tecnica precisa, ritual cuidado y atencion sin prisa.',
                ),
                const SizedBox(height: 38),
                if (shown.isEmpty)
                  const _EmptyPanel()
                else
                  Row(
                    children: shown
                        .map(
                          (Service service) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: _PremiumServiceCard(
                                service: service,
                                onTap: () =>
                                    context.goNamed(RouteNames.services),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _GallerySection(
            onOpen: () => context.goNamed(RouteNames.services),
          ),
        ),
        const SliverToBoxAdapter(child: _WhySection()),
        SliverToBoxAdapter(
          child: _GoldCta(onBook: () => context.goNamed(RouteNames.services)),
        ),
        const SliverToBoxAdapter(child: _Footer()),
      ],
    );
  }
}

class _MobileHome extends StatelessWidget {
  const _MobileHome({required this.services, required this.user});

  final List<Service> services;
  final User? user;

  @override
  Widget build(BuildContext context) {
    final List<Service> shown = services.take(4).toList();

    return ListView(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        bottom: MediaQuery.paddingOf(context).bottom + 110,
      ),
      children: <Widget>[
        const SizedBox(height: 10),
        _CompactHero(onBook: () => context.goNamed(RouteNames.services)),
        const SizedBox(height: 30),
        _InlineTitle(
          title: 'Servicios de firma',
          action: 'Ver todos',
          onAction: () => context.goNamed(RouteNames.services),
        ),
        const SizedBox(height: 14),
        if (shown.isEmpty)
          const _EmptyPanel()
        else
          ...shown.map(
            (Service service) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _PremiumServiceCard(
                service: service,
                compact: true,
                onTap: () => context.goNamed(RouteNames.services),
              ),
            ),
          ),
        const SizedBox(height: 18),
        _QuickActions(),
        const SizedBox(height: 28),
        _GoldCta(
          compact: true,
          onBook: () => context.goNamed(RouteNames.services),
        ),
      ],
    );
  }
}

class _TopNav extends StatelessWidget {
  const _TopNav({required this.user, required this.onBook});

  final User? user;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
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
                _NavLink(label: 'Servicios', onTap: onBook),
                _NavLink(label: 'Galeria', onTap: onBook),
                _NavLink(label: 'Barberos', onTap: onBook),
                _NavLink(label: 'Membership', onTap: onBook),
                const SizedBox(width: 42),
                _GoldButton(label: 'RESERVAR CITA', onTap: onBook),
                if (user?.role == UserRole.admin) ...<Widget>[
                  const SizedBox(width: 12),
                  IconButton(
                    tooltip: 'Admin',
                    color: Colors.white,
                    onPressed: () => context.pushNamed(RouteNames.admin),
                    icon: const Icon(Icons.admin_panel_settings),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.onBook, required this.onServices});

  final VoidCallback onBook;
  final VoidCallback onServices;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 620),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(_patternAsset),
          fit: BoxFit.cover,
          opacity: 0.22,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              Colors.black.withValues(alpha: 0.65),
              _ink.withValues(alpha: 0.9),
            ],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 80, 32, 92),
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: 9,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          'Maestria en cada corte,\nestilo en cada detalle',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 56,
                            height: 1.02,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 22),
                        const SizedBox(
                          width: 560,
                          child: Text(
                            'Redefinimos la experiencia del cuidado masculino con tecnicas tradicionales, ambiente sobrio y una reserva digital simple.',
                            style: TextStyle(
                              color: Color(0xFFD6D6D0),
                              fontSize: 17,
                              height: 1.7,
                            ),
                          ),
                        ),
                        const SizedBox(height: 34),
                        Row(
                          children: <Widget>[
                            _GoldButton(label: 'RESERVAR CITA', onTap: onBook),
                            const SizedBox(width: 14),
                            _OutlineGoldButton(
                              label: 'NUESTROS SERVICIOS',
                              onTap: onServices,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 54),
                  const Expanded(flex: 7, child: _HeroShowcase()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroShowcase extends StatelessWidget {
  const _HeroShowcase();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.82,
      child: Container(
        decoration: BoxDecoration(
          color: _panel,
          border: Border.all(color: _line),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Image.asset(
              _patternAsset,
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.38),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 34,
              right: 34,
              bottom: 34,
              child: Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: _ink.withValues(alpha: 0.92),
                  border: Border.all(color: _line),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            'Tu estilo Gentleman',
                            style: GoogleFonts.playfairDisplay(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Precision cut & grooming',
                            style: TextStyle(color: _muted, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.content_cut, color: _gold, size: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactHero extends StatelessWidget {
  const _CompactHero({required this.onBook});

  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _panel,
        border: Border.all(color: _line),
        image: const DecorationImage(
          image: AssetImage(_patternAsset),
          fit: BoxFit.cover,
          opacity: 0.14,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Maestria en cada corte',
            style: GoogleFonts.playfairDisplay(
              fontSize: 32,
              height: 1.05,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Reserva una experiencia premium de barberia.',
            style: TextStyle(color: _muted, height: 1.5),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: _GoldButton(label: 'RESERVAR AHORA', onTap: onBook),
          ),
        ],
      ),
    );
  }
}

class _SectionShell extends StatelessWidget {
  const _SectionShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF151817),
        image: DecorationImage(
          image: AssetImage(_patternAsset),
          repeat: ImageRepeat.repeat,
          opacity: 0.05,
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 78),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.playfairDisplay(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(width: 44, height: 3, color: _gold),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: 16),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 15),
          ),
        ],
      ],
    );
  }
}

class _PremiumServiceCard extends StatelessWidget {
  const _PremiumServiceCard({
    required this.service,
    required this.onTap,
    this.compact = false,
  });

  final Service service;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final String price = NumberFormat.currency(
      name: 'GTQ',
      symbol: 'Q',
    ).format(service.price);

    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: compact ? 134 : 232),
        padding: EdgeInsets.all(compact ? 18 : 28),
        decoration: BoxDecoration(
          color: _panelAlt,
          border: Border.all(color: _line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: compact ? 38 : 48,
              height: compact ? 38 : 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.22),
              ),
              child: const Icon(Icons.content_cut, color: _gold),
            ),
            SizedBox(height: compact ? 18 : 36),
            Text(
              service.name,
              maxLines: compact ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontSize: compact ? 22 : 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              service.extendedDescription ??
                  'Servicio de precision adaptado a tu estilo.',
              maxLines: compact ? 2 : 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _muted, height: 1.5),
            ),
            SizedBox(height: compact ? 18 : 32),
            Row(
              children: <Widget>[
                Text(
                  price,
                  style: const TextStyle(
                    color: _gold,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  '${service.durationMinutes} MIN',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GallerySection extends StatelessWidget {
  const _GallerySection({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _ink,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 84),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Galeria de Estilos',
                            style: GoogleFonts.playfairDisplay(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Inspiracion para cortes clasicos, modernos y ejecutivos.',
                            style: TextStyle(color: _muted),
                          ),
                        ],
                      ),
                    ),
                    _OutlineGoldButton(
                      label: 'VER PORTAFOLIO COMPLETO',
                      onTap: onOpen,
                    ),
                  ],
                ),
                const SizedBox(height: 38),
                Row(
                  children: List<Widget>.generate(
                    4,
                    (int index) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: index == 3 ? 0 : 18),
                        child: _StyleTile(index: index),
                      ),
                    ),
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

class _StyleTile extends StatelessWidget {
  const _StyleTile({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final List<String> labels = <String>[
      'Modern Fade',
      'Pompadour',
      'Executive',
      'Classic Beard',
    ];

    return AspectRatio(
      aspectRatio: 0.78,
      child: Container(
        decoration: BoxDecoration(
          color: _panel,
          border: Border.all(color: _line),
          image: const DecorationImage(
            image: AssetImage(_patternAsset),
            fit: BoxFit.cover,
            opacity: 0.18,
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.88),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Text(
                labels[index],
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WhySection extends StatelessWidget {
  const _WhySection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1D1B),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 78),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _InfoPanel(
                    title: 'Profesionalismo Incomparable',
                    body:
                        'Barberos expertos, atencion puntual y acabados pensados para tu rostro y rutina.',
                    icon: Icons.workspace_premium,
                    large: true,
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: <Widget>[
                      _InfoPanel(
                        title: 'Atmosfera premium',
                        body:
                            'Un espacio sobrio para esperar, elegir y salir listo.',
                        icon: Icons.emoji_events_outlined,
                      ),
                      SizedBox(height: 20),
                      _InfoPanel(
                        title: 'Productos de elite',
                        body:
                            'Cuidado con formulas profesionales para cabello y barba.',
                        icon: Icons.inventory_2_outlined,
                      ),
                    ],
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

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.title,
    required this.body,
    required this.icon,
    this.large = false,
  });

  final String title;
  final String body;
  final IconData icon;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: large ? 250 : 115),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: _panel,
        border: Border.all(color: _line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Icon(icon, color: _gold, size: large ? 34 : 26),
          const SizedBox(width: 22),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: large ? 24 : 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(body, style: const TextStyle(color: _muted, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldCta extends StatelessWidget {
  const _GoldCta({required this.onBook, this.compact = false});

  final VoidCallback onBook;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _gold,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 24 : 32,
        vertical: compact ? 36 : 78,
      ),
      child: Column(
        children: <Widget>[
          Text(
            'Listo para elevar tu estilo?',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              color: Colors.black,
              fontSize: compact ? 30 : 42,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Agenda tu cita hoy mismo y reserva tu experiencia.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF40360B)),
          ),
          const SizedBox(height: 28),
          _DarkButton(label: 'RESERVAR AHORA', onTap: onBook),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _QuickAction(
            icon: Icons.calendar_month,
            label: 'Mis citas',
            onTap: () => context.goNamed(RouteNames.myBookings),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickAction(
            icon: Icons.person_outline,
            label: 'Perfil',
            onTap: () => context.goNamed(RouteNames.profile),
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: _panel,
          border: Border.all(color: _line),
        ),
        child: Column(
          children: <Widget>[
            Icon(icon, color: _gold),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineTitle extends StatelessWidget {
  const _InlineTitle({
    required this.title,
    required this.action,
    required this.onAction,
  });

  final String title;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextButton(
          onPressed: onAction,
          child: Text(
            action.toUpperCase(),
            style: const TextStyle(color: _gold, fontSize: 12),
          ),
        ),
      ],
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
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          letterSpacing: 1.6,
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
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DarkButton extends StatelessWidget {
  const _DarkButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: _gold,
        shape: const RoundedRectangleBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 18),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          letterSpacing: 1.8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _panel,
        border: Border.all(color: _line),
      ),
      child: const Text(
        'Aun no hay servicios publicados.',
        textAlign: TextAlign.center,
        style: TextStyle(color: _muted),
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
        color: Color(0xFF0B0F0E),
        border: Border(top: BorderSide(color: _line)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 42),
            child: Row(
              children: <Widget>[
                Text(
                  "THE GENTLEMAN'S LOUNGE",
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                const Text(
                  'PRIVACY POLICY     TERMS OF SERVICE     CAREERS     CONTACT',
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
