import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';

class SidebarDrawer extends ConsumerWidget {
  const SidebarDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String location = GoRouterState.of(context).uri.path;

    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.inventory_2_rounded,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'ERPNext',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _NavTile(
                icon: Icons.inventory_2_rounded,
                title: 'Items',
                selected: location.startsWith('/items'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/items');
                },
              ),
              _NavTile(
                icon: Icons.people_alt_outlined,
                title: 'Users',
                selected: location.startsWith('/users'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/users');
                },
              ),
              const Spacer(),
              _NavTile(
                icon: Icons.logout_rounded,
                title: 'Logout',
                selected: false,
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(authControllerProvider.notifier).logout();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color selectedColor = Theme.of(context).colorScheme.primary;
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Icon(icon, color: selected ? selectedColor : null),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: selected ? selectedColor : null,
        ),
      ),
      selected: selected,
      selectedTileColor: selectedColor.withValues(alpha: 0.1),
      onTap: onTap,
    );
  }
}
