import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../repositories/item_repository.dart';

class GetUomsUseCase {
  const GetUomsUseCase(this._repository);

  final ItemRepository _repository;

  Future<Either<Failure, List<String>>> execute() {
    return _repository.getUoms();
  }
}
