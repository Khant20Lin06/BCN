import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/item_entity.dart';
import 'status_toggle.dart';

class ItemListTile extends StatelessWidget {
  const ItemListTile({
    super.key,
    required this.item,
    required this.onTap,
    required this.onStatusChanged,
  });

  final ItemEntity item;
  final VoidCallback onTap;
  final ValueChanged<bool> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final String imageUrl = _resolveImageUrl(item.image);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUrl.isEmpty
                  ? const Icon(Icons.inventory_2_outlined)
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, stackTrace) =>
                          const Icon(Icons.inventory_2_outlined),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.itemName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.itemGroup} • ${item.stockUom}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (item.itemCode != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      'Code: ${item.itemCode}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusToggle(
              value: !item.disabled,
              onChanged: (bool enabled) => onStatusChanged(!enabled),
            ),
          ],
        ),
      ),
    );
  }

  String _resolveImageUrl(String? value) {
    final String normalized = (value ?? '').trim();
    if (normalized.isEmpty) {
      return '';
    }
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return normalized;
    }
    return '${ApiConstants.baseUrl}$normalized';
  }
}
