import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../widgets/sidebar_drawer.dart';

class AppShellPage extends StatelessWidget {
  const AppShellPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    final int currentIndex = _currentIndex(location);
    final ThemeData theme = Theme.of(context);
    final BcnThemePalette palette = theme.bcnPalette;
    return Scaffold(
      drawer: const SidebarDrawer(),
      body: SafeArea(child: child),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        backgroundColor: palette.navigation,
        selectedItemColor: palette.onNavigation,
        unselectedItemColor: palette.onNavigation.withValues(alpha: 0.62),
        selectedFontSize: 12,
        unselectedFontSize: 11,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        onTap: (int index) {
          switch (index) {
            case 0:
              context.go('/items');
              break;
            case 1:
              context.go('/items');
              break;
            case 2:
              context.go('/customers');
              break;
            case 3:
              context.go('/sales-invoices');
              break;
            case 4:
              context.go('/reports');
              break;
          }
        },
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2_rounded),
            label: 'Items',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_outlined),
            activeIcon: Icon(Icons.groups_rounded),
            label: 'Customers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long_rounded),
            label: 'Sales',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics_rounded),
            label: 'Report',
          ),
        ],
      ),
    );
  }

  int _currentIndex(String location) {
    if (location.startsWith('/customers')) {
      return 2;
    }
    if (location.startsWith('/sales-invoices')) {
      return 3;
    }
    if (location.startsWith('/reports')) {
      return 4;
    }
    if (location.startsWith('/items')) {
      return 1;
    }
    return 0;
  }
}
