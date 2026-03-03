import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../items/presentation/widgets/search_field.dart';
import '../../domain/entities/user_entity.dart';
import '../controllers/users_controller.dart';
import '../state/users_state.dart';

class UserListPage extends ConsumerStatefulWidget {
  const UserListPage({super.key});

  @override
  ConsumerState<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends ConsumerState<UserListPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(usersControllerProvider.notifier).loadUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final UsersState state = ref.watch(usersControllerProvider);
    final UsersController controller = ref.read(
      usersControllerProvider.notifier,
    );

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Row(
            children: <Widget>[
              IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu_rounded),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Users',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ),
              FilledButton.icon(
                onPressed: () => context.push('/users/new'),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: SearchField(
            controller: _searchController,
            onChanged: controller.onSearchChanged,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(child: _buildBody(context, state)),
      ],
    );
  }

  Widget _buildBody(BuildContext context, UsersState state) {
    final UsersController controller = ref.read(
      usersControllerProvider.notifier,
    );

    if (state.status == UsersStatus.loading && state.users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == UsersStatus.error && state.users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(state.errorMessage ?? 'Failed to load users'),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: controller.loadUsers,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.users.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No users found. Tap Add to create your first user.'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.loadUsers,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
        itemCount: state.users.length,
        separatorBuilder: (BuildContext context, int index) => Divider(
          height: 1,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        itemBuilder: (BuildContext context, int index) {
          final UserEntity user = state.users[index];
          final String imageUrl = controller.resolveImageUrl(user.userImage);

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            onTap: () => context.push('/users/${Uri.encodeComponent(user.id)}'),
            leading: _UserAvatar(
              imageUrl: imageUrl,
              displayName: user.displayName,
            ),
            title: Text(
              user.displayName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(user.email.isEmpty ? user.username : user.email),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (String action) => _onAction(context, action, user),
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(value: 'view', child: Text('View')),
                const PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: user.enabled
                      ? Colors.green.withValues(alpha: 0.12)
                      : Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  user.enabled ? 'Enabled' : 'Disabled',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: user.enabled
                        ? Colors.green.shade700
                        : Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _onAction(
    BuildContext context,
    String action,
    UserEntity user,
  ) async {
    switch (action) {
      case 'view':
        context.push('/users/${Uri.encodeComponent(user.id)}');
        return;
      case 'edit':
        context.push('/users/${Uri.encodeComponent(user.id)}/edit');
        return;
      case 'delete':
        await _confirmDelete(context, user);
        return;
    }
  }

  Future<void> _confirmDelete(BuildContext context, UserEntity user) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete User'),
          content: Text('Delete ${user.displayName}?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => context.pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => context.pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final failure = await ref
        .read(usersControllerProvider.notifier)
        .deleteUser(user.id);
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(failure == null ? 'User deleted.' : failure.message),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.imageUrl, required this.displayName});

  final String imageUrl;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Image.network(
          imageUrl,
          width: 42,
          height: 42,
          fit: BoxFit.cover,
          errorBuilder: (_, error, stackTrace) => _initialFallback(),
        ),
      );
    }
    return _initialFallback();
  }

  Widget _initialFallback() {
    final String safe = displayName.trim();
    final String first = safe.isNotEmpty ? safe[0] : 'U';
    return CircleAvatar(
      radius: 21,
      child: Text(
        first.toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}
