import 'package:flutter/material.dart';

import '../widgets/sidebar_drawer.dart';

class AppShellPage extends StatelessWidget {
  const AppShellPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const SidebarDrawer(),
      body: SafeArea(child: child),
    );
  }
}
