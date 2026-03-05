import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/permissions/app_permission_resolver.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../items/presentation/widgets/search_field.dart';
import '../../domain/entities/stock_balance_entity.dart';
import '../controllers/stock_balances_controller.dart';
import '../state/stock_balances_state.dart';

class StockBalanceListPage extends ConsumerStatefulWidget {
  const StockBalanceListPage({super.key});

  @override
  ConsumerState<StockBalanceListPage> createState() =>
      _StockBalanceListPageState();
}

class _StockBalanceListPageState extends ConsumerState<StockBalanceListPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(stockBalancesControllerProvider.notifier).loadStockBalances();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final StockBalancesState state = ref.watch(stockBalancesControllerProvider);
    final StockBalancesController controller = ref.read(
      stockBalancesControllerProvider.notifier,
    );
    final session = ref.watch(authControllerProvider).session;
    final bool canRead = AppPermissionResolver.can(
      session,
      AppModule.stockBalances,
      PermissionAction.read,
    );
    final bool canCreate = AppPermissionResolver.can(
      session,
      AppModule.stockBalances,
      PermissionAction.create,
    );
    final bool canWrite = AppPermissionResolver.can(
      session,
      AppModule.stockBalances,
      PermissionAction.write,
    );
    final bool canDelete = AppPermissionResolver.can(
      session,
      AppModule.stockBalances,
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
                  'Stock Balance',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ),
              if (canCreate)
                FilledButton.icon(
                  onPressed: () => context.push('/stock-balances/new'),
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
    StockBalancesState state, {
    required bool canRead,
    required bool canWrite,
    required bool canDelete,
  }) {
    final StockBalancesController controller = ref.read(
      stockBalancesControllerProvider.notifier,
    );

    if (state.status == StockBalancesStatus.loading &&
        state.stockBalances.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == StockBalancesStatus.error &&
        state.stockBalances.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(state.errorMessage ?? 'Failed to load stock balances'),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: controller.loadStockBalances,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.stockBalances.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No stock balances found. Tap Add to create one.'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.loadStockBalances,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
        itemCount: state.stockBalances.length,
        separatorBuilder: (BuildContext context, int index) => Divider(
          height: 1,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        itemBuilder: (BuildContext context, int index) {
          final StockBalanceEntity stock = state.stockBalances[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            onTap: canRead
                ? () => context.push(
                    '/stock-balances/${Uri.encodeComponent(stock.id)}',
                  )
                : null,
            title: Text(
              stock.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${stock.warehouse} | Qty: ${stock.actualQty?.toStringAsFixed(2) ?? '-'} ${stock.uom.trim().isEmpty ? '' : stock.uom}',
              ),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (String action) => _onAction(
                context,
                action,
                stock,
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
            ),
          );
        },
      ),
    );
  }

  Future<void> _onAction(
    BuildContext context,
    String action,
    StockBalanceEntity stock, {
    required bool canRead,
    required bool canWrite,
    required bool canDelete,
  }) async {
    switch (action) {
      case 'view':
        if (canRead) {
          context.push('/stock-balances/${Uri.encodeComponent(stock.id)}');
        }
        return;
      case 'edit':
        if (canWrite) {
          context.push('/stock-balances/${Uri.encodeComponent(stock.id)}/edit');
        }
        return;
      case 'delete':
        if (canDelete) {
          await _confirmDelete(context, stock);
        }
        return;
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    StockBalanceEntity stock,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Stock Balance'),
          content: Text('Delete ${stock.id}?'),
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
        .read(stockBalancesControllerProvider.notifier)
        .deleteStockBalance(
          id: stock.id,
          itemCode: stock.itemCode,
          warehouse: stock.warehouse,
          uom: stock.uom,
          valuationRate: stock.valuationRate,
        );
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failure == null ? 'Stock balance deleted.' : failure.message,
        ),
      ),
    );
  }
}
