import 'package:barberia/app/router.dart';
import 'package:barberia/common/widgets/custom_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      body: navigationShell,
      extendBody: !isDesktop,
      bottomNavigationBar: isDesktop
          ? null
          : CustomBottomNavBar(
              navigationShell: navigationShell,
              onFabPressed: () => context.pushNamed(RouteNames.services),
            ),
    );
  }
}
