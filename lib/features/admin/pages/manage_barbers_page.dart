import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:barberia/features/barber/models/barber.dart';
import 'package:barberia/features/barber/providers/barber_providers.dart';
import 'package:barberia/features/booking/models/booking.dart';
import 'package:barberia/features/booking/providers/booking_providers.dart';

// ─── Admin dark palette ───────────────────────────────────────────────────────
const Color _kBg = Color(0xFF0B0B0B);
const Color _kCard = Color(0xFF1A1A1A);
const Color _kBorder = Color(0xFF2A2A2A);
const Color _kGold = Color(0xFFD4AF37);
const Color _kWhite = Color(0xFFFFFFFF);
const Color _kGray = Color(0xFF888888);
const Color _kGreen = Color(0xFF22C55E);
const Color _kOrange = Color(0xFFF59E0B);

class ManageBarbersPage extends ConsumerWidget {
  const ManageBarbersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Barber>> barbersAsync = ref.watch(
      allBarbersStreamProvider,
    );
    final List<Booking> bookings = ref.watch(bookingsProvider);

    // Weekly performance stats
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final weekBookings = bookings
        .where(
          (b) =>
              b.startAt.isAfter(weekStart) &&
              b.status != BookingStatus.canceled,
        )
        .toList();
    final doneBookings = weekBookings
        .where(
          (b) =>
              b.status == BookingStatus.done ||
              b.status == BookingStatus.confirmed,
        )
        .toList();
    final satisfaction = weekBookings.isEmpty
        ? 0
        : ((doneBookings.length / weekBookings.length) * 100).round();

    return Scaffold(
      backgroundColor: _kBg,
      body: barbersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: _kGold),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(color: _kGray)),
        ),
        data: (barbers) => CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'STAFF MANAGEMENT',
                            style: TextStyle(
                              color: _kGold,
                              fontSize: 10,
                              letterSpacing: 2.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Our Barbers',
                            style: TextStyle(
                              color: _kWhite,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      _AddNewButton(
                        onTap: () => _showInviteDialog(context, ref),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (barbers.isEmpty)
              const SliverFillRemaining(child: _EmptyState())
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                sliver: SliverList.separated(
                  itemCount: barbers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (ctx, i) => _BarberCard(
                    barber: barbers[i],
                    bookings: bookings,
                    onEdit: () => _showEditDialog(context, ref, barbers[i]),
                    onDelete: () =>
                        _confirmDelete(context, ref, barbers[i]),
                    onToggle: (val) async {
                      try {
                        await ref
                            .read(barberRepositoryProvider)
                            .setAvailability(
                              id: barbers[i].id,
                              available: val,
                            );
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
                  ),
                ),
              ),
              // Performance overview
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: _PerformanceOverview(
                    satisfaction: satisfaction,
                    weeklyCount: weekBookings.length,
                    activeStaff: barbers
                        .where((b) => b.inviteStatus != 'pending')
                        .length,
                  ),
                ),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

// ─── Add New button ───────────────────────────────────────────────────────────

class _AddNewButton extends StatelessWidget {
  const _AddNewButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: _kGold),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_add_outlined, color: _kGold, size: 16),
            SizedBox(width: 8),
            Text(
              'Add New',
              style: TextStyle(
                color: _kGold,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Barber card ──────────────────────────────────────────────────────────────

class _BarberCard extends StatelessWidget {
  const _BarberCard({
    required this.barber,
    required this.bookings,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  final Barber barber;
  final List<Booking> bookings;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(bool) onToggle;

  @override
  Widget build(BuildContext context) {
    final bool isPending = barber.inviteStatus == 'pending';
    final bool inSession = bookings.any(
      (b) =>
          b.barberId == barber.id && b.status == BookingStatus.inProgress,
    );
    final nextList = bookings
        .where(
          (b) =>
              b.barberId == barber.id &&
              b.startAt.isAfter(DateTime.now()) &&
              b.status != BookingStatus.canceled,
        )
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));

    Color statusColor;
    String statusText;
    if (!barber.isAvailable) {
      statusColor = _kGray;
      statusText = 'Off-duty';
    } else if (inSession) {
      statusColor = _kOrange;
      final suffix = nextList.isEmpty
          ? ''
          : ' (Next: ${DateFormat('h:mm a').format(nextList.first.startAt)})';
      statusText = 'Busy$suffix';
    } else {
      statusColor = _kGreen;
      statusText = 'Available';
    }

    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: barber.photoUrl != null &&
                          barber.photoUrl!.isNotEmpty
                      ? Image.network(
                          barber.photoUrl!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _PhotoPlaceholder(name: barber.name),
                        )
                      : _PhotoPlaceholder(name: barber.name),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              barber.name,
                              style: const TextStyle(
                                color: _kWhite,
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _LevelBadge(isPending: isPending),
                        ],
                      ),
                      if (barber.specialty != null &&
                          barber.specialty!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          barber.specialty!,
                          style: const TextStyle(
                            color: _kGray,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (isPending && barber.inviteEmail != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.email_outlined,
                              size: 11,
                              color: _kGray,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                barber.inviteEmail!,
                                style: const TextStyle(
                                  color: _kGray,
                                  fontSize: 10,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Availability toggle
                if (!isPending)
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: barber.isAvailable,
                      activeThumbColor: _kGold,
                      inactiveThumbColor: _kGray,
                      inactiveTrackColor: const Color(0xFF2A2A2A),
                      onChanged: onToggle,
                    ),
                  ),
              ],
            ),
          ),
          // Bottom row: quote + actions
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: _kBorder, width: 0.5),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                if (barber.specialty != null &&
                    barber.specialty!.isNotEmpty)
                  Flexible(
                    child: Text(
                      '"${barber.specialty}"',
                      style: const TextStyle(
                        color: Color(0xFF555555),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const Spacer(),
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFF555555),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 14),
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: _kGold),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Edit Profile',
                      style: TextStyle(
                        color: _kGold,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Level badge ──────────────────────────────────────────────────────────────

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.isPending});

  final bool isPending;

  @override
  Widget build(BuildContext context) {
    if (isPending) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.amber.shade600, width: 0.7),
        ),
        child: Text(
          'PENDING',
          style: TextStyle(
            color: Colors.amber.shade700,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _kGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _kGold.withValues(alpha: 0.4), width: 0.7),
      ),
      child: const Text(
        'BARBER',
        style: TextStyle(
          color: _kGold,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── Photo placeholder ────────────────────────────────────────────────────────

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      color: const Color(0xFF2A2A2A),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: _kGold,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ─── Performance overview ─────────────────────────────────────────────────────

class _PerformanceOverview extends StatelessWidget {
  const _PerformanceOverview({
    required this.satisfaction,
    required this.weeklyCount,
    required this.activeStaff,
  });

  final int satisfaction;
  final int weeklyCount;
  final int activeStaff;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141410),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kGold.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          const Text(
            'Performance Overview',
            style: TextStyle(
              color: _kGold,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _PerfStat(value: '$satisfaction%', label: 'SATISFACTION'),
              _PerfStat(value: '$weeklyCount', label: 'WEEKLY\nBOOKINGS'),
              _PerfStat(value: '$activeStaff', label: 'ACTIVE\nSTAFF'),
            ],
          ),
        ],
      ),
    );
  }
}

class _PerfStat extends StatelessWidget {
  const _PerfStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: _kWhite,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: _kGray,
              fontSize: 9,
              letterSpacing: 1,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Color(0xFF1A1A1A),
            child: Icon(Icons.people_outline, size: 40, color: _kGray),
          ),
          SizedBox(height: 20),
          Text(
            'No barbers yet',
            style: TextStyle(color: _kGray, fontSize: 14),
          ),
          SizedBox(height: 8),
          Text(
            'Invite your first barber to get started',
            style: TextStyle(color: Color(0xFF555555), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ─── Dialogs ──────────────────────────────────────────────────────────────────

void _showInviteDialog(BuildContext context, WidgetRef ref) {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final specialtyCtrl = TextEditingController();
  bool loading = false;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Invite Barber',
          style: TextStyle(color: _kWhite),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DarkField(
                controller: nameCtrl,
                label: 'Name *',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 12),
              _DarkField(
                controller: emailCtrl,
                label: 'Email *',
                icon: Icons.email_outlined,
                keyboard: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _DarkField(
                controller: specialtyCtrl,
                label: 'Specialty',
                icon: Icons.content_cut_outlined,
              ),
              const SizedBox(height: 12),
              const Text(
                'The barber will receive an email to activate their account.',
                style: TextStyle(color: _kGray, fontSize: 11),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: loading ? null : () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: _kGray)),
          ),
          ElevatedButton(
            onPressed: loading
                ? null
                : () async {
                    final name = nameCtrl.text.trim();
                    final email = emailCtrl.text.trim();
                    if (name.isEmpty || email.isEmpty) return;
                    setState(() => loading = true);
                    try {
                      await ref
                          .read(barberAdminServiceProvider)
                          .inviteBarber(
                            name: name,
                            email: email,
                            specialty: specialtyCtrl.text.trim().isEmpty
                                ? null
                                : specialtyCtrl.text.trim(),
                          );
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Invitation sent!'),
                          ),
                        );
                      }
                    } catch (e) {
                      setState(() => loading = false);
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kGold,
              foregroundColor: const Color(0xFF0B0B0B),
            ),
            child: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Send Invite',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
        ],
      ),
    ),
  );
}

void _showEditDialog(BuildContext context, WidgetRef ref, Barber barber) {
  final nameCtrl = TextEditingController(text: barber.name);
  final specialtyCtrl = TextEditingController(
    text: barber.specialty ?? '',
  );

  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: const Text(
        'Edit Profile',
        style: TextStyle(color: _kWhite),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DarkField(
            controller: nameCtrl,
            label: 'Name',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 12),
          _DarkField(
            controller: specialtyCtrl,
            label: 'Specialty',
            icon: Icons.content_cut_outlined,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel', style: TextStyle(color: _kGray)),
        ),
        ElevatedButton(
          onPressed: () async {
            final name = nameCtrl.text.trim();
            if (name.isEmpty) return;
            try {
              await ref.read(barberRepositoryProvider).upsert(
                barber.copyWith(
                  name: name,
                  specialty: specialtyCtrl.text.trim().isEmpty
                      ? null
                      : specialtyCtrl.text.trim(),
                ),
              );
              if (ctx.mounted) Navigator.pop(ctx);
            } catch (e) {
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _kGold,
            foregroundColor: const Color(0xFF0B0B0B),
          ),
          child: const Text(
            'Save',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

void _confirmDelete(BuildContext context, WidgetRef ref, Barber barber) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: const Text(
        'Remove Barber?',
        style: TextStyle(color: _kWhite),
      ),
      content: Text(
        'This will remove ${barber.name} and revoke their access. This cannot be undone.',
        style: const TextStyle(color: _kGray),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel', style: TextStyle(color: _kGray)),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(ctx);
            try {
              await ref
                  .read(barberAdminServiceProvider)
                  .removeBarber(barber.id);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            }
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Remove'),
        ),
      ],
    ),
  );
}

// ─── Dark text field ──────────────────────────────────────────────────────────

class _DarkField extends StatelessWidget {
  const _DarkField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboard = TextInputType.text,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboard;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      style: const TextStyle(color: _kWhite),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _kGray),
        prefixIcon: Icon(icon, color: _kGray, size: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kGold),
        ),
        filled: true,
        fillColor: const Color(0xFF111111),
      ),
    );
  }
}
