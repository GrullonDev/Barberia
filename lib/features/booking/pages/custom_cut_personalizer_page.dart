import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:barberia/app/router.dart';

const Color _ink = Color(0xFF101312);
const Color _inkDeep = Color(0xFF0B0F0E);
const Color _panel = Color(0xFF202221);
const Color _panelAlt = Color(0xFF282A29);
const Color _line = Color(0xFF3A3D39);
const Color _gold = Color(0xFFE8C84E);
const Color _muted = Color(0xFFC7C7C2);
const String _heroAsset = 'assets/images/style_pompadour.png';

class CustomCutPersonalizerPage extends StatefulWidget {
  const CustomCutPersonalizerPage({super.key});

  @override
  State<CustomCutPersonalizerPage> createState() =>
      _CustomCutPersonalizerPageState();
}

class _CustomCutPersonalizerPageState extends State<CustomCutPersonalizerPage> {
  int _baseIndex = 1;
  double _topLength = 3;
  String _fade = 'Mid Fade';
  String _beard = 'Clean Shaven';

  String get _style => _baseOptions[_baseIndex].label;

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
              SliverToBoxAdapter(
                child: _TopNav(onBook: _goToBooking, selected: null),
              ),
            SliverToBoxAdapter(
              child: _PersonalizerBody(
                compact: !isDesktop,
                baseIndex: _baseIndex,
                topLength: _topLength,
                fade: _fade,
                beard: _beard,
                style: _style,
                onBaseChanged: (int value) {
                  setState(() => _baseIndex = value);
                },
                onTopLengthChanged: (double value) {
                  setState(() => _topLength = value);
                },
                onFadeChanged: (String value) {
                  setState(() => _fade = value);
                },
                onBeardChanged: (String value) {
                  setState(() => _beard = value);
                },
                onConfirm: _goToBooking,
              ),
            ),
            SliverToBoxAdapter(child: _FeatureBand(compact: !isDesktop)),
            SliverToBoxAdapter(child: _Footer(compact: !isDesktop)),
          ],
        ),
      ),
    );
  }

  void _goToBooking() {
    context.goNamed(RouteNames.services);
  }
}

class _TopNav extends StatelessWidget {
  const _TopNav({required this.onBook, required this.selected});

  final VoidCallback onBook;
  final String? selected;

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
                _NavLink(
                  label: 'Services',
                  selected: selected == 'Services',
                  onTap: onBook,
                ),
                _NavLink(
                  label: 'Gallery',
                  selected: selected == 'Gallery',
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

class _PersonalizerBody extends StatelessWidget {
  const _PersonalizerBody({
    required this.compact,
    required this.baseIndex,
    required this.topLength,
    required this.fade,
    required this.beard,
    required this.style,
    required this.onBaseChanged,
    required this.onTopLengthChanged,
    required this.onFadeChanged,
    required this.onBeardChanged,
    required this.onConfirm,
  });

  final bool compact;
  final int baseIndex;
  final double topLength;
  final String fade;
  final String beard;
  final String style;
  final ValueChanged<int> onBaseChanged;
  final ValueChanged<double> onTopLengthChanged;
  final ValueChanged<String> onFadeChanged;
  final ValueChanged<String> onBeardChanged;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: _ink,
        gradient: LinearGradient(
          colors: <Color>[_ink, Color(0xFF151716), _ink],
          stops: <double>[0, 0.52, 1],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 18 : 32,
              compact ? 36 : 36,
              compact ? 18 : 32,
              compact ? 44 : 74,
            ),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _ControlsPanel(
                        compact: true,
                        baseIndex: baseIndex,
                        topLength: topLength,
                        fade: fade,
                        beard: beard,
                        onBaseChanged: onBaseChanged,
                        onTopLengthChanged: onTopLengthChanged,
                        onFadeChanged: onFadeChanged,
                        onBeardChanged: onBeardChanged,
                      ),
                      const SizedBox(height: 28),
                      _PreviewPanel(
                        compact: true,
                        style: style,
                        fade: fade,
                        beard: beard,
                        onConfirm: onConfirm,
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(
                        width: 500,
                        child: _ControlsPanel(
                          compact: false,
                          baseIndex: baseIndex,
                          topLength: topLength,
                          fade: fade,
                          beard: beard,
                          onBaseChanged: onBaseChanged,
                          onTopLengthChanged: onTopLengthChanged,
                          onFadeChanged: onFadeChanged,
                          onBeardChanged: onBeardChanged,
                        ),
                      ),
                      const SizedBox(width: 28),
                      Expanded(
                        child: _PreviewPanel(
                          compact: false,
                          style: style,
                          fade: fade,
                          beard: beard,
                          onConfirm: onConfirm,
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

class _ControlsPanel extends StatelessWidget {
  const _ControlsPanel({
    required this.compact,
    required this.baseIndex,
    required this.topLength,
    required this.fade,
    required this.beard,
    required this.onBaseChanged,
    required this.onTopLengthChanged,
    required this.onFadeChanged,
    required this.onBeardChanged,
  });

  final bool compact;
  final int baseIndex;
  final double topLength;
  final String fade;
  final String beard;
  final ValueChanged<int> onBaseChanged;
  final ValueChanged<double> onTopLengthChanged;
  final ValueChanged<String> onFadeChanged;
  final ValueChanged<String> onBeardChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Custom Cut\nPersonalizer',
          style: GoogleFonts.playfairDisplay(
            color: _gold,
            fontSize: compact ? 46 : 54,
            height: 1.08,
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
        const SizedBox(height: 16),
        const Text(
          'Define your legacy with a precision-tailored grooming experience. Select your signature elements below.',
          style: TextStyle(color: _muted, fontSize: 16, height: 1.65),
        ),
        const SizedBox(height: 34),
        const _SectionLabel('CHOOSE YOUR BASE'),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool tight = constraints.maxWidth < 450;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                for (int i = 0; i < _baseOptions.length; i++)
                  SizedBox(
                    width: tight
                        ? (constraints.maxWidth - 12) / 2
                        : (constraints.maxWidth - 24) / 3,
                    child: _BaseOptionTile(
                      option: _baseOptions[i],
                      selected: baseIndex == i,
                      onTap: () => onBaseChanged(i),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 26),
        _LengthControl(value: topLength, onChanged: onTopLengthChanged),
        const SizedBox(height: 26),
        const _SectionLabel('TIPO DE DEGRADADO'),
        const SizedBox(height: 16),
        for (final String option in _fadeOptions)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _FadeOption(
              label: option,
              selected: fade == option,
              onTap: () => onFadeChanged(option),
            ),
          ),
        const SizedBox(height: 8),
        const _SectionLabel('DETALLE DE BARBA'),
        const SizedBox(height: 16),
        _BeardDropdown(value: beard, onChanged: onBeardChanged),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        letterSpacing: 2.2,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _BaseOptionTile extends StatelessWidget {
  const _BaseOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _BaseOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 110,
        decoration: BoxDecoration(
          color: _panelAlt,
          border: Border.all(color: selected ? _gold : _line, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              option.icon,
              color: selected ? _gold : Colors.white70,
              size: 30,
            ),
            const SizedBox(height: 18),
            Text(
              option.label.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LengthControl extends StatelessWidget {
  const _LengthControl({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(26, 24, 26, 22),
      decoration: BoxDecoration(
        color: _panel.withValues(alpha: 0.86),
        border: Border.all(color: _line.withValues(alpha: 0.34)),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(child: _SectionLabel('LARGO DE ARRIBA')),
              Text(
                '${value.round()} cm',
                style: const TextStyle(
                  color: _gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _gold,
              inactiveTrackColor: Colors.white24,
              thumbColor: _gold,
              overlayColor: _gold.withValues(alpha: 0.14),
              trackHeight: 3,
            ),
            child: Slider(
              min: 1,
              max: 7,
              divisions: 6,
              value: value,
              onChanged: onChanged,
            ),
          ),
          const Row(
            children: <Widget>[
              Text(
                'Corto',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              Spacer(),
              Text(
                'Largo',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FadeOption extends StatelessWidget {
  const _FadeOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1B1E1D) : Colors.transparent,
          border: Border.all(color: _line),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? _gold : Colors.transparent,
                border: Border.all(color: _gold),
              ),
              child: selected
                  ? const Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: SizedBox(width: 6, height: 6),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _BeardDropdown extends StatelessWidget {
  const _BeardDropdown({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: _panelAlt,
        border: Border.all(color: _line),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: _panelAlt,
          iconEnabledColor: Colors.white54,
          isExpanded: true,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          items: _beardOptions
              .map(
                (String option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                ),
              )
              .toList(),
          onChanged: (String? option) {
            if (option != null) {
              onChanged(option);
            }
          },
        ),
      ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({
    required this.compact,
    required this.style,
    required this.fade,
    required this.beard,
    required this.onConfirm,
  });

  final bool compact;
  final String style;
  final String fade;
  final String beard;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 620 : 970,
      decoration: BoxDecoration(
        color: _inkDeep,
        border: Border.all(color: _line.withValues(alpha: 0.5)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(
            _heroAsset,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Colors.black.withValues(alpha: 0.18),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.78),
                ],
              ),
            ),
          ),
          Positioned(
            top: compact ? 22 : 34,
            right: compact ? 22 : 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                _SpecTag(label: 'STYLE', value: style),
                const SizedBox(height: 12),
                _SpecTag(label: 'FADE', value: fade),
              ],
            ),
          ),
          Positioned(
            left: compact ? 20 : 42,
            right: compact ? 20 : 42,
            bottom: compact ? 22 : 44,
            child: _SummaryPanel(
              compact: compact,
              beard: beard,
              onConfirm: onConfirm,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecTag extends StatelessWidget {
  const _SpecTag({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.fromLTRB(18, 12, 0, 12),
      decoration: BoxDecoration(color: _inkDeep.withValues(alpha: 0.82)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: const TextStyle(
              color: _gold,
              fontSize: 13,
              letterSpacing: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 18),
          Container(width: 2, height: 36, color: _gold),
        ],
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.compact,
    required this.beard,
    required this.onConfirm,
  });

  final bool compact;
  final String beard;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 24 : 34),
      decoration: BoxDecoration(
        color: _ink.withValues(alpha: 0.94),
        border: Border.all(color: _line),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _SummaryCopy(beard: beard),
                const SizedBox(height: 24),
                _GoldButton(label: 'CONFIRMAR Y AGENDAR', onTap: onConfirm),
              ],
            )
          : Row(
              children: <Widget>[
                Expanded(child: _SummaryCopy(beard: beard)),
                const SizedBox(width: 38),
                SizedBox(
                  width: 280,
                  child: _GoldButton(
                    label: 'CONFIRMAR Y AGENDAR',
                    onTap: onConfirm,
                  ),
                ),
              ],
            ),
    );
  }
}

class _SummaryCopy extends StatelessWidget {
  const _SummaryCopy({required this.beard});

  final String beard;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'Tu Estilo\nGentleman',
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontSize: 28,
            height: 1.05,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Signature Precision Cut &\n$beard Grooming',
          style: const TextStyle(color: _muted, fontSize: 16, height: 1.5),
        ),
      ],
    );
  }
}

class _FeatureBand extends StatelessWidget {
  const _FeatureBand({required this.compact});

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
              compact ? 26 : 30,
              compact ? 18 : 32,
              compact ? 48 : 54,
            ),
            child: compact
                ? const Column(
                    children: <Widget>[
                      _PrestigePanel(),
                      SizedBox(height: 16),
                      _InfoCard(
                        icon: Icons.schedule,
                        title: '45 MINUTOS',
                        body: 'Dedicacion completa',
                      ),
                      SizedBox(height: 16),
                      _InfoCard(
                        icon: Icons.local_cafe_outlined,
                        title: 'COMPLIMENTARY',
                        body: 'Single malt o cafe artesanal',
                      ),
                    ],
                  )
                : const Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Expanded(flex: 2, child: _PrestigePanel()),
                      SizedBox(width: 26),
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.schedule,
                          title: '45 MINUTOS',
                          body: 'Dedicacion completa',
                        ),
                      ),
                      SizedBox(width: 26),
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.local_cafe_outlined,
                          title: 'COMPLIMENTARY',
                          body: 'Single malt o cafe artesanal',
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

class _PrestigePanel extends StatelessWidget {
  const _PrestigePanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 268),
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: _panel,
        border: Border.all(color: _line),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            right: 0,
            top: 0,
            child: Icon(
              Icons.verified_outlined,
              color: Colors.white.withValues(alpha: 0.18),
              size: 58,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Text(
                'Prestigio & Precision',
                style: GoogleFonts.playfairDisplay(
                  color: _gold,
                  fontSize: 28,
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
              const SizedBox(height: 16),
              const Text(
                'Nuestros barberos maestros aseguran que cada milimetro de tu eleccion se ejecute con excelencia tecnica.',
                style: TextStyle(
                  color: Color(0xFFE3E3DF),
                  fontSize: 16,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 268),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _panel,
        border: Border.all(color: _line),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, color: _gold, size: 36),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFE3E3DF),
              fontSize: 16,
              height: 1.55,
            ),
          ),
        ],
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
              vertical: compact ? 34 : 50,
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
                      SizedBox(width: 34),
                      Text(
                        "© 2024 THE GENTLEMAN'S LOUNGE. ALL RIGHTS RESERVED.",
                        style: TextStyle(
                          color: Color(0xFF8D8D89),
                          fontSize: 11,
                          letterSpacing: 0.7,
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

class _FooterBrand extends StatelessWidget {
  const _FooterBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          "THE GENTLEMAN'S LOUNGE",
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Crafting Confidence Since 1924',
          style: TextStyle(color: Color(0xFFAAA9A4), fontSize: 16),
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
      'Privacy Policy      Terms of Service      Careers      Contact',
      style: TextStyle(color: Colors.white, fontSize: 12, letterSpacing: 0.7),
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
          fontSize: 13,
          letterSpacing: 3,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _BaseOption {
  const _BaseOption({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

const List<_BaseOption> _baseOptions = <_BaseOption>[
  _BaseOption(label: 'Classic', icon: Icons.history_toggle_off),
  _BaseOption(label: 'Modern', icon: Icons.wb_sunny_outlined),
  _BaseOption(label: 'Edgy', icon: Icons.content_cut),
];

const List<String> _fadeOptions = <String>['Low Fade', 'Mid Fade', 'High Fade'];

const List<String> _beardOptions = <String>[
  'Clean Shaven',
  'Short Beard',
  'Defined Beard',
  'Full Beard',
];
