import 'package:flutter/material.dart';

import '../../domain/entities/item_entity.dart';

class ItemListTile extends StatelessWidget {
  const ItemListTile({
    super.key,
    required this.item,
    required this.baseUrl,
    this.onTap,
  });

  final ItemEntity item;
  final String baseUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool narrow = screenWidth < 390;
    final TextStyle itemNameStyle = theme.textTheme.titleMedium!.copyWith(
      fontWeight: FontWeight.w800,
      height: 1.1,
    );
    final TextStyle metaStyle = theme.textTheme.labelSmall!.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
      height: 1.1,
    );
    final TextStyle qtyStyle = theme.textTheme.labelSmall!.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );
    final TextStyle priceStyle = theme.textTheme.titleMedium!.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w800,
      height: 1.1,
    );
    final String imageUrl = _resolveImageUrl(item.image);
    final String itemCode = (item.itemCode ?? '').trim();
    final String qtyText = item.stockQty == null
        ? '-'
        : item.stockQty!.toStringAsFixed(0);
    final String priceText = item.standardRate == null
        ? '-'
        : item.standardRate!.toStringAsFixed(2);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
        padding: EdgeInsets.symmetric(
          horizontal: narrow ? 10 : 12,
          vertical: narrow ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: narrow ? 52 : 56,
              height: narrow ? 52 : 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.45,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUrl.isEmpty
                  ? const Icon(Icons.inventory_2_outlined, size: 24)
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, stackTrace) =>
                          const Icon(Icons.inventory_2_outlined, size: 24),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      item.itemName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: itemNameStyle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'CODE: ${itemCode.isEmpty ? '-' : itemCode}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: metaStyle,
                    ),
                    Text(
                      'GROUP: ${item.itemGroup}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: metaStyle,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: narrow ? 104 : 118,
                maxWidth: narrow ? 104 : 118,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          'QTY: $qtyText Units',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: qtyStyle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: theme.colorScheme.outline,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\$$priceText',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: priceStyle,
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
    if (baseUrl.trim().isEmpty) {
      return '';
    }
    return '${baseUrl.trim()}$normalized';
  }
}
