import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/permissions/app_permission_resolver.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/stock_balance_entity.dart';
import '../controllers/stock_balances_controller.dart';

class StockBalanceDetailPage extends ConsumerWidget {
  const StockBalanceDetailPage({super.key, required this.stockBalanceId});

  final String stockBalanceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).session;
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

    final AsyncValue<StockBalanceEntity> stockAsync = ref.watch(
      stockBalanceDetailProvider(stockBalanceId),
    );

    return stockAsync.when(
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
                onPressed: () =>
                    ref.invalidate(stockBalanceDetailProvider(stockBalanceId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (StockBalanceEntity stock) {
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
                  const Expanded(
                    child: Text(
                      'Stock Balance Detail',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (canWrite)
                    FilledButton.tonalIcon(
                      onPressed: () async {
                        final bool? changed = await context.push<bool>(
                          '/stock-balances/${Uri.encodeComponent(stock.id)}/edit',
                        );
                        if (changed == true) {
                          ref.invalidate(stockBalanceDetailProvider(stock.id));
                        }
                      },
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
                    _ReadOnlyField(label: 'ID', value: stock.id),
                    const SizedBox(height: 14),
                    _ReadOnlyField(label: 'Item Code', value: stock.itemCode),
                    const SizedBox(height: 14),
                    _ReadOnlyField(label: 'Item Name', value: stock.itemName),
                    const SizedBox(height: 14),
                    _ReadOnlyField(label: 'Warehouse', value: stock.warehouse),
                    const SizedBox(height: 14),
                    _ReadOnlyField(
                      label: 'Actual Qty',
                      value: stock.actualQty?.toStringAsFixed(2) ?? '-',
                    ),
                    const SizedBox(height: 14),
                    _ReadOnlyField(
                      label: 'Valuation Rate',
                      value: stock.valuationRate?.toStringAsFixed(2) ?? '-',
                    ),
                    const SizedBox(height: 14),
                    _ReadOnlyField(label: 'UOM', value: stock.uom),
                    const SizedBox(height: 14),
                    _ReadOnlyField(
                      label: 'Creation',
                      value: _formatDate(stock.creation),
                    ),
                    const SizedBox(height: 14),
                    _ReadOnlyField(
                      label: 'Modified',
                      value: _formatDate(stock.modified),
                    ),
                    const SizedBox(height: 20),
                    if (canDelete)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _confirmDelete(context, ref, stock),
                          icon: const Icon(Icons.delete_forever_rounded),
                          label: const Text('Delete Stock Balance'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
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

    if (failure == null && context.mounted) {
      context.pop();
    }
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '-';
    }
    return DateFormat('yyyy-MM-dd HH:mm').format(value.toLocal());
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
          child: Text(value.trim().isEmpty ? '-' : value.trim()),
        ),
      ],
    );
  }
}
