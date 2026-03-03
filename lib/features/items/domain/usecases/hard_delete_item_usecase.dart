import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../repositories/item_repository.dart';

class HardDeleteItemUseCase {
  const HardDeleteItemUseCase(this._repository);

  final ItemRepository _repository;

  Future<Either<Failure, void>> execute(String id) {
    return _repository.hardDeleteItem(id);
  }
}
