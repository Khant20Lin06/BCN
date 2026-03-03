import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../entities/create_item_input.dart';
import '../entities/item_entity.dart';
import '../repositories/item_repository.dart';

class CreateItemUseCase {
  const CreateItemUseCase(this._repository);

  final ItemRepository _repository;

  Future<Either<Failure, ItemEntity>> execute(CreateItemInput input) {
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

    return _repository.createItem(input);
  }
}
