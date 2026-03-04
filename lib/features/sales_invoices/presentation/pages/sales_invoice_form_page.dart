import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/failure.dart';
import '../controllers/sales_invoices_controller.dart';

class SalesInvoiceFormPage extends ConsumerStatefulWidget {
  const SalesInvoiceFormPage({super.key, this.salesInvoiceId});

  final String? salesInvoiceId;

  bool get isEdit => salesInvoiceId != null;

  @override
  ConsumerState<SalesInvoiceFormPage> createState() =>
      _SalesInvoiceFormPageState();
}

class _SalesInvoiceFormPageState extends ConsumerState<SalesInvoiceFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _customerController;
  late final TextEditingController _postingDateController;
  late final TextEditingController _grandTotalController;
  late final TextEditingController _statusController;

  List<String> _customerOptions = const <String>[];
  List<String> _statusOptions = const <String>[];
  List<SalesInvoiceItemOption> _itemOptions = const <SalesInvoiceItemOption>[];
  final List<_SalesInvoiceLineDraft> _lines = <_SalesInvoiceLineDraft>[];

  String? _selectedCustomer;
  String? _selectedStatus;
  bool _loading = false;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _customerController = TextEditingController();
    _postingDateController = TextEditingController();
    _grandTotalController = TextEditingController();
    _statusController = TextEditingController();

    _postingDateController.text = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.now());
    _lines.add(_SalesInvoiceLineDraft());
    _loading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _customerController.dispose();
    _postingDateController.dispose();
    _grandTotalController.dispose();
    _statusController.dispose();
    for (final _SalesInvoiceLineDraft line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  Future<void> _initialize() async {
    final SalesInvoicesController controller = ref.read(
      salesInvoicesControllerProvider.notifier,
    );

    String? errorMessage;
    List<String> customerOptions = const <String>[];
    List<String> statusOptions = const <String>[];
    List<SalesInvoiceItemOption> itemOptions = const <SalesInvoiceItemOption>[];

    String id = '';
    String customer = '';
    String postingDate = _postingDateController.text;
    String grandTotal = '';
    String status = '';
    List<_SalesInvoiceLineDraft> loadedLines = <_SalesInvoiceLineDraft>[
      _SalesInvoiceLineDraft(),
    ];

    try {
      customerOptions = await controller.fetchCustomerOptions();
    } catch (_) {
      customerOptions = const <String>[];
    }

    try {
      itemOptions = await controller.fetchItemOptions();
    } catch (_) {
      itemOptions = const <SalesInvoiceItemOption>[];
    }

    statusOptions = await controller.fetchStatusOptions();

    if (widget.isEdit) {
      try {
        final invoice = await controller.getSalesInvoiceDetail(
          widget.salesInvoiceId!,
        );
        id = invoice.id;
        customer = invoice.customer.trim();
        postingDate = invoice.postingDate == null
            ? ''
            : DateFormat('yyyy-MM-dd').format(invoice.postingDate!);
        grandTotal = invoice.grandTotal.toStringAsFixed(2);
        status = invoice.status.trim();

        if (invoice.items.isNotEmpty) {
          loadedLines = invoice.items
              .map(
                (line) => _SalesInvoiceLineDraft(
                  itemCode: line.itemCode,
                  qty: line.qty.toString(),
                  rate: line.rate?.toString() ?? '',
                ),
              )
              .toList(growable: false);
        }
      } catch (error) {
        errorMessage = error.toString();
      }
    }

    if (!mounted) {
      for (final _SalesInvoiceLineDraft line in loadedLines) {
        line.dispose();
      }
      return;
    }

    itemOptions = _mergeItemOptionsWithLines(itemOptions, loadedLines);
    final List<String> mergedCustomerOptions = _mergeWithCurrent(
      customerOptions,
      customer,
    );
    final List<String> mergedStatusOptions = _mergeWithCurrent(
      statusOptions,
      status,
    );

    for (final _SalesInvoiceLineDraft line in loadedLines) {
      if (line.selectedItemCode == null && itemOptions.isNotEmpty) {
        final String first = itemOptions.first.value;
        line.selectedItemCode = first;
        line.itemCodeController.text = first;
      }
      if (line.qtyController.text.trim().isEmpty) {
        line.qtyController.text = '1';
      }
    }

    for (final _SalesInvoiceLineDraft line in _lines) {
      line.dispose();
    }

    setState(() {
      _lines
        ..clear()
        ..addAll(loadedLines);

      _customerOptions = mergedCustomerOptions;
      _statusOptions = mergedStatusOptions;
      _itemOptions = itemOptions;

      if (widget.isEdit && errorMessage == null) {
        _nameController.text = id;
        _customerController.text = customer;
        _postingDateController.text = postingDate;
        _grandTotalController.text = grandTotal;
        _statusController.text = status;
      }

      if (_customerController.text.trim().isEmpty &&
          _customerOptions.isNotEmpty) {
        _customerController.text = _customerOptions.first;
      }

      if (_statusController.text.trim().isEmpty && _statusOptions.isNotEmpty) {
        _statusController.text = _statusOptions.first;
      }

      _selectedCustomer = _customerController.text.trim().isEmpty
          ? null
          : _customerController.text.trim();
      _selectedStatus = _statusController.text.trim().isEmpty
          ? null
          : _statusController.text.trim();

      _errorMessage = errorMessage;
      _loading = false;
    });
  }

  Future<void> _pickPostingDate() async {
    final DateTime initialDate =
        DateTime.tryParse(_postingDateController.text.trim()) ?? DateTime.now();

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (!mounted || selectedDate == null) {
      return;
    }

    setState(() {
      _postingDateController.text = DateFormat(
        'yyyy-MM-dd',
      ).format(selectedDate);
    });
  }

  void _addItemLine() {
    setState(() {
      final _SalesInvoiceLineDraft draft = _SalesInvoiceLineDraft();
      if (_itemOptions.isNotEmpty) {
        draft.selectedItemCode = _itemOptions.first.value;
        draft.itemCodeController.text = _itemOptions.first.value;
      }
      _lines.add(draft);
    });
  }

  void _removeItemLine(int index) {
    if (_lines.length <= 1) {
      return;
    }

    setState(() {
      final _SalesInvoiceLineDraft removed = _lines.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final List<SalesInvoiceLineInput> lines = <SalesInvoiceLineInput>[];
    for (int i = 0; i < _lines.length; i++) {
      final _SalesInvoiceLineDraft line = _lines[i];
      final String itemCode =
          (line.selectedItemCode ?? line.itemCodeController.text).trim();
      final double? qty = double.tryParse(line.qtyController.text.trim());
      final String rateText = line.rateController.text.trim();
      final double? rate = rateText.isEmpty ? null : double.tryParse(rateText);

      if (itemCode.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item is required in line ${i + 1}.')),
        );
        return;
      }

      if (qty == null || qty <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Qty must be greater than 0 in line ${i + 1}.'),
          ),
        );
        return;
      }

      if (rateText.isNotEmpty && rate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rate must be valid in line ${i + 1}.')),
        );
        return;
      }

      lines.add(
        SalesInvoiceLineInput(itemCode: itemCode, qty: qty, rate: rate),
      );
    }

    if (lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one item line is required.')),
      );
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final SalesInvoicesController controller = ref.read(
      salesInvoicesControllerProvider.notifier,
    );

    final Failure? failure = widget.isEdit
        ? await controller.updateSalesInvoice(
            id: widget.salesInvoiceId!,
            customer: _customerController.text,
            postingDate: _postingDateController.text,
            lines: lines,
          )
        : await controller.createSalesInvoice(
            salesInvoiceId: _nameController.text,
            customer: _customerController.text,
            postingDate: _postingDateController.text,
            lines: lines,
          );

    if (!mounted) {
      return;
    }

    setState(() {
      _submitting = false;
      _errorMessage = failure?.message;
    });

    if (failure != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
      return;
    }

    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final bool isBusy = _loading || _submitting;

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
                  widget.isEdit ? 'Edit Sales Invoice' : 'Create Sales Invoice',
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
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        if (!widget.isEdit) ...<Widget>[
                          const _FieldLabel(label: 'Invoice Name (optional)'),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              hintText: 'Auto generated if blank',
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        const _FieldLabel(label: 'Customer *'),
                        if (_customerOptions.isNotEmpty)
                          DropdownButtonFormField<String>(
                            key: ValueKey<String>(
                              'customer-${_selectedCustomer ?? ''}-${_customerOptions.length}',
                            ),
                            initialValue: _selectedCustomer,
                            decoration: const InputDecoration(),
                            items: _customerOptions
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
                                      _selectedCustomer = value;
                                      _customerController.text = (value ?? '')
                                          .trim();
                                    });
                                  },
                            validator: (String? value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Customer is required';
                              }
                              return null;
                            },
                          )
                        else
                          TextFormField(
                            controller: _customerController,
                            decoration: const InputDecoration(
                              hintText: 'Customer',
                            ),
                            validator: (String? value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Customer is required';
                              }
                              return null;
                            },
                          ),
                        const SizedBox(height: 14),
                        const _FieldLabel(label: 'Posting Date *'),
                        TextFormField(
                          controller: _postingDateController,
                          readOnly: true,
                          decoration: InputDecoration(
                            hintText: 'YYYY-MM-DD',
                            suffixIcon: IconButton(
                              onPressed: _pickPostingDate,
                              icon: const Icon(Icons.calendar_today_outlined),
                            ),
                          ),
                          validator: (String? value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Posting date is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: <Widget>[
                            const _FieldLabel(label: 'Items *'),
                            const Spacer(),
                            OutlinedButton.icon(
                              onPressed: isBusy ? null : _addItemLine,
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Add Item'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ..._buildItemLines(isBusy),
                        const SizedBox(height: 14),
                        const _FieldLabel(label: 'Grand Total (read only)'),
                        TextFormField(
                          controller: _grandTotalController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            hintText: 'Auto calculated by ERPNext',
                          ),
                        ),
                        const SizedBox(height: 14),
                        const _FieldLabel(label: 'Status'),
                        if (_statusOptions.isNotEmpty)
                          DropdownButtonFormField<String>(
                            key: ValueKey<String>(
                              'status-${_selectedStatus ?? ''}-${_statusOptions.length}',
                            ),
                            initialValue: _selectedStatus,
                            decoration: const InputDecoration(),
                            items: _statusOptions
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
                                      _selectedStatus = value;
                                      _statusController.text = (value ?? '')
                                          .trim();
                                    });
                                  },
                          )
                        else
                          TextFormField(
                            controller: _statusController,
                            decoration: const InputDecoration(
                              hintText: 'Status (optional)',
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  List<Widget> _buildItemLines(bool isBusy) {
    final List<Widget> widgets = <Widget>[];

    for (int index = 0; index < _lines.length; index++) {
      final _SalesInvoiceLineDraft line = _lines[index];

      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    'Line ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  if (_lines.length > 1)
                    IconButton(
                      onPressed: isBusy ? null : () => _removeItemLine(index),
                      icon: const Icon(Icons.delete_outline_rounded),
                      tooltip: 'Remove line',
                    ),
                ],
              ),
              const SizedBox(height: 6),
              const _FieldLabel(label: 'Item *'),
              if (_itemOptions.isNotEmpty)
                DropdownButtonFormField<String>(
                  key: ValueKey<String>(
                    'line-item-$index-${line.selectedItemCode ?? ''}-${_itemOptions.length}',
                  ),
                  initialValue: line.selectedItemCode,
                  isExpanded: true,
                  decoration: const InputDecoration(),
                  items: _itemOptions
                      .map(
                        (SalesInvoiceItemOption option) =>
                            DropdownMenuItem<String>(
                              value: option.value,
                              child: Text(
                                option.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                      )
                      .toList(growable: false),
                  onChanged: isBusy
                      ? null
                      : (String? value) {
                          setState(() {
                            line.selectedItemCode = value;
                            line.itemCodeController.text = (value ?? '').trim();
                          });
                        },
                )
              else
                TextFormField(
                  controller: line.itemCodeController,
                  decoration: const InputDecoration(hintText: 'Item code'),
                ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const _FieldLabel(label: 'Qty *'),
                        TextFormField(
                          controller: line.qtyController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(hintText: '1'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const _FieldLabel(label: 'Rate'),
                        TextFormField(
                          controller: line.rateController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Optional',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  List<String> _mergeWithCurrent(List<String> source, String currentValue) {
    final String normalizedCurrent = currentValue.trim();
    if (normalizedCurrent.isEmpty || source.contains(normalizedCurrent)) {
      return source;
    }
    return <String>[normalizedCurrent, ...source];
  }

  List<SalesInvoiceItemOption> _mergeItemOptionsWithLines(
    List<SalesInvoiceItemOption> source,
    List<_SalesInvoiceLineDraft> lines,
  ) {
    final Map<String, SalesInvoiceItemOption> byValue =
        <String, SalesInvoiceItemOption>{
          for (final SalesInvoiceItemOption option in source)
            option.value: option,
        };

    for (final _SalesInvoiceLineDraft line in lines) {
      final String value =
          (line.selectedItemCode ?? line.itemCodeController.text).trim();
      if (value.isNotEmpty && !byValue.containsKey(value)) {
        byValue[value] = SalesInvoiceItemOption(value: value, label: value);
      }
    }

    final List<SalesInvoiceItemOption> merged = byValue.values.toList(
      growable: false,
    );
    merged.sort(
      (SalesInvoiceItemOption a, SalesInvoiceItemOption b) =>
          a.label.toLowerCase().compareTo(b.label.toLowerCase()),
    );
    return merged;
  }
}

class _SalesInvoiceLineDraft {
  _SalesInvoiceLineDraft({String? itemCode, String qty = '1', String rate = ''})
    : itemCodeController = TextEditingController(text: itemCode ?? ''),
      qtyController = TextEditingController(text: qty),
      rateController = TextEditingController(text: rate),
      selectedItemCode = (itemCode ?? '').trim().isEmpty
          ? null
          : (itemCode ?? '').trim();

  final TextEditingController itemCodeController;
  final TextEditingController qtyController;
  final TextEditingController rateController;
  String? selectedItemCode;

  void dispose() {
    itemCodeController.dispose();
    qtyController.dispose();
    rateController.dispose();
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
