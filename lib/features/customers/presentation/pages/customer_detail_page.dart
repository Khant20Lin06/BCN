import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/feedback/app_feedback.dart';
import '../../../../core/permissions/app_permission_resolver.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/customer_entity.dart';
import '../controllers/customers_controller.dart';

class CustomerDetailPage extends ConsumerWidget {
  const CustomerDetailPage({super.key, required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).session;
    final bool canWrite = AppPermissionResolver.can(
      session,
      AppModule.customers,
      PermissionAction.write,
    );
    final bool canDelete = AppPermissionResolver.can(
      session,
      AppModule.customers,
      PermissionAction.delete,
    );

    final AsyncValue<CustomerEntity> customerAsync = ref.watch(
      customerDetailProvider(customerId),
    );

    return customerAsync.when(
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
                  onPressed: () =>
                      ref.invalidate(customerDetailProvider(customerId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (CustomerEntity customer) {
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
                      'Customer Detail',
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
                          '/customers/${Uri.encodeComponent(customer.id)}/edit',
                        );
                        if (changed == true) {
                          ref.invalidate(customerDetailProvider(customer.id));
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
                    _ReadOnlyField(label: 'ID', value: customer.id),
                    const SizedBox(height: 14),
                    _ReadOnlyField(
                      label: 'Customer Name',
                      value: customer.customerName,
                    ),
                    const SizedBox(height: 14),
                    _ReadOnlyField(
                      label: 'Customer Type',
                      value: customer.customerType,
                    ),
                    const SizedBox(height: 14),
                    _ReadOnlyField(
                      label: 'Customer Group',
                      value: customer.customerGroup,
                    ),
                    const SizedBox(height: 14),
                    _ReadOnlyField(
                      label: 'Territory',
                      value: customer.territory,
                    ),
                    const SizedBox(height: 14),
                    _ReadOnlyField(
                      label: 'Creation',
                      value: _formatDate(customer.creation),
                    ),
                    const SizedBox(height: 14),
                    _ReadOnlyField(
                      label: 'Modified',
                      value: _formatDate(customer.modified),
                    ),
                    const SizedBox(height: 20),
                    if (canDelete)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () =>
                              _confirmDelete(context, ref, customer),
                          icon: const Icon(Icons.delete_forever_rounded),
                          label: const Text('Delete Customer'),
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
    CustomerEntity customer,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Customer'),
          content: Text('Delete ${customer.displayName}?'),
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
        .read(customersControllerProvider.notifier)
        .deleteCustomer(customer.id);
    if (!context.mounted) {
      return;
    }

    if (failure == null) {
      context.showAppSuccess('Customer deleted.');
    } else {
      context.showAppFailure(failure);
    }

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
