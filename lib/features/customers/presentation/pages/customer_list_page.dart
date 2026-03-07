import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/feedback/app_feedback.dart';
import '../../../../core/permissions/app_permission_resolver.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../items/presentation/widgets/search_field.dart';
import '../../domain/entities/customer_entity.dart';
import '../controllers/customers_controller.dart';
import '../state/customers_state.dart';

class CustomerListPage extends ConsumerStatefulWidget {
  const CustomerListPage({super.key});

  @override
  ConsumerState<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends ConsumerState<CustomerListPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customersControllerProvider.notifier).loadCustomers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CustomersState state = ref.watch(customersControllerProvider);
    final CustomersController controller = ref.read(
      customersControllerProvider.notifier,
    );
    final session = ref.watch(authControllerProvider).session;
    final bool canRead = AppPermissionResolver.can(
      session,
      AppModule.customers,
      PermissionAction.read,
    );
    final bool canCreate = AppPermissionResolver.can(
      session,
      AppModule.customers,
      PermissionAction.create,
    );
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
                  'Customers',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ),
              if (canCreate)
                FilledButton.icon(
                  onPressed: () => context.push('/customers/new'),
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
            hintText: 'Enter customer name, code, group...',
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
    CustomersState state, {
    required bool canRead,
    required bool canWrite,
    required bool canDelete,
  }) {
    final CustomersController controller = ref.read(
      customersControllerProvider.notifier,
    );

    if (state.status == CustomersStatus.loading && state.customers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == CustomersStatus.error && state.customers.isEmpty) {
      return AppLoadErrorReporter(
        message: state.errorMessage ?? 'Failed to load customers',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(state.errorMessage ?? 'Failed to load customers'),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: controller.loadCustomers,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state.customers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No customers found. Tap Add to create your first customer.',
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.loadCustomers,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              children: <Widget>[
                const _CustomerTableHeader(),
                ...List<Widget>.generate(state.customers.length, (int index) {
                  final CustomerEntity customer = state.customers[index];
                  return Column(
                    children: <Widget>[
                      _CustomerListRow(
                        customer: customer,
                        canRead: canRead,
                        canWrite: canWrite,
                        canDelete: canDelete,
                        onTap: canRead
                            ? () => context.push(
                                '/customers/${Uri.encodeComponent(customer.id)}',
                              )
                            : null,
                        onAction: (String action) => _onAction(
                          context,
                          action,
                          customer,
                          canRead: canRead,
                          canWrite: canWrite,
                          canDelete: canDelete,
                        ),
                      ),
                      if (index != state.customers.length - 1)
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: Theme.of(context).colorScheme.outlineVariant
                              .withValues(alpha: 0.75),
                        ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onAction(
    BuildContext context,
    String action,
    CustomerEntity customer, {
    required bool canRead,
    required bool canWrite,
    required bool canDelete,
  }) async {
    switch (action) {
      case 'view':
        if (canRead) {
          context.push('/customers/${Uri.encodeComponent(customer.id)}');
        }
        return;
      case 'edit':
        if (canWrite) {
          context.push('/customers/${Uri.encodeComponent(customer.id)}/edit');
        }
        return;
      case 'delete':
        if (canDelete) {
          await _confirmDelete(context, customer);
        }
        return;
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
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
  }
}

class _CustomerTableHeader extends StatelessWidget {
  const _CustomerTableHeader();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle headerStyle = theme.textTheme.labelMedium!.copyWith(
      fontWeight: FontWeight.w800,
      color: theme.colorScheme.onSecondaryContainer,
      letterSpacing: 0.2,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.7),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(flex: 5, child: Text('Customer', style: headerStyle)),
          Expanded(flex: 3, child: Text('Group', style: headerStyle)),
          Expanded(flex: 3, child: Text('Territory', style: headerStyle)),
          const SizedBox(width: 32),
        ],
      ),
    );
  }
}

class _CustomerListRow extends StatelessWidget {
  const _CustomerListRow({
    required this.customer,
    required this.canRead,
    required this.canWrite,
    required this.canDelete,
    required this.onAction,
    this.onTap,
  });

  final CustomerEntity customer;
  final bool canRead;
  final bool canWrite;
  final bool canDelete;
  final VoidCallback? onTap;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle titleStyle = theme.textTheme.titleSmall!.copyWith(
      fontWeight: FontWeight.w800,
      height: 1.1,
    );
    final TextStyle idStyle = theme.textTheme.labelSmall!.copyWith(
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.onSurfaceVariant,
      letterSpacing: 0.2,
    );
    final TextStyle valueStyle = theme.textTheme.labelMedium!.copyWith(
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.onSurface,
    );
    final TextStyle secondaryStyle = theme.textTheme.labelSmall!.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurfaceVariant,
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    customer.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    customer.id,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: idStyle,
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: _InfoCell(
                icon: Icons.group_outlined,
                primary: _groupValue(customer),
                secondary: customer.customerType.trim(),
                valueStyle: valueStyle,
                secondaryStyle: secondaryStyle,
              ),
            ),
            Expanded(
              flex: 3,
              child: _InfoCell(
                icon: Icons.location_on_outlined,
                primary: customer.territory.trim().isEmpty
                    ? '-'
                    : customer.territory.trim(),
                secondary: null,
                valueStyle: valueStyle,
                secondaryStyle: secondaryStyle,
              ),
            ),
            SizedBox(
              width: 32,
              child: _CustomerActionButton(
                canRead: canRead,
                canWrite: canWrite,
                canDelete: canDelete,
                onAction: onAction,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _groupValue(CustomerEntity customer) {
    final String group = customer.customerGroup.trim();
    if (group.isNotEmpty) {
      return group;
    }
    final String type = customer.customerType.trim();
    if (type.isNotEmpty) {
      return type;
    }
    return '-';
  }
}

class _InfoCell extends StatelessWidget {
  const _InfoCell({
    required this.icon,
    required this.primary,
    required this.valueStyle,
    required this.secondaryStyle,
    this.secondary,
  });

  final IconData icon;
  final String primary;
  final String? secondary;
  final TextStyle valueStyle;
  final TextStyle secondaryStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              icon,
              size: 15,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  primary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: valueStyle,
                ),
                if (secondary != null && secondary!.trim().isNotEmpty)
                  Text(
                    secondary!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: secondaryStyle,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerActionButton extends StatelessWidget {
  const _CustomerActionButton({
    required this.canRead,
    required this.canWrite,
    required this.canDelete,
    required this.onAction,
  });

  final bool canRead;
  final bool canWrite;
  final bool canDelete;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final List<PopupMenuEntry<String>> entries = <PopupMenuEntry<String>>[];
    if (canRead) {
      entries.add(
        const PopupMenuItem<String>(value: 'view', child: Text('View')),
      );
    }
    if (canWrite) {
      entries.add(
        const PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
      );
    }
    if (canDelete) {
      entries.add(
        const PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
      );
    }

    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      onSelected: onAction,
      itemBuilder: (BuildContext context) => entries,
      icon: Icon(
        Icons.more_vert_rounded,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
