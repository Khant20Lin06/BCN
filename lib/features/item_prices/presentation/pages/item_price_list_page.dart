import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/feedback/app_feedback.dart';
import '../../../../core/permissions/app_permission_resolver.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../items/presentation/widgets/search_field.dart';
import '../../domain/entities/item_price_entity.dart';
import '../controllers/item_prices_controller.dart';
import '../state/item_prices_state.dart';

class ItemPriceListPage extends ConsumerStatefulWidget {
  const ItemPriceListPage({super.key});

  @override
  ConsumerState<ItemPriceListPage> createState() => _ItemPriceListPageState();
}

class _ItemPriceListPageState extends ConsumerState<ItemPriceListPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(itemPricesControllerProvider.notifier).loadItemPrices();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ItemPricesState state = ref.watch(itemPricesControllerProvider);
    final ItemPricesController controller = ref.read(
      itemPricesControllerProvider.notifier,
    );
    final session = ref.watch(authControllerProvider).session;
    final bool canRead = AppPermissionResolver.can(
      session,
      AppModule.itemPrices,
      PermissionAction.read,
    );
    final bool canCreate = AppPermissionResolver.can(
      session,
      AppModule.itemPrices,
      PermissionAction.create,
    );
    final bool canWrite = AppPermissionResolver.can(
      session,
      AppModule.itemPrices,
      PermissionAction.write,
    );
    final bool canDelete = AppPermissionResolver.can(
      session,
      AppModule.itemPrices,
      PermissionAction.delete,
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
                  'Item Prices',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ),
              if (canCreate)
                FilledButton.icon(
                  onPressed: () => context.push('/item-prices/new'),
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
        Expanded(
          child: _buildBody(
            context,
            state,
            canRead: canRead,
            canWrite: canWrite,
            canDelete: canDelete,
          ),
        ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    ItemPricesState state, {
    required bool canRead,
    required bool canWrite,
    required bool canDelete,
  }) {
    final ItemPricesController controller = ref.read(
      itemPricesControllerProvider.notifier,
    );

    if (state.status == ItemPricesStatus.loading && state.itemPrices.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == ItemPricesStatus.error && state.itemPrices.isEmpty) {
      return AppLoadErrorReporter(
        message: state.errorMessage ?? 'Failed to load item prices',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(state.errorMessage ?? 'Failed to load item prices'),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: controller.loadItemPrices,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state.itemPrices.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No item prices found. Tap Add to create one.'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.loadItemPrices,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
        itemCount: state.itemPrices.length,
        separatorBuilder: (BuildContext context, int index) => Divider(
          height: 1,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        itemBuilder: (BuildContext context, int index) {
          final ItemPriceEntity itemPrice = state.itemPrices[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            onTap: canRead
                ? () => context.push(
                    '/item-prices/${Uri.encodeComponent(itemPrice.id)}',
                  )
                : null,
            title: Text(
              itemPrice.displayName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_subtitle(itemPrice)),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (String action) => _onAction(
                context,
                action,
                itemPrice,
                canRead: canRead,
                canWrite: canWrite,
                canDelete: canDelete,
              ),
              itemBuilder: (BuildContext context) {
                final List<PopupMenuEntry<String>> entries =
                    <PopupMenuEntry<String>>[];
                if (canRead) {
                  entries.add(
                    const PopupMenuItem<String>(
                      value: 'view',
                      child: Text('View'),
                    ),
                  );
                }
                if (canWrite) {
                  entries.add(
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                  );
                }
                if (canDelete) {
                  entries.add(
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  );
                }
                return entries;
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _rateText(itemPrice),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _subtitle(ItemPriceEntity itemPrice) {
    final String itemName = itemPrice.itemName.trim();
    final String uom = itemPrice.uom.trim();
    final String priceList = itemPrice.priceList.trim();
    final String validFrom = _formatDate(itemPrice.validFrom);

    final List<String> parts = <String>[];
    if (itemName.isNotEmpty) {
      parts.add(itemName);
    }
    if (uom.isNotEmpty) {
      parts.add(uom);
    }
    if (priceList.isNotEmpty) {
      parts.add(priceList);
    }
    if (validFrom != '-') {
      parts.add(validFrom);
    }
    if (parts.isEmpty) {
      return '-';
    }
    return parts.join(' | ');
  }

  String _rateText(ItemPriceEntity itemPrice) {
    return itemPrice.priceListRate?.toStringAsFixed(2) ?? '-';
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '-';
    }
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  Future<void> _onAction(
    BuildContext context,
    String action,
    ItemPriceEntity itemPrice, {
    required bool canRead,
    required bool canWrite,
    required bool canDelete,
  }) async {
    switch (action) {
      case 'view':
        if (canRead) {
          context.push('/item-prices/${Uri.encodeComponent(itemPrice.id)}');
        }
        return;
      case 'edit':
        if (canWrite) {
          context.push(
            '/item-prices/${Uri.encodeComponent(itemPrice.id)}/edit',
          );
        }
        return;
      case 'delete':
        if (canDelete) {
          await _confirmDelete(context, itemPrice);
        }
        return;
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ItemPriceEntity itemPrice,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Item Price'),
          content: Text('Delete price record ${itemPrice.id}?'),
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
        .read(itemPricesControllerProvider.notifier)
        .deleteItemPrice(itemPrice.id);
    if (!context.mounted) {
      return;
    }

    if (failure == null) {
      context.showAppSuccess('Item price deleted.');
    } else {
      context.showAppFailure(failure);
    }
  }
}
