import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/feedback/app_feedback.dart';
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
  static final NumberFormat _quantityFormat = NumberFormat('#,##0.##');

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
        _buildHeader(context, canCreate: canCreate),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: _buildFilterSection(controller),
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

  Widget _buildHeader(BuildContext context, {required bool canCreate}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.menu_rounded),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Stock Balance',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (canCreate) ...<Widget>[
            FilledButton.icon(
              onPressed: () => context.push('/stock-balances/new'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 42),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterSection(StockBalancesController controller) {
    return SearchField(
      controller: _searchController,
      onChanged: controller.onSearchChanged,
      hintText: 'Search by Item Code, Item Name, Warehouse',
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
    final List<StockBalanceEntity> filteredStockBalances =
        state.filteredStockBalances;

    if (state.status == StockBalancesStatus.loading &&
        state.stockBalances.isEmpty) {
      return _buildScrollableMessage(
        context,
        const CircularProgressIndicator(),
        onRefresh: controller.loadStockBalances,
      );
    }

    if (state.status == StockBalancesStatus.error &&
        state.stockBalances.isEmpty) {
      return _buildScrollableMessage(
        context,
        AppLoadErrorReporter(
          message: state.errorMessage ?? 'Failed to load stock balances',
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
        onRefresh: controller.loadStockBalances,
      );
    }

    if (state.stockBalances.isEmpty) {
      return _buildScrollableMessage(
        context,
        const Text('No stock balances found.'),
        onRefresh: controller.loadStockBalances,
      );
    }

    if (filteredStockBalances.isEmpty) {
      return _buildScrollableMessage(
        context,
        const Text('No stock balances match the current filters.'),
        onRefresh: controller.loadStockBalances,
      );
    }

    return RefreshIndicator(
      onRefresh: controller.loadStockBalances,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
        itemCount: filteredStockBalances.length + 1,
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _TableHeader(
                headerBackground: Theme.of(context).colorScheme.secondaryContainer,
                headerForeground: Theme.of(
                  context,
                ).colorScheme.onSecondaryContainer,
              ),
            );
          }

          final StockBalanceEntity stock = filteredStockBalances[index - 1];
          final bool showDivider = index != filteredStockBalances.length;
          return _StockBalanceRow(
            stock: stock,
            quantity: _formatQuantity(stock.actualQty),
            showDivider: showDivider,
            onTap: canRead
                ? () => context.push(
                    '/stock-balances/${Uri.encodeComponent(stock.id)}',
                  )
                : null,
            onLongPress: (canRead || canWrite || canDelete)
                ? () => _showRowActions(
                    context,
                    stock,
                    canRead: canRead,
                    canWrite: canWrite,
                    canDelete: canDelete,
                  )
                : null,
          );
        },
      ),
    );
  }

  Widget _buildScrollableMessage(
    BuildContext context,
    Widget child, {
    required Future<void> Function() onRefresh,
  }) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          const SizedBox(height: 90),
          Center(child: child),
        ],
      ),
    );
  }

  Future<void> _showRowActions(
    BuildContext context,
    StockBalanceEntity stock, {
    required bool canRead,
    required bool canWrite,
    required bool canDelete,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              if (canRead)
                ListTile(
                  leading: const Icon(Icons.visibility_outlined),
                  title: const Text('View'),
                  onTap: () {
                    Navigator.pop(context);
                    this.context.push(
                      '/stock-balances/${Uri.encodeComponent(stock.id)}',
                    );
                  },
                ),
              if (canWrite)
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Edit'),
                  onTap: () {
                    Navigator.pop(context);
                    this.context.push(
                      '/stock-balances/${Uri.encodeComponent(stock.id)}/edit',
                    );
                  },
                ),
              if (canDelete)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded),
                  title: const Text('Delete'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _confirmDelete(this.context, stock);
                  },
                ),
            ],
          ),
        );
      },
    );
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

    if (failure == null) {
      context.showAppSuccess('Stock balance deleted.');
    } else {
      context.showAppFailure(failure);
    }
  }

  String _formatQuantity(double? value) {
    if (value == null) {
      return '-';
    }
    return _quantityFormat.format(value);
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({
    required this.headerBackground,
    required this.headerForeground,
  });

  final Color headerBackground;
  final Color headerForeground;

  @override
  Widget build(BuildContext context) {
    final TextStyle? headerStyle = Theme.of(context).textTheme.labelSmall
        ?.copyWith(
          color: headerForeground,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        );

    return Container(
      decoration: BoxDecoration(
        color: headerBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Item Code', style: headerStyle),
                Text(
                  '(Auto-generated)',
                  style: headerStyle?.copyWith(
                    color: headerForeground.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 5,
            child: Text('Warehouse', style: headerStyle),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'On Hand\nQty',
              textAlign: TextAlign.right,
              style: headerStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _StockBalanceRow extends StatelessWidget {
  const _StockBalanceRow({
    required this.stock,
    required this.quantity,
    required this.showDivider,
    this.onTap,
    this.onLongPress,
  });

  final StockBalanceEntity stock;
  final String quantity;
  final bool showDivider;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String itemCode = stock.itemCode.trim().isEmpty ? stock.id : stock.itemCode;
    final String itemName = stock.itemName.trim().isEmpty ? '-' : stock.itemName.trim();
    final String warehouse = stock.warehouse.trim().isEmpty ? '-' : stock.warehouse.trim();

    return Material(
      color: theme.colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 11, 10, 11),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: showDivider
                    ? theme.colorScheme.outlineVariant
                    : Colors.transparent,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                flex: 4,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        itemCode,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        itemName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        warehouse,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      quantity,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    if (stock.uom.trim().isNotEmpty)
                      Text(
                        stock.uom.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
