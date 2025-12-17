import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({
    required this.navigationShell,
    required this.onFabPressed,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final VoidCallback onFabPressed;

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: size.width,
      height: 80,
      child: Stack(
        children: <Widget>[
          CustomPaint(
            size: Size(size.width, 80),
            painter: _BNBCustomPainter(
              color: isDark ? const Color(0xFF1E1F23) : cs.surface,
            ),
          ),
          Center(
            heightFactor: 0.6,
            child: FloatingActionButton(
              onPressed: onFabPressed,
              backgroundColor: cs.primary, // Use app primary color
              shape: const CircleBorder(),
              elevation: 4,
              child: Icon(Icons.add, color: cs.onPrimary, size: 28), // Add icon
            ),
          ),
          SizedBox(
            width: size.width,
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                _NavBarIcon(
                  icon: Icons.home_filled,
                  isSelected: navigationShell.currentIndex == 0,
                  onTap: () => _onTap(context, 0),
                  activeColor: cs.primary,
                ),
                _NavBarIcon(
                  icon: Icons.calendar_month, // Bookings
                  isSelected: navigationShell.currentIndex == 1,
                  onTap: () => _onTap(context, 1),
                  activeColor: cs.primary,
                ),
                SizedBox(width: size.width * 0.20), // Space for FAB
                _NavBarIcon(
                  icon: Icons.settings_outlined,
                  isSelected: navigationShell.currentIndex == 2,
                  onTap: () => _onTap(context, 2),
                  activeColor: cs.primary,
                ),
                _NavBarIcon(
                  icon: Icons.person_outline,
                  isSelected: navigationShell.currentIndex == 3,
                  onTap: () => _onTap(context, 3),
                  activeColor: cs.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBarIcon extends StatelessWidget {
  const _NavBarIcon({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.activeColor,
  });

  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 28),
          if (isSelected) ...<Widget>[
            const SizedBox(height: 4),
            Container(
              height: 3,
              width: 16,
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BNBCustomPainter extends CustomPainter {
  _BNBCustomPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final Path path = Path();
    path.moveTo(0, 0); // Start top left ? No, wait.

    // We want a curved shape.
    // 0,20 start
    path.moveTo(0, 20);
    path.quadraticBezierTo(size.width * 0.20, 0, size.width * 0.35, 0);
    path.quadraticBezierTo(size.width * 0.40, 0, size.width * 0.40, 20);
    path.arcToPoint(
      Offset(size.width * 0.60, 20),
      radius: const Radius.circular(10.0),
      clockwise: false,
    );
    path.quadraticBezierTo(size.width * 0.60, 0, size.width * 0.65, 0);
    path.quadraticBezierTo(size.width * 0.80, 0, size.width, 20);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Shadow?
    canvas.drawShadow(path, Colors.black, 5, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
