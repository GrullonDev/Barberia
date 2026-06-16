import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:barberia/app/router.dart';
import 'package:barberia/features/auth/providers/auth_providers.dart';
import 'package:barberia/features/booking/models/service.dart';
import 'package:barberia/features/booking/providers/booking_providers.dart';
import 'package:barberia/features/config/models/barberia_config.dart';
import 'package:barberia/features/config/providers/barberia_config_providers.dart';

// ─── Admin dark palette ───────────────────────────────────────────────────────
const Color _kBg = Color(0xFF0B0B0B);
const Color _kCard = Color(0xFF1A1A1A);
const Color _kBorder = Color(0xFF2A2A2A);
const Color _kGold = Color(0xFFD4AF37);
const Color _kWhite = Color(0xFFFFFFFF);
const Color _kGray = Color(0xFF888888);
const Color _kGreen = Color(0xFF22C55E);

class AdminSettingsPage extends ConsumerStatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  ConsumerState<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends ConsumerState<AdminSettingsPage> {
  bool _shopOpen = true;
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(barberiaConfigProvider);
    final servicesAsync = ref.watch(servicesAsyncProvider);

    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            backgroundColor: _kBg,
            automaticallyImplyLeading: false,
            pinned: true,
            toolbarHeight: 64,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            expandedHeight: 80,
            flexibleSpace: const FlexibleSpaceBar(
              background: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Settings',
                        style: TextStyle(
                          color: _kWhite,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Status toggles
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _ToggleCard(
                      label: 'SHOP STATUS',
                      value: _shopOpen ? 'OPEN' : 'CLOSED',
                      valueColor: _shopOpen ? _kGreen : _kGray,
                      toggled: _shopOpen,
                      onToggle: (v) => setState(() => _shopOpen = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ToggleCard(
                      label: 'NOTIFICATIONS',
                      value: _notifications ? 'ON' : 'OFF',
                      valueColor: _notifications ? _kGreen : _kGray,
                      toggled: _notifications,
                      onToggle: (v) => setState(() => _notifications = v),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Business Info
          SliverToBoxAdapter(
            child: configAsync.when(
              data: (config) => _BusinessInfoSection(config: config),
              loading: () =>
                  const _SectionSkeleton(label: 'BUSINESS INFO'),
              error: (e, _) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Text(
                  'Error loading config: $e',
                  style: const TextStyle(color: _kGray),
                ),
              ),
            ),
          ),

          // Services
          SliverToBoxAdapter(
            child: servicesAsync.when(
              data: (services) => _ServicesSection(services: services),
              loading: () =>
                  const _SectionSkeleton(label: 'MANAGE SERVICES'),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // Operating Hours
          SliverToBoxAdapter(
            child: configAsync.when(
              data: (config) => _OperatingHoursSection(config: config),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // Delete account
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: GestureDetector(
                onTap: () => _confirmDelete(context, ref),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF2A2A2A)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'DELETE ACCOUNT',
                      style: TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Version
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Version 2.4.0 (Enterprise Edition)',
                  style: TextStyle(color: Color(0xFF555555), fontSize: 11),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Delete Account?',
          style: TextStyle(color: _kWhite),
        ),
        content: const Text(
          'This will permanently delete your account and all data. This cannot be undone.',
          style: TextStyle(color: _kGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: _kGray)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authStateProvider.notifier).logout();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─── Toggle card ──────────────────────────────────────────────────────────────

class _ToggleCard extends StatelessWidget {
  const _ToggleCard({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.toggled,
    required this.onToggle,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool toggled;
  final void Function(bool) onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _kGray,
              fontSize: 9,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Transform.scale(
                scale: 0.75,
                alignment: Alignment.centerRight,
                child: Switch(
                  value: toggled,
                  onChanged: onToggle,
                  activeThumbColor: _kGold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Business info section ────────────────────────────────────────────────────

class _BusinessInfoSection extends StatelessWidget {
  const _BusinessInfoSection({required this.config});

  final BarberiaConfig config;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'BUSINESS INFO',
                style: TextStyle(
                  color: _kWhite,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              GestureDetector(
                onTap: () => context.goNamed(RouteNames.adminConfig),
                child: const Text(
                  'Edit',
                  style: TextStyle(color: _kGold, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kBorder),
            ),
            child: Column(
              children: [
                _InfoRow('SHOP NAME', config.businessName),
                const _RowDivider(),
                _InfoRow('PHONE NUMBER', config.phone ?? 'Not set'),
                const _RowDivider(),
                _InfoRow(
                  'LOCATION',
                  config.address.isEmpty ? 'Not set' : config.address,
                ),
                if (config.landingBaseUrl != null &&
                    config.landingBaseUrl!.isNotEmpty) ...[
                  const _RowDivider(),
                  _InfoRow('WEBSITE', config.landingBaseUrl!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _kGray,
              fontSize: 9,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: _kWhite, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      color: Color(0xFF2A2A2A),
      height: 0.5,
      indent: 16,
      endIndent: 16,
    );
  }
}

// ─── Services section ─────────────────────────────────────────────────────────

class _ServicesSection extends StatelessWidget {
  const _ServicesSection({required this.services});

  final List<Service> services;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MANAGE SERVICES',
                style: TextStyle(
                  color: _kWhite,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              GestureDetector(
                onTap: () => context.goNamed(RouteNames.addService),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _kGold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Add New',
                    style: TextStyle(
                      color: Color(0xFF0B0B0B),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          services.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _kCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _kBorder),
                  ),
                  child: const Center(
                    child: Text(
                      'No services yet',
                      style: TextStyle(color: _kGray),
                    ),
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: _kCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _kBorder),
                  ),
                  child: ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: services.length,
                    separatorBuilder: (_, __) => const Divider(
                      color: Color(0xFF2A2A2A),
                      height: 0.5,
                      indent: 16,
                      endIndent: 16,
                    ),
                    itemBuilder: (ctx, i) {
                      final s = services[i];
                      return InkWell(
                        onTap: () =>
                            ctx.goNamed(RouteNames.addService, extra: s),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A2A2A),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.content_cut,
                                  color: _kGold,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.name,
                                      style: const TextStyle(
                                        color: _kWhite,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${s.durationMinutes} mins · ${s.category.name}',
                                      style: const TextStyle(
                                        color: _kGray,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '\$${s.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: _kWhite,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.chevron_right,
                                color: _kGray,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }
}

// ─── Operating hours section ──────────────────────────────────────────────────

class _OperatingHoursSection extends StatelessWidget {
  const _OperatingHoursSection({required this.config});

  final BarberiaConfig config;

  static const List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  String _fmtHour(int h) {
    final suffix = h < 12 ? 'AM' : 'PM';
    final h12 = h == 0 ? 12 : h > 12 ? h - 12 : h;
    return '${h12.toString().padLeft(2, '0')}:00 $suffix';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'OPERATING HOURS',
            style: TextStyle(
              color: _kWhite,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kBorder),
            ),
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: 7,
              separatorBuilder: (_, __) => const Divider(
                color: Color(0xFF2A2A2A),
                height: 0.5,
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (ctx, i) {
                final bool isWeekend = i >= 5;
                final bool isClosed = i == 6;
                final String hours = isClosed
                    ? 'CLOSED'
                    : '${_fmtHour(config.openHour)} - ${_fmtHour(config.closeHour)}';
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _days[i],
                        style: TextStyle(
                          color: isWeekend ? _kGold : _kWhite,
                          fontSize: 14,
                          fontWeight: isWeekend
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      Text(
                        hours,
                        style: TextStyle(
                          color: isClosed
                              ? Colors.redAccent
                              : isWeekend
                              ? _kGold
                              : _kGray,
                          fontSize: 13,
                          fontWeight: isWeekend
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section skeleton ─────────────────────────────────────────────────────────

class _SectionSkeleton extends StatelessWidget {
  const _SectionSkeleton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _kWhite,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kBorder),
            ),
          ),
        ],
      ),
    );
  }
}
