import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/item_entity.dart';

class ItemCartCard extends StatelessWidget {
  const ItemCartCard({super.key, required this.item, this.onTap});

  final ItemEntity item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final String imageUrl = _resolveImageUrl(item.image);
    final ThemeData theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          color: theme.colorScheme.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: imageUrl.isEmpty
                    ? Container(
                        width: double.infinity,
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.35),
                        child: const Icon(Icons.inventory_2_outlined, size: 34),
                      )
                    : Image.network(
                        imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, error, stackTrace) => Container(
                          width: double.infinity,
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.35),
                          child: const Icon(
                            Icons.broken_image_outlined,
                            size: 30,
                          ),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.itemName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (item.itemCode ?? '-').trim().isEmpty
                        ? '-'
                        : item.itemCode!.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Price: ${item.standardRate?.toStringAsFixed(2) ?? '-'}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Qty: ${item.stockQty?.toStringAsFixed(2) ?? '-'}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
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
