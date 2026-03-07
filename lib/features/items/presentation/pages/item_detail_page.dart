import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/feedback/app_feedback.dart';
import '../../../../core/permissions/app_permission_resolver.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/items_controller.dart';

class ItemDetailPage extends ConsumerWidget {
  const ItemDetailPage({
    super.key,
    required this.itemId,
    this.embedded = false,
  });

  final String itemId;
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(itemDetailProvider(itemId));
    final session = ref.watch(authControllerProvider).session;
    final bool canWrite = AppPermissionResolver.can(
      session,
      AppModule.items,
      PermissionAction.write,
    );
    final bool canDelete = AppPermissionResolver.can(
      session,
      AppModule.items,
      PermissionAction.delete,
    );

    return itemAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stackTrace) => AppLoadErrorReporter(
        message: error.toString(),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(error.toString()),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: () => ref.invalidate(itemDetailProvider(itemId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (item) {
        final String imageUrl = _resolveImageUrl(item.image, session?.baseUrl);
        final Widget content = SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (imageUrl.isNotEmpty) ...<Widget>[
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      imageUrl,
                      width: 128,
                      height: 128,
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, stackTrace) => Container(
                        width: 128,
                        height: 128,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              _ReadOnlyField(
                label: 'Item Code',
                value: item.itemCode?.trim().isNotEmpty == true
                    ? item.itemCode!
                    : 'Auto-generated',
              ),
              const SizedBox(height: 14),
              _ReadOnlyField(label: 'Item Name', value: item.itemName),
              const SizedBox(height: 14),
              _ReadOnlyField(label: 'Item Group', value: item.itemGroup),
              const SizedBox(height: 14),
              _ReadOnlyField(label: 'UOM', value: item.stockUom),
              const SizedBox(height: 14),
              _ReadOnlyField(
                label: 'Qty (Stock)',
                value: item.stockQty?.toStringAsFixed(2) ?? '-',
              ),
              const SizedBox(height: 14),
              _ReadOnlyField(
                label: 'Valuation Rate',
                value: item.valuationRate?.toString() ?? '-',
              ),
              const SizedBox(height: 14),
              _ReadOnlyField(
                label: 'Standard Rate',
                value: item.standardRate?.toString() ?? '-',
              ),
              const SizedBox(height: 14),
              _ReadOnlySwitchField(
                label: 'Maintain Stock',
                value: item.maintainStock,
              ),
              const SizedBox(height: 20),
              if (canWrite || canDelete) ...<Widget>[
                Row(
                  children: <Widget>[
                    if (canWrite)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openEditForm(context, ref),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit'),
                        ),
                      ),
                    if (canWrite) const SizedBox(width: 12),
                    if (canWrite)
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () =>
                              _confirmSoftDelete(context, ref, item.id),
                          icon: const Icon(Icons.block_outlined),
                          label: const Text('Soft Delete'),
                        ),
                      ),
                  ],
                ),
                if (canDelete) const SizedBox(height: 12),
                if (canDelete)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () =>
                          _confirmHardDelete(context, ref, item.id),
                      icon: const Icon(Icons.delete_forever_rounded),
                      label: const Text('Hard Delete'),
                    ),
                  ),
              ] else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'You have read-only permission for Item.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
            ],
          ),
        );

        if (embedded) {
          return content;
        }

        return Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Item Detail',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            Expanded(child: content),
          ],
        );
      },
    );
  }

  String _resolveImageUrl(String? path, String? baseUrl) {
    final String normalized = (path ?? '').trim();
    if (normalized.isEmpty) {
      return '';
    }
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return normalized;
    }
    final String resolvedBaseUrl = (baseUrl ?? '').trim();
    if (resolvedBaseUrl.isEmpty) {
      return '';
    }
    return '$resolvedBaseUrl$normalized';
  }

  Future<void> _openEditForm(BuildContext context, WidgetRef ref) async {
    final bool? didUpdate = await context.push<bool>('/items/$itemId/edit');
    if (didUpdate != true || !context.mounted) {
      return;
    }

    ref.invalidate(itemDetailProvider(itemId));
    await ref.read(itemsControllerProvider.notifier).refresh();
  }

  Future<void> _confirmSoftDelete(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Soft Delete Item'),
          content: const Text('This will set the item to disabled. Continue?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => context.pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => context.pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final Failure? failure = await ref
        .read(itemsControllerProvider.notifier)
        .softDelete(id);
    if (!context.mounted) {
      return;
    }

    if (failure == null) {
      context.showAppSuccess('Item disabled.');
    } else {
      context.showAppFailure(failure);
    }

    ref.invalidate(itemDetailProvider(id));
    if (!embedded) {
      await ref.read(itemsControllerProvider.notifier).refresh();
      if (context.mounted) {
        context.pop();
      }
    }
  }

  Future<void> _confirmHardDelete(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hard Delete Item'),
          content: const Text(
            'This action permanently deletes the item. Continue?',
          ),
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

    final Failure? failure = await ref
        .read(itemsControllerProvider.notifier)
        .hardDelete(id);
    if (!context.mounted) {
      return;
    }

    if (failure == null) {
      context.showAppSuccess('Item deleted.');
    } else {
      context.showAppFailure(failure);
    }

    if (failure == null) {
      ref.invalidate(itemDetailProvider(id));
      await ref.read(itemsControllerProvider.notifier).refresh();
      if (!embedded && context.mounted) {
        context.pop();
      }
    }
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
          child: Text(
            value.isEmpty ? '-' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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
