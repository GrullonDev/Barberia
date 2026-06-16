import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barberia/features/auth/models/user.dart';
import 'package:barberia/features/auth/providers/auth_providers.dart';
import 'package:barberia/features/barber/models/barber.dart';
import 'package:barberia/features/barber/providers/barber_providers.dart';
import 'package:barberia/features/barber/widgets/barber_chrome.dart';

const Color _kBg = Color(0xFF0B0B0B);
const Color _kSurface = Color(0xFF181A1A);
const Color _kField = Color(0xFF202222);
const Color _kGold = Color(0xFFD4AF37);
const Color _kText = Color(0xFFFFFFFF);
const Color _kMuted = Color(0xFFC7C7C7);
const Color _kDim = Color(0xFF8A8A8A);
const Color _kBorder = Color(0xFF343737);

class BarberSettingsPage extends ConsumerStatefulWidget {
  const BarberSettingsPage({super.key});

  @override
  ConsumerState<BarberSettingsPage> createState() => _BarberSettingsPageState();
}

class _BarberSettingsPageState extends ConsumerState<BarberSettingsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final List<String> _specialties = <String>[
    'Skin Fade',
    'Hot Towel Shave',
    'Beard Sculpting',
  ];
  bool _pushNotifications = true;
  bool _emailUpdates = false;
  bool _seeded = false;

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final User? user = ref.watch(authStateProvider);
    final AsyncValue<Barber?> profile = ref.watch(currentBarberProfileProvider);

    if (user == null) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(child: CircularProgressIndicator(color: _kGold)),
      );
    }

    final Barber fallback = Barber(
      id: user.id,
      name: user.name.isEmpty ? 'Julian Vane' : user.name,
      title: 'Executive Manager & Senior Stylist',
      bio:
          'With over 15 years of experience in traditional barbering, specializes in precision scissor cuts and classic straight-razor shaves.',
      specialties: _specialties,
      workingHours: Barber.defaultWorkingHours(),
    );

    final Barber barber = profile.value ?? fallback;
    _seed(barber);

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: BarberTopBar(
                name: user.name,
                photoUrl: user.photoUrl,
                compact: true,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 96),
              sliver: SliverList(
                delegate: SliverChildListDelegate(<Widget>[
                  Text(
                    'Master Profile',
                    style: barberHeadingStyle(fontSize: 30),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Configure your professional presence and availability.',
                    style: TextStyle(color: _kMuted, fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 30),
                  _Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Stack(
                              clipBehavior: Clip.none,
                              children: <Widget>[
                                Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: _kGold),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _nameController.text.isEmpty
                                          ? '?'
                                          : _nameController.text[0]
                                                .toUpperCase(),
                                      style: const TextStyle(
                                        color: _kGold,
                                        fontSize: 30,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: -8,
                                  bottom: -8,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: _kGold,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      color: Colors.black,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  TextField(
                                    controller: _nameController,
                                    style: const TextStyle(
                                      color: _kGold,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                    decoration: const InputDecoration.collapsed(
                                      hintText: 'Name',
                                      hintStyle: TextStyle(color: _kGold),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: _titleController,
                                    style: const TextStyle(
                                      color: Color(0xFFC8A98A),
                                      fontSize: 13,
                                    ),
                                    decoration: const InputDecoration.collapsed(
                                      hintText: 'Title',
                                      hintStyle: TextStyle(color: _kDim),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    '* 4.9 (128 reviews)',
                                    style: TextStyle(
                                      color: _kGold,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          'PROFESSIONAL BIOGRAPHY',
                          style: TextStyle(
                            color: _kMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _bioController,
                          maxLines: 5,
                          style: const TextStyle(
                            color: _kText,
                            fontSize: 14,
                            height: 1.35,
                          ),
                          decoration: const InputDecoration(
                            filled: true,
                            fillColor: _kField,
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: _kBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: _kGold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  _Panel(
                    title: 'Specialties',
                    icon: Icons.content_cut,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        ..._specialties.map(
                          (String item) => InputChip(
                            label: Text(item),
                            onDeleted: () => setState(() {
                              _specialties.remove(item);
                            }),
                            backgroundColor: _kField,
                            deleteIconColor: _kGold,
                            labelStyle: const TextStyle(
                              color: _kGold,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                            side: const BorderSide(color: _kGold),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => setState(() {
                            _specialties.add('New Skill');
                          }),
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('Add New'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _kText,
                            side: const BorderSide(color: _kBorder),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const _Panel(
                    title: 'Languages',
                    icon: Icons.translate,
                    child: Column(
                      children: <Widget>[
                        _LanguageRow(language: 'English', level: 'NATIVE'),
                        Divider(color: Color(0xFF282B2B)),
                        _LanguageRow(language: 'Italian', level: 'FLUENT'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const _Panel(
                    title: 'Availability',
                    icon: Icons.calendar_month,
                    child: Column(
                      children: <Widget>[
                        _AvailabilityRow(day: 'Mon', enabled: true),
                        SizedBox(height: 14),
                        _AvailabilityRow(day: 'Tue', enabled: true),
                        SizedBox(height: 14),
                        _AvailabilityRow(day: 'Sun', enabled: false),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _Panel(
                    title: 'Notifications',
                    child: Column(
                      children: <Widget>[
                        _SwitchRow(
                          title: 'Push Notifications',
                          subtitle: 'New bookings and reminders',
                          value: _pushNotifications,
                          onChanged: (bool value) => setState(() {
                            _pushNotifications = value;
                          }),
                        ),
                        const SizedBox(height: 20),
                        _SwitchRow(
                          title: 'Email Updates',
                          subtitle: 'Daily schedule and revenue reports',
                          value: _emailUpdates,
                          onChanged: (bool value) => setState(() {
                            _emailUpdates = value;
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kGold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      onPressed: () => _save(barber),
                      child: const Text(
                        'SAVE CHANGES',
                        style: TextStyle(letterSpacing: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 54,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFFB8AD),
                        side: const BorderSide(color: Color(0xFFFFB8AD)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      onPressed: () =>
                          ref.read(authStateProvider.notifier).logout(),
                      child: const Text(
                        'LOGOUT',
                        style: TextStyle(letterSpacing: 2),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _seed(Barber barber) {
    if (_seeded) {
      return;
    }
    _nameController.text = barber.name;
    _titleController.text =
        barber.title ?? 'Executive Manager & Senior Stylist';
    _bioController.text =
        barber.bio ??
        'With over 15 years of experience in traditional barbering, Julian specializes in precision scissor cuts and classic straight-razor shaves.';
    if (barber.specialties.isNotEmpty) {
      _specialties
        ..clear()
        ..addAll(barber.specialties);
    }
    _seeded = true;
  }

  Future<void> _save(Barber current) async {
    final Barber updated = current.copyWith(
      name: _nameController.text.trim(),
      title: _titleController.text.trim(),
      bio: _bioController.text.trim(),
      specialties: List<String>.from(_specialties),
    );
    try {
      await ref.read(barberRepositoryProvider).upsert(updated);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile updated')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save profile changes')),
        );
      }
    }
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.title, this.icon});

  final String? title;
  final IconData? icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (title != null) ...<Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(title!, style: barberHeadingStyle(fontSize: 24)),
                ),
                if (icon != null) Icon(icon, color: _kText),
              ],
            ),
            const SizedBox(height: 20),
          ],
          child,
        ],
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({required this.language, required this.level});

  final String language;
  final String level;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(language, style: const TextStyle(color: _kText)),
          ),
          Text(
            level,
            style: const TextStyle(
              color: _kGold,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityRow extends StatelessWidget {
  const _AvailabilityRow({required this.day, required this.enabled});

  final String day;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Checkbox(
          value: enabled,
          onChanged: null,
          activeColor: _kGold,
          checkColor: Colors.white,
          side: const BorderSide(color: _kBorder),
        ),
        SizedBox(
          width: 46,
          child: Text(
            day,
            style: TextStyle(
              color: enabled ? _kText : _kDim,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Spacer(),
        if (enabled) ...const <Widget>[
          _TimePill(label: '09:00 AM'),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('-', style: TextStyle(color: _kText)),
          ),
          _TimePill(label: '06:00 PM'),
        ] else
          const Text('Closed', style: TextStyle(color: Color(0xFFD8A09A))),
      ],
    );
  }
}

class _TimePill extends StatelessWidget {
  const _TimePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      color: _kField,
      child: Text(label, style: const TextStyle(color: _kText, fontSize: 11)),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: const TextStyle(color: _kText, fontSize: 15)),
              Text(
                subtitle,
                style: const TextStyle(color: _kMuted, fontSize: 11),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: Colors.white,
          activeTrackColor: _kGold,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: _kBorder,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
