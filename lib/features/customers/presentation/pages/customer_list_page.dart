import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
          ),
        ),
        const SizedBox(height: 10),
        Expanded(child: _buildBody(context, state)),
      ],
    );
  }

  Widget _buildBody(BuildContext context, CustomersState state) {
    final CustomersController controller = ref.read(
      customersControllerProvider.notifier,
    );

    if (state.status == CustomersStatus.loading && state.customers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == CustomersStatus.error && state.customers.isEmpty) {
      return Center(
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
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
        itemCount: state.customers.length,
        separatorBuilder: (BuildContext context, int index) => Divider(
          height: 1,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        itemBuilder: (BuildContext context, int index) {
          final CustomerEntity customer = state.customers[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            onTap: () =>
                context.push('/customers/${Uri.encodeComponent(customer.id)}'),
            title: Text(
              customer.displayName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_subtitle(customer)),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (String action) =>
                  _onAction(context, action, customer),
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(value: 'view', child: Text('View')),
                const PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
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
                  customer.territory.trim().isEmpty
                      ? '-'
                      : customer.territory.trim(),
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

  String _subtitle(CustomerEntity customer) {
    final String type = customer.customerType.trim();
    final String group = customer.customerGroup.trim();
    if (type.isEmpty && group.isEmpty) {
      return customer.id;
    }
    if (type.isEmpty) {
      return group;
    }
    if (group.isEmpty) {
      return type;
    }
    return '$type • $group';
  }

  Future<void> _onAction(
    BuildContext context,
    String action,
    CustomerEntity customer,
  ) async {
    switch (action) {
      case 'view':
        context.push('/customers/${Uri.encodeComponent(customer.id)}');
        return;
      case 'edit':
        context.push('/customers/${Uri.encodeComponent(customer.id)}/edit');
        return;
      case 'delete':
        await _confirmDelete(context, customer);
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(failure == null ? 'Customer deleted.' : failure.message),
      ),
    );
  }
}
