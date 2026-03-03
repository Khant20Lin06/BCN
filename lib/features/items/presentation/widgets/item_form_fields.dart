import 'package:flutter/material.dart';

class ItemFormFields extends StatelessWidget {
  const ItemFormFields({
    super.key,
    required this.itemCodeController,
    required this.itemCodeReadOnly,
    required this.itemNameController,
    required this.descriptionController,
    required this.valuationRateController,
    required this.itemGroupOptions,
    required this.uomOptions,
    required this.selectedItemGroup,
    required this.selectedUom,
    required this.disabled,
    required this.hasVariants,
    required this.onItemGroupChanged,
    required this.onUomChanged,
    required this.onDisabledChanged,
    required this.onHasVariantsChanged,
  });

  final TextEditingController itemCodeController;
  final bool itemCodeReadOnly;
  final TextEditingController itemNameController;
  final TextEditingController descriptionController;
  final TextEditingController valuationRateController;
  final List<String> itemGroupOptions;
  final List<String> uomOptions;
  final String? selectedItemGroup;
  final String? selectedUom;
  final bool disabled;
  final bool hasVariants;
  final ValueChanged<String?> onItemGroupChanged;
  final ValueChanged<String?> onUomChanged;
  final ValueChanged<bool> onDisabledChanged;
  final ValueChanged<bool> onHasVariantsChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _FieldLabel(label: 'Item Code *'),
        TextField(
          controller: itemCodeController,
          readOnly: itemCodeReadOnly,
          decoration: InputDecoration(
            hintText: itemCodeReadOnly ? null : 'Ex: ITEM-0001',
          ),
        ),
        const SizedBox(height: 14),
        _FieldLabel(label: 'Item Name *'),
        TextField(controller: itemNameController),
        const SizedBox(height: 14),
        _FieldLabel(label: 'Item Group *'),
        DropdownButtonFormField<String>(
          key: ValueKey<String?>(selectedItemGroup),
          initialValue: selectedItemGroup,
          items: itemGroupOptions
              .map(
                (String value) =>
                    DropdownMenuItem<String>(value: value, child: Text(value)),
              )
              .toList(growable: false),
          onChanged: onItemGroupChanged,
          decoration: const InputDecoration(),
        ),
        const SizedBox(height: 14),
        _FieldLabel(label: 'Default Unit of Measure *'),
        DropdownButtonFormField<String>(
          key: ValueKey<String?>(selectedUom),
          initialValue: selectedUom,
          items: uomOptions
              .map(
                (String value) =>
                    DropdownMenuItem<String>(value: value, child: Text(value)),
              )
              .toList(growable: false),
          onChanged: onUomChanged,
          decoration: const InputDecoration(),
        ),
        const SizedBox(height: 14),
        _FieldLabel(label: 'Description'),
        TextField(controller: descriptionController, maxLines: 4, minLines: 3),
        const SizedBox(height: 14),
        _FieldLabel(label: 'Valuation Rate'),
        TextField(
          controller: valuationRateController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Disabled'),
          value: disabled,
          onChanged: onDisabledChanged,
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Has Variants'),
          value: hasVariants,
          onChanged: onHasVariantsChanged,
        ),
      ],
    );
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
