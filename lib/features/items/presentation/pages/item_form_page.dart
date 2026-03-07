import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/feedback/app_feedback.dart';
import '../controllers/item_form_controller.dart';
import '../controllers/items_controller.dart';
import '../state/item_form_state.dart';

class ItemFormPage extends ConsumerStatefulWidget {
  const ItemFormPage({super.key, this.itemId});

  final String? itemId;

  bool get isEdit => itemId != null;

  @override
  ConsumerState<ItemFormPage> createState() => _ItemFormPageState();
}

class _ItemFormPageState extends ConsumerState<ItemFormPage> {
  late final TextEditingController _itemCodeController;
  late final TextEditingController _itemNameController;
  late final TextEditingController _openingStockController;
  late final TextEditingController _valuationController;
  late final TextEditingController _standardRateController;

  String? _selectedItemGroup;
  String? _selectedUom;
  bool _disabled = false;
  bool _hasVariants = false;
  bool _maintainStock = true;
  bool _isFixedAsset = false;
  bool _hydratedFromItem = false;
  String? _existingDescription;

  @override
  void initState() {
    super.initState();
    _itemCodeController = TextEditingController();
    _itemNameController = TextEditingController();
    _openingStockController = TextEditingController(text: '0');
    _valuationController = TextEditingController(text: '0.00');
    _standardRateController = TextEditingController(text: '0.00');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(itemFormControllerProvider.notifier)
          .initialize(itemId: widget.itemId);
    });
  }

  @override
  void dispose() {
    _itemCodeController.dispose();
    _itemNameController.dispose();
    _openingStockController.dispose();
    _valuationController.dispose();
    _standardRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ItemFormState state = ref.watch(itemFormControllerProvider);

    if (!_hydratedFromItem && state.item != null) {
      _hydratedFromItem = true;
      _itemCodeController.text = state.item!.itemCode ?? '';
      _itemNameController.text = state.item!.itemName;
      _openingStockController.text = _displayNumber(state.item!.stockQty);
      _valuationController.text = _displayNumber(state.item!.valuationRate);
      _standardRateController.text = _displayNumber(state.item!.standardRate);
      _selectedItemGroup = state.item!.itemGroup;
      _selectedUom = state.item!.stockUom;
      _disabled = state.item!.disabled;
      _hasVariants = state.item!.hasVariants;
      _maintainStock = state.item!.maintainStock;
      _isFixedAsset = state.item!.isFixedAsset;
      _existingDescription = state.item!.description;
    }

    if (_selectedItemGroup == null && state.itemGroups.isNotEmpty) {
      _selectedItemGroup = state.itemGroups.first;
    }
    if (_selectedItemGroup != null &&
        !state.itemGroups.contains(_selectedItemGroup)) {
      _selectedItemGroup = state.itemGroups.isEmpty
          ? null
          : state.itemGroups.first;
    }

    if (_selectedUom == null && state.uoms.isNotEmpty) {
      _selectedUom = state.uoms.first;
    }
    if (_selectedUom != null && !state.uoms.contains(_selectedUom)) {
      _selectedUom = state.uoms.isEmpty ? null : state.uoms.first;
    }

    final bool isBusy =
        state.status == ItemFormStatus.loading ||
        state.status == ItemFormStatus.submitting;

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
                  widget.isEdit ? 'Edit Item' : 'Create Item',
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
          child: state.status == ItemFormStatus.loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (state.errorMessage != null)
                        AppLoadErrorReporter(
                          message: state.errorMessage!,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              state.errorMessage!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ),
                      const _SectionTitle('General Information'),
                      const SizedBox(height: 8),
                      const _FieldLabel(
                        'Item Code (Auto-generated)',
                        required: false,
                      ),
                      TextField(
                        controller: _itemCodeController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          hintText: 'Auto generated by ERPNext',
                          prefixIcon: Icon(Icons.lock_outline_rounded),
                          suffixIcon: Icon(Icons.qr_code_2_rounded),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _FieldLabelRow(
                        label: 'Item Name',
                        trailing: Text(
                          '* required',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextField(
                        controller: _itemNameController,
                        decoration: const InputDecoration(
                          hintText: 'Wireless Charging Pad',
                        ),
                      ),
                      const SizedBox(height: 10),
                      const _FieldLabel('Item Group', required: true),
                      DropdownButtonFormField<String>(
                        key: ValueKey<String?>(_selectedItemGroup),
                        initialValue: _selectedItemGroup,
                        isExpanded: true,
                        items: state.itemGroups
                            .map(
                              (String value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (String? value) =>
                            setState(() => _selectedItemGroup = value),
                        decoration: const InputDecoration(
                          suffixIcon: Icon(Icons.search_rounded),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _SectionTitle('Units & Stock'),
                      const SizedBox(height: 8),
                      const _FieldLabel(
                        'UOM (Unit of Measure)',
                        required: true,
                      ),
                      DropdownButtonFormField<String>(
                        key: ValueKey<String?>(_selectedUom),
                        initialValue: _selectedUom,
                        isExpanded: true,
                        items: state.uoms
                            .map(
                              (String value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (String? value) =>
                            setState(() => _selectedUom = value),
                        decoration: const InputDecoration(),
                      ),
                      if (_selectedUom != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 3, left: 4),
                          child: Text(
                            _selectedUom!,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      const SizedBox(height: 6),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _maintainStock,
                        onChanged: (bool? value) =>
                            setState(() => _maintainStock = value ?? false),
                        title: const Text('Maintain Stock'),
                      ),
                      const SizedBox(height: 8),
                      const _FieldLabel('Opening Qty', required: false),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextField(
                              controller: _openingStockController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(hintText: '0'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _QtyStepper(
                            onIncrement: () => _adjustOpeningStock(1),
                            onDecrement: () => _adjustOpeningStock(-1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Current stock: [date]',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 16),
                      const _SectionTitle('Pricing & Costing'),
                      const SizedBox(height: 8),
                      const _FieldLabel('Valuation Rate'),
                      TextField(
                        controller: _valuationController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(prefixText: '\$ '),
                      ),
                      const SizedBox(height: 10),
                      const _FieldLabel('Standard Selling Price'),
                      TextField(
                        controller: _standardRateController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(prefixText: '\$ '),
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _isFixedAsset,
                        onChanged: (bool? value) =>
                            setState(() => _isFixedAsset = value ?? false),
                        title: const Text('Is Fixed Asset'),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  void _adjustOpeningStock(double delta) {
    final double current =
        _tryParseNumber(_openingStockController.text.trim()) ?? 0;
    final double next = (current + delta).clamp(0, 999999);
    setState(() {
      _openingStockController.text = _displayNumber(next);
    });
  }

  Future<void> _save() async {
    if (_itemNameController.text.trim().isEmpty ||
        (_selectedItemGroup == null || _selectedItemGroup!.isEmpty) ||
        (_selectedUom == null || _selectedUom!.isEmpty)) {
      context.showAppError('Item Name, Item Group and UOM are required.');
      return;
    }

    final double? openingStock = _tryParseNumber(
      _openingStockController.text.trim(),
    );
    final double? valuation = _tryParseNumber(_valuationController.text.trim());
    final double? standardRate = _tryParseNumber(
      _standardRateController.text.trim(),
    );

    if (_openingStockController.text.trim().isNotEmpty &&
        openingStock == null) {
      context.showAppError('Opening Qty must be a valid number.');
      return;
    }

    if (_valuationController.text.trim().isNotEmpty && valuation == null) {
      context.showAppError('Valuation Rate must be a valid number.');
      return;
    }

    if (_standardRateController.text.trim().isNotEmpty &&
        standardRate == null) {
      context.showAppError('Standard Selling Price must be a valid number.');
      return;
    }

    final ItemFormController controller = ref.read(
      itemFormControllerProvider.notifier,
    );

    final String? itemCodeForCreate = _itemCodeController.text.trim().isEmpty
        ? null
        : _itemCodeController.text;

    final Failure? failure = widget.isEdit
        ? await controller.submitUpdate(
            id: widget.itemId!,
            itemName: _itemNameController.text,
            itemGroup: _selectedItemGroup!,
            stockUom: _selectedUom!,
            image: null,
            description: _existingDescription,
            disabled: _disabled,
            hasVariants: _hasVariants,
            maintainStock: _maintainStock,
            openingStock: openingStock,
            valuationRate: valuation,
            standardRate: standardRate,
            isFixedAsset: _isFixedAsset,
          )
        : await controller.submitCreate(
            itemCode: itemCodeForCreate,
            itemName: _itemNameController.text,
            itemGroup: _selectedItemGroup!,
            stockUom: _selectedUom!,
            image: null,
            description: null,
            disabled: _disabled,
            hasVariants: _hasVariants,
            maintainStock: _maintainStock,
            openingStock: openingStock,
            valuationRate: valuation,
            standardRate: standardRate,
            isFixedAsset: _isFixedAsset,
          );

    if (!mounted) {
      return;
    }

    if (failure != null) {
      context.showAppFailure(failure);
      return;
    }

    await ref.read(itemsControllerProvider.notifier).refresh();
    if (mounted) {
      context.showAppSuccess(
        widget.isEdit ? 'Item updated.' : 'Item created.',
      );
      context.pop(true);
    }
  }

  double? _tryParseNumber(String text) {
    if (text.isEmpty) {
      return null;
    }
    return double.tryParse(text);
  }

  String _displayNumber(double? value) {
    if (value == null) {
      return '0';
    }
    final String raw = value.toStringAsFixed(2);
    if (raw.endsWith('.00')) {
      return raw.substring(0, raw.length - 3);
    }
    if (raw.endsWith('0')) {
      return raw.substring(0, raw.length - 1);
    }
    return raw;
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label, {this.required = false});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final TextStyle style =
        Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600) ??
        const TextStyle(fontWeight: FontWeight.w600);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: style,
          children: <InlineSpan>[
            TextSpan(text: label),
            if (required)
              TextSpan(
                text: ' *',
                style: style.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabelRow extends StatelessWidget {
  const _FieldLabelRow({required this.label, required this.trailing});

  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: <Widget>[
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          trailing,
        ],
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({required this.onIncrement, required this.onDecrement});

  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: onIncrement,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add_rounded),
          ),
          Container(
            width: 1,
            height: 22,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          IconButton(
            onPressed: onDecrement,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove_rounded),
          ),
        ],
      ),
    );
  }
}
