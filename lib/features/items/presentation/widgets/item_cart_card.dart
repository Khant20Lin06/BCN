import 'package:flutter/material.dart';

import '../../domain/entities/item_entity.dart';

class ItemCartCard extends StatelessWidget {
  const ItemCartCard({
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
    final TextStyle chipStyle = theme.textTheme.labelSmall!.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: 0.2,
    );
    final TextStyle titleStyle = theme.textTheme.titleSmall!.copyWith(
      fontWeight: FontWeight.w800,
      height: 1.1,
    );
    final TextStyle metaStyle = theme.textTheme.labelSmall!.copyWith(
      fontWeight: FontWeight.w600,
      height: 1.15,
      color: theme.colorScheme.onSurfaceVariant,
    );
    final TextStyle priceStyle = theme.textTheme.titleMedium!.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w900,
      height: 1.0,
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
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
        child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          color: theme.colorScheme.surface,
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: <Widget>[
                    Container(
                      width: double.infinity,
                      height: 130,
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.42),
                      child: imageUrl.isEmpty
                          ? Icon(
                              Icons.inventory_2_outlined,
                              size: 42,
                              color: theme.colorScheme.onSurfaceVariant,
                            )
                          : Image.network(
                              imageUrl,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, error, stackTrace) => Icon(
                                Icons.broken_image_outlined,
                                size: 38,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _StockChip(
                        unitsLabel: '$qtyText UNITS',
                        textStyle: chipStyle,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.itemName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: titleStyle,
              ),
              const SizedBox(height: 2),
              Text(
                itemCode.isEmpty ? '-' : itemCode,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: metaStyle,
              ),
              const SizedBox(height: 1),
              Text(
                item.itemGroup,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: metaStyle,
              ),
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.centerRight,
                child: Text('\$$priceText', style: priceStyle),
              ),
            ],
          ),
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

class _StockChip extends StatelessWidget {
  const _StockChip({required this.unitsLabel, required this.textStyle});

  final String unitsLabel;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFF2BBE5E),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(unitsLabel, style: textStyle),
        ],
      ),
    );
  }
}
