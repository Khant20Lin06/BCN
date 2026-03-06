import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/item_entity.dart';

class ItemListTile extends StatelessWidget {
  const ItemListTile({super.key, required this.item, this.onTap});

  final ItemEntity item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
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
      color: const Color(0xFF0D6B61),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool compact = constraints.maxWidth < 390;
            final Widget thumbnail = Container(
              width: compact ? 52 : 56,
              height: compact ? 52 : 56,
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
            );

            final Widget metaBlock = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.itemName,
                  maxLines: compact ? 2 : 1,
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
            );

            final Widget qtyPriceBlock = Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('QTY: $qtyText Units', style: qtyStyle),
                const SizedBox(height: 4),
                Text('\$$priceText', style: priceStyle),
              ],
            );

            if (compact) {
              return Column(
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      thumbnail,
                      const SizedBox(width: 10),
                      Expanded(child: metaBlock),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: theme.colorScheme.outline,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: qtyPriceBlock,
                  ),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                thumbnail,
                const SizedBox(width: 10),
                Expanded(child: metaBlock),
                const SizedBox(width: 6),
                qtyPriceBlock,
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: theme.colorScheme.outline,
                ),
              ],
            );
          },
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
