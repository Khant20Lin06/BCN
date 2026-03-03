import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../entities/item_entity.dart';
import '../repositories/item_repository.dart';

class GetItemDetailUseCase {
  const GetItemDetailUseCase(this._repository);

  final ItemRepository _repository;

  Future<Either<Failure, ItemEntity>> execute(String id) {
    return _repository.getItemDetail(id);
  }
}
