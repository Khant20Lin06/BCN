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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('All'),
              selected: selectedItemGroup == null,
              onSelected: (_) => onItemGroupChanged(null),
            ),
          ),
          ...itemGroups.map(
            (String group) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(group),
                selected: selectedItemGroup == group,
                onSelected: (_) => onItemGroupChanged(group),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('Enabled'),
              selected: selectedDisabled == false,
              onSelected: (_) =>
                  onDisabledChanged(selectedDisabled == false ? null : false),
            ),
          ),
          ChoiceChip(
            label: const Text('Disabled'),
            selected: selectedDisabled == true,
            onSelected: (_) =>
                onDisabledChanged(selectedDisabled == true ? null : true),
          ),
        ],
      ),
    );
  }
}
