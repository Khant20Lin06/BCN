import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/feedback/app_feedback.dart';
import '../../../../core/permissions/app_permission_resolver.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../items/presentation/widgets/search_field.dart';
import '../../domain/entities/sales_invoice_entity.dart';
import '../controllers/sales_invoices_controller.dart';
import '../state/sales_invoices_state.dart';

class SalesInvoiceListPage extends ConsumerStatefulWidget {
  const SalesInvoiceListPage({super.key});

  @override
  ConsumerState<SalesInvoiceListPage> createState() =>
      _SalesInvoiceListPageState();
}

class _SalesInvoiceListPageState extends ConsumerState<SalesInvoiceListPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(salesInvoicesControllerProvider.notifier).loadSalesInvoices();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SalesInvoicesState state = ref.watch(salesInvoicesControllerProvider);
    final SalesInvoicesController controller = ref.read(
      salesInvoicesControllerProvider.notifier,
    );
    final session = ref.watch(authControllerProvider).session;
    final bool canRead = AppPermissionResolver.can(
      session,
      AppModule.salesInvoices,
      PermissionAction.read,
    );
    final bool canCreate = AppPermissionResolver.can(
      session,
      AppModule.salesInvoices,
      PermissionAction.create,
    );
    final bool canWrite = AppPermissionResolver.can(
      session,
      AppModule.salesInvoices,
      PermissionAction.write,
    );
    final bool canDelete = AppPermissionResolver.can(
      session,
      AppModule.salesInvoices,
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
                  'Sales Invoice',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ),
              if (canCreate)
                FilledButton.icon(
                  onPressed: () => context.push('/sales-invoices/new'),
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
    SalesInvoicesState state, {
    required bool canRead,
    required bool canWrite,
    required bool canDelete,
  }) {
    final SalesInvoicesController controller = ref.read(
      salesInvoicesControllerProvider.notifier,
    );

    if (state.status == SalesInvoicesStatus.loading &&
        state.salesInvoices.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == SalesInvoicesStatus.error &&
        state.salesInvoices.isEmpty) {
      return AppLoadErrorReporter(
        message: state.errorMessage ?? 'Failed to load sales invoices',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(state.errorMessage ?? 'Failed to load sales invoices'),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: controller.loadSalesInvoices,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state.salesInvoices.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No sales invoices found. Tap Add to create your first invoice.',
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.loadSalesInvoices,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
        itemCount: state.salesInvoices.length,
        separatorBuilder: (BuildContext context, int index) => Divider(
          height: 1,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        itemBuilder: (BuildContext context, int index) {
          final SalesInvoiceEntity invoice = state.salesInvoices[index];
          final String postingDate = invoice.postingDate == null
              ? '-'
              : DateFormat('yyyy-MM-dd').format(invoice.postingDate!);
          final String statusText = invoice.status.trim().isEmpty
              ? '-'
              : invoice.status.trim();

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            onTap: canRead
                ? () => context.push(
                    '/sales-invoices/${Uri.encodeComponent(invoice.id)}',
                  )
                : null,
            title: Text(
              invoice.id,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${invoice.customer.trim().isEmpty ? '-' : invoice.customer.trim()} • $postingDate',
              ),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (String action) => _onAction(
                context,
                action,
                invoice,
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
                  statusText,
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

  Future<void> _onAction(
    BuildContext context,
    String action,
    SalesInvoiceEntity invoice, {
    required bool canRead,
    required bool canWrite,
    required bool canDelete,
  }) async {
    switch (action) {
      case 'view':
        if (canRead) {
          context.push('/sales-invoices/${Uri.encodeComponent(invoice.id)}');
        }
        return;
      case 'edit':
        if (canWrite) {
          context.push(
            '/sales-invoices/${Uri.encodeComponent(invoice.id)}/edit',
          );
        }
        return;
      case 'delete':
        if (canDelete) {
          await _confirmDelete(context, invoice);
        }
        return;
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    SalesInvoiceEntity invoice,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Sales Invoice'),
          content: Text('Delete ${invoice.id}?'),
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
        .read(salesInvoicesControllerProvider.notifier)
        .deleteSalesInvoice(invoice.id);
    if (!context.mounted) {
      return;
    }

    if (failure == null) {
      context.showAppSuccess('Sales invoice deleted.');
    } else {
      context.showAppFailure(failure);
    }
  }
}
