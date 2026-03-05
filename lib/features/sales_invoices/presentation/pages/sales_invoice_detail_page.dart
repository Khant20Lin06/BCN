import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/permissions/app_permission_resolver.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/sales_invoice_entity.dart';
import '../controllers/sales_invoices_controller.dart';

class SalesInvoiceDetailPage extends ConsumerWidget {
  const SalesInvoiceDetailPage({super.key, required this.salesInvoiceId});

  final String salesInvoiceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).session;
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

    final AsyncValue<SalesInvoiceEntity> invoiceAsync = ref.watch(
      salesInvoiceDetailProvider(salesInvoiceId),
    );

    return invoiceAsync.when(
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
                    ref.invalidate(salesInvoiceDetailProvider(salesInvoiceId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (SalesInvoiceEntity invoice) {
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
                      'Sales Invoice Detail',
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
                          '/sales-invoices/${Uri.encodeComponent(invoice.id)}/edit',
                        );
                        if (changed == true) {
                          ref.invalidate(
                            salesInvoiceDetailProvider(invoice.id),
                          );
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
                    _ReadOnlyField(label: 'Name', value: invoice.id),
                    const SizedBox(height: 14),
                    _ReadOnlyField(label: 'Customer', value: invoice.customer),
                    const SizedBox(height: 14),
                    _ReadOnlyField(
                      label: 'Posting Date',
                      value: _formatDate(invoice.postingDate),
                    ),
                    const SizedBox(height: 14),
                    _ReadOnlyField(
                      label: 'Grand Total',
                      value: invoice.grandTotal.toStringAsFixed(2),
                    ),
                    const SizedBox(height: 14),
                    _ReadOnlyField(label: 'Status', value: invoice.status),
                    const SizedBox(height: 14),
                    _ReadOnlyField(
                      label: 'Creation',
                      value: _formatDateTime(invoice.creation),
                    ),
                    const SizedBox(height: 14),
                    _ReadOnlyField(
                      label: 'Modified',
                      value: _formatDateTime(invoice.modified),
                    ),
                    const SizedBox(height: 20),
                    if (canDelete)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () =>
                              _confirmDelete(context, ref, invoice),
                          icon: const Icon(Icons.delete_forever_rounded),
                          label: const Text('Delete Sales Invoice'),
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failure == null ? 'Sales invoice deleted.' : failure.message,
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
    return DateFormat('yyyy-MM-dd').format(value.toLocal());
  }

  String _formatDateTime(DateTime? value) {
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
    final String normalizedValue = value.trim();

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
          child: Text(normalizedValue.isEmpty ? '-' : normalizedValue),
        ),
      ],
    );
  }
}
