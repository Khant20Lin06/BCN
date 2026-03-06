import 'package:flutter/material.dart';

class FilterChipBar extends StatelessWidget {
  const FilterChipBar({
    super.key,
    required this.itemGroups,
    required this.selectedItemGroup,
    required this.selectedDisabled,
    required this.onItemGroupChanged,
    required this.onDisabledChanged,
  });

  final List<String> itemGroups;
  final String? selectedItemGroup;
  final bool? selectedDisabled;
  final ValueChanged<String?> onItemGroupChanged;
  final ValueChanged<bool?> onDisabledChanged;

  @override
  Widget build(BuildContext context) {
    final TextStyle chipLabelStyle = Theme.of(
      context,
    ).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w700);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('All', style: chipLabelStyle),
              selected: selectedItemGroup == null,
              onSelected: (_) => onItemGroupChanged(null),
            ),
          ),
          ...itemGroups.map(
            (String group) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(group, style: chipLabelStyle),
                selected: selectedItemGroup == group,
                onSelected: (_) => onItemGroupChanged(group),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('Active', style: chipLabelStyle),
              selected: selectedDisabled == false,
              onSelected: (_) =>
                  onDisabledChanged(selectedDisabled == false ? null : false),
            ),
          ),
          ChoiceChip(
            label: Text('Inactive', style: chipLabelStyle),
            selected: selectedDisabled == true,
            onSelected: (_) =>
                onDisabledChanged(selectedDisabled == true ? null : true),
          ),
        ],
      ),
    );
  }
}
