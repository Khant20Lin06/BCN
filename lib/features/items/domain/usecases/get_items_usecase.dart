import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/paginated.dart';
import '../entities/item_entity.dart';
import '../repositories/item_repository.dart';
import '../value_objects/item_query.dart';

class GetItemsUseCase {
  const GetItemsUseCase(this._repository);

  final ItemRepository _repository;

  Future<Either<Failure, Paginated<ItemEntity>>> execute(ItemQuery query) {
    return _repository.getItems(query);
  }
}
