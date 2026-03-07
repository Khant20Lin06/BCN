import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/feedback/app_feedback.dart';
import '../controllers/customers_controller.dart';

class CustomerFormPage extends ConsumerStatefulWidget {
  const CustomerFormPage({super.key, this.customerId});

  final String? customerId;

  bool get isEdit => customerId != null;

  @override
  ConsumerState<CustomerFormPage> createState() => _CustomerFormPageState();
}

class _CustomerFormPageState extends ConsumerState<CustomerFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _customerIdController;
  late final TextEditingController _customerNameController;
  late final TextEditingController _customerGroupController;
  late final TextEditingController _territoryController;

  List<String> _customerGroupOptions = const <String>[];
  List<String> _territoryOptions = const <String>[];
  String? _selectedCustomerGroup;
  String? _selectedTerritory;
  String? _customerType;
  bool _loading = false;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _customerIdController = TextEditingController();
    _customerNameController = TextEditingController();
    _customerGroupController = TextEditingController();
    _territoryController = TextEditingController();
    _customerType = 'Company';
    _loading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  @override
  void dispose() {
    _customerIdController.dispose();
    _customerNameController.dispose();
    _customerGroupController.dispose();
    _territoryController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final CustomersController controller = ref.read(
      customersControllerProvider.notifier,
    );

    List<String> customerGroups = const <String>[];
    List<String> territories = const <String>[];
    String? errorMessage;

    try {
      customerGroups = await controller.fetchCustomerGroups();
    } catch (_) {
      customerGroups = const <String>[];
    }

    try {
      territories = await controller.fetchTerritories();
    } catch (_) {
      territories = const <String>[];
    }

    String customerId = '';
    String customerName = '';
    String customerType = _customerType ?? 'Company';
    String customerGroup = '';
    String territory = '';

    if (widget.isEdit) {
      try {
        final customer = await controller.getCustomerDetail(widget.customerId!);
        customerId = customer.id;
        customerName = customer.customerName;
        customerType = customer.customerType.trim().isEmpty
            ? 'Company'
            : customer.customerType.trim();
        customerGroup = customer.customerGroup.trim();
        territory = customer.territory.trim();
      } catch (error) {
        errorMessage = error.toString();
      }
    }

    if (!mounted) {
      return;
    }

    final List<String> mergedGroups = _mergeWithCurrent(
      customerGroups,
      customerGroup,
    );
    final List<String> mergedTerritories = _mergeWithCurrent(
      territories,
      territory,
    );

    setState(() {
      _customerGroupOptions = mergedGroups;
      _territoryOptions = mergedTerritories;

      if (widget.isEdit && errorMessage == null) {
        _customerIdController.text = customerId;
        _customerNameController.text = customerName;
        _customerType = customerType;
        _customerGroupController.text = customerGroup;
        _territoryController.text = territory;
      }

      if (_customerGroupController.text.trim().isEmpty &&
          _customerGroupOptions.isNotEmpty) {
        _customerGroupController.text = _customerGroupOptions.first;
      }
      if (_territoryController.text.trim().isEmpty &&
          _territoryOptions.isNotEmpty) {
        _territoryController.text = _territoryOptions.first;
      }

      _selectedCustomerGroup = _customerGroupController.text.trim().isEmpty
          ? null
          : _customerGroupController.text.trim();
      _selectedTerritory = _territoryController.text.trim().isEmpty
          ? null
          : _territoryController.text.trim();

      _loading = false;
      _errorMessage = errorMessage;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final String selectedType = (_customerType ?? '').trim();
    final failure = widget.isEdit
        ? await ref
              .read(customersControllerProvider.notifier)
              .updateCustomer(
                id: widget.customerId!,
                customerName: _customerNameController.text,
                customerType: selectedType,
                customerGroup: _customerGroupController.text,
                territory: _territoryController.text,
              )
        : await ref
              .read(customersControllerProvider.notifier)
              .createCustomer(
                customerId: _customerIdController.text,
                customerName: _customerNameController.text,
                customerType: selectedType,
                customerGroup: _customerGroupController.text,
                territory: _territoryController.text,
              );

    if (!mounted) {
      return;
    }

    setState(() {
      _submitting = false;
    });

    if (failure != null) {
      context.showAppFailure(failure);
      return;
    }

    context.showAppSuccess(
      widget.isEdit ? 'Customer updated.' : 'Customer created.',
    );
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final bool isBusy = _loading || _submitting;
    final List<String> customerTypeOptions = _customerTypeOptions();

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
              Expanded(
                child: Text(
                  widget.isEdit ? 'Edit Customer' : 'Create Customer',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              FilledButton(
                onPressed: isBusy ? null : _save,
                child: isBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (_errorMessage != null)
                          AppLoadErrorReporter(
                            message: _errorMessage!,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ),
                        if (!widget.isEdit) ...<Widget>[
                          const _FieldLabel(label: 'Customer ID (optional)'),
                          TextFormField(
                            controller: _customerIdController,
                            decoration: const InputDecoration(
                              hintText: 'Auto generated if blank',
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        const _FieldLabel(label: 'Customer Name *'),
                        TextFormField(
                          controller: _customerNameController,
                          decoration: const InputDecoration(
                            hintText: 'Customer name',
                          ),
                          validator: (String? value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Customer name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        const _FieldLabel(label: 'Customer Type *'),
                        DropdownButtonFormField<String>(
                          key: ValueKey<String?>(_customerType),
                          initialValue: _customerType,
                          decoration: const InputDecoration(),
                          items: customerTypeOptions
                              .map(
                                (String value) => DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: isBusy
                              ? null
                              : (String? value) {
                                  setState(() {
                                    _customerType = value;
                                  });
                                },
                          validator: (String? value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Customer type is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        const _FieldLabel(label: 'Customer Group *'),
                        if (_customerGroupOptions.isNotEmpty)
                          DropdownButtonFormField<String>(
                            key: ValueKey<String>(
                              'group-${_selectedCustomerGroup ?? ''}-${_customerGroupOptions.length}',
                            ),
                            initialValue: _selectedCustomerGroup,
                            decoration: const InputDecoration(),
                            items: _customerGroupOptions
                                .map(
                                  (String value) => DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: isBusy
                                ? null
                                : (String? value) {
                                    setState(() {
                                      _selectedCustomerGroup = value;
                                      _customerGroupController.text =
                                          (value ?? '').trim();
                                    });
                                  },
                            validator: (String? value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Customer group is required';
                              }
                              return null;
                            },
                          )
                        else
                          TextFormField(
                            controller: _customerGroupController,
                            decoration: const InputDecoration(
                              hintText: 'Customer Group',
                            ),
                            validator: (String? value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Customer group is required';
                              }
                              return null;
                            },
                          ),
                        const SizedBox(height: 14),
                        const _FieldLabel(label: 'Territory *'),
                        if (_territoryOptions.isNotEmpty)
                          DropdownButtonFormField<String>(
                            key: ValueKey<String>(
                              'territory-${_selectedTerritory ?? ''}-${_territoryOptions.length}',
                            ),
                            initialValue: _selectedTerritory,
                            decoration: const InputDecoration(),
                            items: _territoryOptions
                                .map(
                                  (String value) => DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: isBusy
                                ? null
                                : (String? value) {
                                    setState(() {
                                      _selectedTerritory = value;
                                      _territoryController.text = (value ?? '')
                                          .trim();
                                    });
                                  },
                            validator: (String? value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Territory is required';
                              }
                              return null;
                            },
                          )
                        else
                          TextFormField(
                            controller: _territoryController,
                            decoration: const InputDecoration(
                              hintText: 'Territory',
                            ),
                            validator: (String? value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Territory is required';
                              }
                              return null;
                            },
                          ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  List<String> _customerTypeOptions() {
    const List<String> defaults = <String>['Company', 'Individual'];
    final String current = (_customerType ?? '').trim();
    if (current.isEmpty || defaults.contains(current)) {
      return defaults;
    }
    return <String>[current, ...defaults];
  }

  List<String> _mergeWithCurrent(List<String> source, String currentValue) {
    final String normalizedCurrent = currentValue.trim();
    if (normalizedCurrent.isEmpty || source.contains(normalizedCurrent)) {
      return source;
    }
    return <String>[normalizedCurrent, ...source];
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          letterSpacing: 1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
