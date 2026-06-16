import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const Color _kNavBg = Color(0xFF111111);
const Color _kGold = Color(0xFFD4AF37);
const Color _kUnselected = Color(0xFF505050);
const Color _kTopBorder = Color(0xFF2A2A2A);

class AdminScaffold extends StatelessWidget {
  const AdminScaffold({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      body: navigationShell,
      bottomNavigationBar: _AdminBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (int idx) => navigationShell.goBranch(
          idx,
          initialLocation: idx == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

class _AdminBottomNav extends StatelessWidget {
  const _AdminBottomNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final void Function(int) onTap;

  static const List<(IconData, String)> _tabs = [
    (Icons.grid_view_rounded, 'Dashboard'),
    (Icons.calendar_month_outlined, 'Bookings'),
    (Icons.content_cut_outlined, 'Barbers'),
    (Icons.settings_outlined, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kNavBg,
        border: Border(top: BorderSide(color: _kTopBorder, width: 0.5)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_tabs.length, (idx) {
              final (icon, label) = _tabs[idx];
              final bool sel = idx == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(idx),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: sel ? _kGold : _kUnselected, size: 22),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          color: sel ? _kGold : _kUnselected,
                          fontSize: 10,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
