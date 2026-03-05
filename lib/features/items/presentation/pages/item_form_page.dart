import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../controllers/item_form_controller.dart';
import '../controllers/items_controller.dart';
import '../state/item_form_state.dart';
import '../widgets/item_form_fields.dart';

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
    _openingStockController = TextEditingController(text: '0.00');
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

    if (_selectedUom == null && state.uoms.isNotEmpty) {
      _selectedUom = state.uoms.first;
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
                  widget.isEdit
                      ? 'Item Update information'
                      : 'Item Creation information',
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
                        height: 16,
                        width: 16,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (state.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            state.errorMessage!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ItemFormFields(
                        itemCodeController: _itemCodeController,
                        itemCodeReadOnly: widget.isEdit,
                        itemNameController: _itemNameController,
                        openingStockController: _openingStockController,
                        valuationRateController: _valuationController,
                        standardRateController: _standardRateController,
                        itemGroupOptions: state.itemGroups,
                        uomOptions: state.uoms,
                        selectedItemGroup: _selectedItemGroup,
                        selectedUom: _selectedUom,
                        maintainStock: _maintainStock,
                        isFixedAsset: _isFixedAsset,
                        onItemGroupChanged: (String? value) =>
                            setState(() => _selectedItemGroup = value),
                        onUomChanged: (String? value) =>
                            setState(() => _selectedUom = value),
                        onMaintainStockChanged: (bool value) =>
                            setState(() => _maintainStock = value),
                        onIsFixedAssetChanged: (bool value) =>
                            setState(() => _isFixedAsset = value),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if ((!widget.isEdit && _itemCodeController.text.trim().isEmpty) ||
        _itemNameController.text.trim().isEmpty ||
        (_selectedItemGroup == null || _selectedItemGroup!.isEmpty) ||
        (_selectedUom == null || _selectedUom!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Item Code, Item Name, Item Group and UOM are required.',
          ),
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opening Stock must be a valid number.')),
      );
      return;
    }

    if (_valuationController.text.trim().isNotEmpty && valuation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valuation Rate must be a valid number.')),
      );
      return;
    }

    if (_standardRateController.text.trim().isNotEmpty &&
        standardRate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Standard Selling Rate must be a valid number.'),
        ),
      );
      return;
    }

    final ItemFormController controller = ref.read(
      itemFormControllerProvider.notifier,
    );

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
            itemCode: _itemCodeController.text,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
      return;
    }

    await ref.read(itemsControllerProvider.notifier).refresh();
    if (mounted) {
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
      return '0.00';
    }
    return value.toString();
  }
}
