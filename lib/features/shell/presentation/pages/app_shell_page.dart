import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/sidebar_drawer.dart';

class AppShellPage extends StatelessWidget {
  const AppShellPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    final int currentIndex = _currentIndex(location);
    return Scaffold(
      drawer: const SidebarDrawer(),
      body: SafeArea(child: child),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        selectedItemColor: const Color(0xFF0A6772),
        unselectedItemColor: const Color(0xFF8A96A3),
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
