import 'package:flutter/material.dart';

class ItemFormFields extends StatelessWidget {
  const ItemFormFields({
    super.key,
    required this.itemCodeController,
    required this.itemCodeReadOnly,
    required this.itemNameController,
    required this.openingStockController,
    required this.valuationRateController,
    required this.standardRateController,
    required this.itemGroupOptions,
    required this.uomOptions,
    required this.selectedItemGroup,
    required this.selectedUom,
    required this.maintainStock,
    required this.isFixedAsset,
    required this.onItemGroupChanged,
    required this.onUomChanged,
    required this.onMaintainStockChanged,
    required this.onIsFixedAssetChanged,
  });

  final TextEditingController itemCodeController;
  final bool itemCodeReadOnly;
  final TextEditingController itemNameController;
  final TextEditingController openingStockController;
  final TextEditingController valuationRateController;
  final TextEditingController standardRateController;
  final List<String> itemGroupOptions;
  final List<String> uomOptions;
  final String? selectedItemGroup;
  final String? selectedUom;
  final bool maintainStock;
  final bool isFixedAsset;
  final ValueChanged<String?> onItemGroupChanged;
  final ValueChanged<String?> onUomChanged;
  final ValueChanged<bool> onMaintainStockChanged;
  final ValueChanged<bool> onIsFixedAssetChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _FieldLabel(label: 'Item Code', required: true),
        TextField(
          controller: itemCodeController,
          readOnly: itemCodeReadOnly,
          decoration: InputDecoration(
            hintText: itemCodeReadOnly ? null : 'Ex: ITEM-0001',
          ),
        ),
        const SizedBox(height: 12),
        const _FieldLabel(label: 'Item Name'),
        TextField(controller: itemNameController),
        const SizedBox(height: 12),
        const _FieldLabel(label: 'Item Group', required: true),
        DropdownButtonFormField<String>(
          key: ValueKey<String?>(selectedItemGroup),
          initialValue: selectedItemGroup,
          isExpanded: true,
          items: itemGroupOptions
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
          onChanged: onItemGroupChanged,
          decoration: const InputDecoration(),
        ),
        const SizedBox(height: 12),
        const _FieldLabel(label: 'Default Unit of Measure', required: true),
        DropdownButtonFormField<String>(
          key: ValueKey<String?>(selectedUom),
          initialValue: selectedUom,
          isExpanded: true,
          items: uomOptions
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
          onChanged: onUomChanged,
          decoration: const InputDecoration(),
        ),
        const SizedBox(height: 6),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          visualDensity: VisualDensity.compact,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('Maintain Stock'),
          value: maintainStock,
          onChanged: (bool? value) => onMaintainStockChanged(value ?? false),
        ),
        const SizedBox(height: 8),
        const _FieldLabel(label: 'Opening Stock'),
        TextField(
          controller: openingStockController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: '0.00'),
        ),
        const SizedBox(height: 12),
        const _FieldLabel(label: 'Valuation Rate'),
        TextField(
          controller: valuationRateController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: '0.00'),
        ),
        const SizedBox(height: 12),
        const _FieldLabel(label: 'Standard Selling Rate'),
        TextField(
          controller: standardRateController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: '0.00'),
        ),
        const SizedBox(height: 6),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          visualDensity: VisualDensity.compact,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('Is Fixed Asset'),
          value: isFixedAsset,
          onChanged: (bool? value) => onIsFixedAssetChanged(value ?? false),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, this.required = false});

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
      padding: const EdgeInsets.only(bottom: 6),
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
