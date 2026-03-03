import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../entities/item_entity.dart';
import '../entities/update_item_input.dart';
import '../repositories/item_repository.dart';

class UpdateItemUseCase {
  const UpdateItemUseCase(this._repository);

  final ItemRepository _repository;

  Future<Either<Failure, ItemEntity>> execute(
    String id,
    UpdateItemInput input,
  ) {
    if (input.itemName.trim().isEmpty ||
        input.itemGroup.trim().isEmpty ||
        input.stockUom.trim().isEmpty) {
      return Future<Either<Failure, ItemEntity>>.value(
        const Left<Failure, ItemEntity>(
          ValidationFailure(
            message: 'Item Name, Item Group and UOM are required.',
          ),
        ),
      );
    }

    if (input.valuationRate != null && input.valuationRate! < 0) {
      return Future<Either<Failure, ItemEntity>>.value(
        const Left<Failure, ItemEntity>(
          ValidationFailure(
            message: 'Valuation Rate must be greater or equal to 0.',
          ),
        ),
      );
    }

    return _repository.updateItem(id, input);
  }
}
