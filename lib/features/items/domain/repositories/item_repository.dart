import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/paginated.dart';
import '../entities/create_item_input.dart';
import '../entities/item_entity.dart';
import '../entities/update_item_input.dart';
import '../value_objects/item_query.dart';

abstract class ItemRepository {
  Future<Either<Failure, Paginated<ItemEntity>>> getItems(ItemQuery query);

  Future<Either<Failure, ItemEntity>> getItemDetail(String id);

  Future<Either<Failure, ItemEntity>> createItem(CreateItemInput input);

  Future<Either<Failure, ItemEntity>> updateItem(
    String id,
    UpdateItemInput input,
  );

  Future<Either<Failure, void>> softDeleteItem(String id);

  Future<Either<Failure, void>> hardDeleteItem(String id);

  Future<Either<Failure, List<String>>> getItemGroups();

  Future<Either<Failure, List<String>>> getUoms();
}
