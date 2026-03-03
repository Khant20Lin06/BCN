import '../../../../core/error/exception_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/paginated.dart';
import '../../domain/entities/create_item_input.dart';
import '../../domain/entities/item_entity.dart';
import '../../domain/entities/update_item_input.dart';
import '../../domain/repositories/item_repository.dart';
import '../../domain/value_objects/item_query.dart';
import '../datasources/item_local_ds.dart';
import '../datasources/item_remote_ds.dart';
import '../dtos/item_dto.dart';
import '../mappers/item_mapper.dart';

class ItemRepositoryImpl implements ItemRepository {
  ItemRepositoryImpl({
    required ItemRemoteDataSource remoteDataSource,
    required ItemLocalDataSource localDataSource,
    required ItemMapper mapper,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _mapper = mapper;

  final ItemRemoteDataSource _remoteDataSource;
  final ItemLocalDataSource _localDataSource;
  final ItemMapper _mapper;

  bool _hardDeleteAllowed = true;

  @override
  Future<Either<Failure, Paginated<ItemEntity>>> getItems(
    ItemQuery query,
  ) async {
    try {
      final List<ItemDto> remoteItems = await _remoteDataSource.fetchItems(
        query,
      );
      await _localDataSource.cacheItems(remoteItems);

      final List<ItemEntity> entities = remoteItems
          .map(_mapper.toEntity)
          .toList(growable: false);
      return Right<Failure, Paginated<ItemEntity>>(
        Paginated<ItemEntity>(
          items: entities,
          hasMore: remoteItems.length == query.limit,
          nextOffset: query.offset + remoteItems.length,
        ),
      );
    } catch (error) {
      final Failure failure = mapExceptionToFailure(error);
      // V1 offline behavior intentionally limits fallback to read-only cache.
      // We skip mutation queues to avoid hidden conflict resolution rules.
      if (_shouldUseCacheFallback(failure)) {
        final List<ItemDto> cached = await _localDataSource.getItems(query);
        final List<ItemEntity> entities = cached
            .map(_mapper.toEntity)
            .toList(growable: false);
        return Right<Failure, Paginated<ItemEntity>>(
          Paginated<ItemEntity>(
            items: entities,
            hasMore: cached.length == query.limit,
            nextOffset: query.offset + cached.length,
          ),
        );
      }

      return Left<Failure, Paginated<ItemEntity>>(failure);
    }
  }

  @override
  Future<Either<Failure, ItemEntity>> getItemDetail(String id) async {
    try {
      final ItemDto remote = await _remoteDataSource.fetchItemDetail(id);
      await _localDataSource.cacheItem(remote);
      return Right<Failure, ItemEntity>(_mapper.toEntity(remote));
    } catch (error) {
      final Failure failure = mapExceptionToFailure(error);
      if (_shouldUseCacheFallback(failure)) {
        final ItemDto? cached = await _localDataSource.getItemById(id);
        if (cached != null) {
          return Right<Failure, ItemEntity>(_mapper.toEntity(cached));
        }
      }
      return Left<Failure, ItemEntity>(failure);
    }
  }

  @override
  Future<Either<Failure, ItemEntity>> createItem(CreateItemInput input) async {
    try {
      final ItemDto created = await _remoteDataSource.createItem(input);
      await _localDataSource.cacheItem(created);
      return Right<Failure, ItemEntity>(_mapper.toEntity(created));
    } catch (error) {
      return Left<Failure, ItemEntity>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, ItemEntity>> updateItem(
    String id,
    UpdateItemInput input,
  ) async {
    try {
      final ItemDto updated = await _remoteDataSource.updateItem(id, input);
      await _localDataSource.cacheItem(updated);
      return Right<Failure, ItemEntity>(_mapper.toEntity(updated));
    } catch (error) {
      return Left<Failure, ItemEntity>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, void>> softDeleteItem(String id) async {
    try {
      await _remoteDataSource.softDeleteItem(id);
      await _localDataSource.setItemDisabled(id, true);
      return const Right<Failure, void>(null);
    } catch (error) {
      return Left<Failure, void>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, void>> hardDeleteItem(String id) async {
    try {
      await _remoteDataSource.hardDeleteItem(id);
      await _localDataSource.removeItem(id);
      return const Right<Failure, void>(null);
    } catch (error) {
      final Failure failure = mapExceptionToFailure(error);
      if (failure is ForbiddenFailure) {
        // Remember capability downgrade in-memory so UI can stop surfacing hard
        // delete actions for this session after a permission denial.
        _hardDeleteAllowed = false;
        return const Left<Failure, void>(
          ForbiddenFailure(
            message: 'Hard delete is not permitted for this account.',
          ),
        );
      }
      return Left<Failure, void>(failure);
    }
  }

  @override
  Future<Either<Failure, List<String>>> getItemGroups() async {
    try {
      final List<String> groups = await _remoteDataSource.fetchItemGroups();
      return Right<Failure, List<String>>(groups);
    } catch (error) {
      return Left<Failure, List<String>>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getUoms() async {
    try {
      final List<String> uoms = await _remoteDataSource.fetchUoms();
      return Right<Failure, List<String>>(uoms);
    } catch (error) {
      return Left<Failure, List<String>>(mapExceptionToFailure(error));
    }
  }

  bool get hardDeleteAllowed => _hardDeleteAllowed;

  bool _shouldUseCacheFallback(Failure failure) {
    return failure is NetworkFailure || failure is TimeoutFailure;
  }
}
