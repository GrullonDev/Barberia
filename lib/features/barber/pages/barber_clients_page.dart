import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:barberia/features/auth/models/user.dart';
import 'package:barberia/features/auth/providers/auth_providers.dart';
import 'package:barberia/features/barber/widgets/barber_chrome.dart';
import 'package:barberia/features/booking/models/booking.dart';
import 'package:barberia/features/booking/providers/booking_providers.dart';

const Color _kBg = Color(0xFF0B0B0B);
const Color _kSurface = Color(0xFF191B1B);
const Color _kSurface2 = Color(0xFF262828);
const Color _kGold = Color(0xFFD4AF37);
const Color _kText = Color(0xFFFFFFFF);
const Color _kMuted = Color(0xFFC6C6C6);
const Color _kDim = Color(0xFF8B8B8B);
const Color _kBorder = Color(0xFF3A3A3A);

class BarberClientsPage extends ConsumerStatefulWidget {
  const BarberClientsPage({super.key});

  @override
  ConsumerState<BarberClientsPage> createState() => _BarberClientsPageState();
}

class _BarberClientsPageState extends ConsumerState<BarberClientsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _filter = 'All Clients';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final User? user = ref.watch(authStateProvider);
    final List<Booking> bookings = ref.watch(bookingsProvider);

    if (user == null) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(child: CircularProgressIndicator(color: _kGold)),
      );
    }

    final List<_ClientSummary> clients = _summaries(bookings, user.id)
      ..sort((a, b) => b.lastVisit.compareTo(a.lastVisit));
    final List<_ClientSummary> filtered = clients.where((client) {
      final bool matchesQuery =
          _query.isEmpty || client.name.toLowerCase().contains(_query);
      final bool matchesFilter = switch (_filter) {
        'VIPs' => client.totalSpent >= 750,
        'Inactive' => DateTime.now().difference(client.lastVisit).inDays > 45,
        'Last 30' => DateTime.now().difference(client.lastVisit).inDays <= 30,
        _ => true,
      };
      return matchesQuery && matchesFilter;
    }).toList();

    final double avgRevenue = clients.isEmpty
        ? 0
        : clients.fold(
                0.0,
                (double sum, _ClientSummary c) => sum + c.totalSpent,
              ) /
              clients.length;

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: BarberTopBar(
                name: user.name,
                photoUrl: user.photoUrl,
                centerBrand: true,
                menuLabel: 'menu',
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 96),
              sliver: SliverList(
                delegate: SliverChildListDelegate(<Widget>[
                  TextField(
                    controller: _searchController,
                    onChanged: (String value) => setState(() {
                      _query = value.trim().toLowerCase();
                    }),
                    style: const TextStyle(color: _kText, fontSize: 20),
                    decoration: InputDecoration(
                      hintText: 'Search clients...',
                      hintStyle: const TextStyle(color: _kDim),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: _kMuted,
                        size: 32,
                      ),
                      filled: true,
                      fillColor: _kBg,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 24,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(2),
                        borderSide: const BorderSide(color: _kBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(2),
                        borderSide: const BorderSide(color: _kGold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  _FilterStrip(
                    selected: _filter,
                    onSelected: (String value) => setState(() {
                      _filter = value;
                    }),
                  ),
                  const SizedBox(height: 42),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _MetricCard(
                          label: 'TOTAL CLIENTS',
                          value: NumberFormat('#,##0').format(clients.length),
                        ),
                      ),
                      const SizedBox(width: 22),
                      Expanded(
                        child: _MetricCard(
                          label: 'AVG REVENUE',
                          value: '\$${avgRevenue.toStringAsFixed(2)}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 42),
                  if (filtered.isEmpty)
                    const _EmptyClients()
                  else
                    ...filtered.map(
                      (_ClientSummary client) => Padding(
                        padding: const EdgeInsets.only(bottom: 26),
                        child: _ClientCard(client: client),
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

  List<_ClientSummary> _summaries(List<Booking> bookings, String barberId) {
    final Map<String, List<Booking>> grouped = <String, List<Booking>>{};
    for (final Booking booking in bookings) {
      if (booking.barberId != barberId ||
          booking.status == BookingStatus.canceled ||
          booking.customerName.trim().isEmpty) {
        continue;
      }
      final String key = booking.phoneNormalized?.isNotEmpty == true
          ? booking.phoneNormalized!
          : booking.customerName.trim().toLowerCase();
      grouped.putIfAbsent(key, () => <Booking>[]).add(booking);
    }

    return grouped.values.map((List<Booking> items) {
      items.sort((a, b) => b.startAt.compareTo(a.startAt));
      final Booking latest = items.first;
      final double totalSpent = items
          .where((Booking b) => b.status == BookingStatus.done)
          .fold(0.0, (double sum, Booking b) => sum + b.servicePrice);
      final Booking serviceSource = items.firstWhere(
        (Booking b) => b.status == BookingStatus.done,
        orElse: () => latest,
      );
      return _ClientSummary(
        name: latest.customerName,
        lastVisit: latest.startAt,
        service: serviceSource.serviceName,
        totalSpent: totalSpent,
        visits: items.length,
      );
    }).toList();
  }
}

class _FilterStrip extends StatelessWidget {
  const _FilterStrip({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  static const List<String> _filters = <String>[
    'All Clients',
    'VIPs',
    'Inactive',
    'Last 30',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (BuildContext context, int index) {
          final String filter = _filters[index];
          final bool active = filter == selected;
          return GestureDetector(
            onTap: () => onSelected(filter),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? _kGold : _kBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: active ? _kGold : _kBorder),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: active ? Colors.black : _kText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 138,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: _kMuted,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 18),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: _kGold,
                fontSize: 34,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({required this.client});

  final _ClientSummary client;

  @override
  Widget build(BuildContext context) {
    final bool premium = client.totalSpent >= 750;
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: _kSurface2,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _kBorder),
                ),
                child: Center(
                  child: Text(
                    client.name.isEmpty ? '?' : client.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: _kGold,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 26),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      client.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _kText,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Last Visit: ${DateFormat('MMM d, yyyy').format(client.lastVisit)}',
                      style: const TextStyle(
                        color: _kMuted,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (premium)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _kGold.withValues(alpha: 0.14),
                    border: Border.all(color: _kGold.withValues(alpha: 0.5)),
                  ),
                  child: const Text(
                    'PREMIUM',
                    style: TextStyle(
                      color: _kGold,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 28),
          const Divider(color: Color(0xFF303030)),
          const SizedBox(height: 22),
          Row(
            children: <Widget>[
              Expanded(
                child: _ClientFact(label: 'SERVICE', value: client.service),
              ),
              const SizedBox(width: 16),
              _ClientFact(
                label: 'TOTAL SPENT',
                value: '\$${client.totalSpent.toStringAsFixed(2)}',
                alignEnd: true,
                gold: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClientFact extends StatelessWidget {
  const _ClientFact({
    required this.label,
    required this.value,
    this.alignEnd = false,
    this.gold = false,
  });

  final String label;
  final String value;
  final bool alignEnd;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: _kMuted,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: gold ? _kGold : _kText,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _EmptyClients extends StatelessWidget {
  const _EmptyClients();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
      ),
      child: const Text(
        'No clients match this view.',
        style: TextStyle(color: _kMuted, fontSize: 16),
      ),
    );
  }
}

class _ClientSummary {
  const _ClientSummary({
    required this.name,
    required this.lastVisit,
    required this.service,
    required this.totalSpent,
    required this.visits,
  });

  final String name;
  final DateTime lastVisit;
  final String service;
  final double totalSpent;
  final int visits;
}
