import 'package:flutter_test/flutter_test.dart';
import 'package:frappe_mobile_item_app/features/items/data/dtos/item_dto.dart';
import 'package:frappe_mobile_item_app/features/items/data/mappers/item_mapper.dart';

void main() {
  group('ItemMapper', () {
    test('maps int flags to bool fields correctly', () {
      const dto = ItemDto(
        id: 'ITEM-0001',
        itemCode: null,
        itemName: 'Galaxy Earbuds Pro',
        itemGroup: 'Electronics',
        stockUom: 'Nos',
        description: 'desc',
        disabled: 1,
        hasVariants: 0,
        valuationRate: 199,
        modified: null,
      );

      final mapper = ItemMapper();
      final entity = mapper.toEntity(dto);

      expect(entity.disabled, isTrue);
      expect(entity.hasVariants, isFalse);
      expect(entity.valuationRate, 199.0);
    });
  });
}
