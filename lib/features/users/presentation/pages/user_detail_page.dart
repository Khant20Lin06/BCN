import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/permissions/app_permission_resolver.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/user_entity.dart';
import '../controllers/users_controller.dart';

class UserDetailPage extends ConsumerWidget {
  const UserDetailPage({
    super.key,
    required this.userId,
    this.isProfileMode = false,
  });

  final String userId;
  final bool isProfileMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).session;
    final bool canWriteProfile = AppPermissionResolver.can(
      session,
      AppModule.profile,
      PermissionAction.write,
    );

    final AsyncValue<UserEntity> userAsync = ref.watch(
      userDetailProvider(userId),
    );
    final UsersController controller = ref.read(
      usersControllerProvider.notifier,
    );

    return userAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(error.toString()),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: () => ref.invalidate(userDetailProvider(userId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (UserEntity user) {
        final String imageUrl = controller.resolveImageUrl(user.userImage);

        return Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () {
                      if (isProfileMode) {
                        Scaffold.of(context).openDrawer();
                        return;
                      }
                      context.pop();
                    },
                    icon: Icon(
                      isProfileMode
                          ? Icons.menu_rounded
                          : Icons.arrow_back_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isProfileMode ? 'Profile' : 'User Detail',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (canWriteProfile)
                    FilledButton.tonalIcon(
                      onPressed: () => context.push(
                        isProfileMode
                            ? '/profile/edit'
                            : '/users/${Uri.encodeComponent(user.id)}/edit',
                      ),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                      child: _UserHeaderAvatar(
                        imageUrl: imageUrl,
                        displayName: user.displayName,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ReadOnlyField(label: 'User ID', value: user.id),
                    const SizedBox(height: 14),
                    _ReadOnlyField(label: 'Email', value: user.email),
                    const SizedBox(height: 14),
                    _ReadOnlyField(label: 'First Name', value: user.firstName),
                    const SizedBox(height: 14),
                    _ReadOnlyField(label: 'Last Name', value: user.lastName),
                    const SizedBox(height: 14),
                    _ReadOnlyField(label: 'Username', value: user.username),
                    const SizedBox(height: 14),
                    _ReadOnlyField(label: 'User Type', value: user.userType),
                    const SizedBox(height: 14),
                    _ReadOnlySwitchField(label: 'Enabled', value: user.enabled),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _UserHeaderAvatar extends StatelessWidget {
  const _UserHeaderAvatar({required this.imageUrl, required this.displayName});

  final String imageUrl;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Image.network(
          imageUrl,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
          errorBuilder: (_, error, stackTrace) => _fallbackAvatar(),
        ),
      );
    }
    return _fallbackAvatar();
  }

  Widget _fallbackAvatar() {
    final String safe = displayName.trim();
    final String first = safe.isNotEmpty ? safe[0] : 'U';
    return CircleAvatar(
      radius: 36,
      child: Text(
        first.toUpperCase(),
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.35,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Text(value.isEmpty ? '-' : value),
        ),
      ],
    );
  }
}

class _ReadOnlySwitchField extends StatelessWidget {
  const _ReadOnlySwitchField({required this.label, required this.value});

  final String label;
  final bool value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          IgnorePointer(
            child: Switch.adaptive(value: value, onChanged: (_) {}),
          ),
        ],
      ),
    );
  }
}
