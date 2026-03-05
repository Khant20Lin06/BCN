import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/dio_factory.dart';
import '../../../../core/network/frappe_api_client.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/datasources/item_local_ds.dart';
import '../../data/datasources/item_remote_ds.dart';
import '../../data/mappers/item_mapper.dart';
import '../../data/repositories/item_repository_impl.dart';
import '../../domain/entities/item_entity.dart';
import '../../domain/entities/update_item_input.dart';
import '../../domain/repositories/item_repository.dart';
import '../../domain/usecases/get_item_groups_usecase.dart';
import '../../domain/usecases/get_items_usecase.dart';
import '../../domain/usecases/get_uoms_usecase.dart';
import '../../domain/usecases/hard_delete_item_usecase.dart';
import '../../domain/usecases/soft_delete_item_usecase.dart';
import '../../domain/usecases/update_item_usecase.dart';
import '../../domain/value_objects/item_query.dart';
import '../state/items_state.dart';
import '../../../../core/storage/local_database.dart';
import '../../domain/usecases/get_item_detail_usecase.dart';

final itemMapperProvider = Provider<ItemMapper>(
  (Ref ref) => const ItemMapper(),
);

final frappeApiClientProvider = Provider<FrappeApiClient>((Ref ref) {
  return FrappeApiClient(
    storageService: ref.watch(secureStorageServiceProvider),
    dioFactory: DioFactory(ref.watch(appLoggerProvider)),
  );
});

final itemRepositoryProvider = Provider<ItemRepository>((Ref ref) {
  return ItemRepositoryImpl(
    remoteDataSource: ItemRemoteDataSource(
      apiClient: ref.watch(frappeApiClientProvider),
      mapper: ref.watch(itemMapperProvider),
    ),
    localDataSource: ItemLocalDataSource(
      database: ref.watch(localDatabaseProvider),
      mapper: ref.watch(itemMapperProvider),
    ),
    mapper: ref.watch(itemMapperProvider),
  );
});

final getItemsUseCaseProvider = Provider<GetItemsUseCase>((Ref ref) {
  return GetItemsUseCase(ref.watch(itemRepositoryProvider));
});

final getItemDetailUseCaseProvider = Provider<GetItemDetailUseCase>((Ref ref) {
  return GetItemDetailUseCase(ref.watch(itemRepositoryProvider));
});

final updateItemUseCaseProvider = Provider<UpdateItemUseCase>((Ref ref) {
  return UpdateItemUseCase(ref.watch(itemRepositoryProvider));
});

final softDeleteUseCaseProvider = Provider<SoftDeleteItemUseCase>((Ref ref) {
  return SoftDeleteItemUseCase(ref.watch(itemRepositoryProvider));
});

final hardDeleteUseCaseProvider = Provider<HardDeleteItemUseCase>((Ref ref) {
  return HardDeleteItemUseCase(ref.watch(itemRepositoryProvider));
});

final getItemGroupsUseCaseProvider = Provider<GetItemGroupsUseCase>((Ref ref) {
  return GetItemGroupsUseCase(ref.watch(itemRepositoryProvider));
});

final getUomsUseCaseProvider = Provider<GetUomsUseCase>((Ref ref) {
  return GetUomsUseCase(ref.watch(itemRepositoryProvider));
});

final itemDetailProvider = FutureProvider.family<ItemEntity, String>((
  Ref ref,
  String id,
) async {
  final result = await ref.watch(getItemDetailUseCaseProvider).execute(id);
  return result.fold(
    (Failure failure) => throw Exception(failure.message),
    (ItemEntity item) => item,
  );
});

final itemsControllerProvider =
    StateNotifierProvider<ItemsController, ItemsState>((Ref ref) {
      return ItemsController(
        getItemsUseCase: ref.watch(getItemsUseCaseProvider),
        getItemGroupsUseCase: ref.watch(getItemGroupsUseCaseProvider),
        updateItemUseCase: ref.watch(updateItemUseCaseProvider),
        softDeleteItemUseCase: ref.watch(softDeleteUseCaseProvider),
        hardDeleteItemUseCase: ref.watch(hardDeleteUseCaseProvider),
      );
    });

class ItemsController extends StateNotifier<ItemsState> {
  ItemsController({
    required GetItemsUseCase getItemsUseCase,
    required GetItemGroupsUseCase getItemGroupsUseCase,
    required UpdateItemUseCase updateItemUseCase,
    required SoftDeleteItemUseCase softDeleteItemUseCase,
    required HardDeleteItemUseCase hardDeleteItemUseCase,
  }) : _getItemsUseCase = getItemsUseCase,
       _getItemGroupsUseCase = getItemGroupsUseCase,
       _updateItemUseCase = updateItemUseCase,
       _softDeleteItemUseCase = softDeleteItemUseCase,
       _hardDeleteItemUseCase = hardDeleteItemUseCase,
       super(const ItemsState.initial());

  final GetItemsUseCase _getItemsUseCase;
  final GetItemGroupsUseCase _getItemGroupsUseCase;
  final UpdateItemUseCase _updateItemUseCase;
  final SoftDeleteItemUseCase _softDeleteItemUseCase;
  final HardDeleteItemUseCase _hardDeleteItemUseCase;

  Timer? _searchDebounce;

  Future<void> loadInitial() async {
    state = state.copyWith(
      status: ItemsStatus.loading,
      query: state.query.copyWith(offset: 0),
      errorMessage: null,
    );

    if (state.itemGroups.isEmpty) {
      await _loadItemGroups();
    }

    final result = await _getItemsUseCase.execute(
      state.query.copyWith(offset: 0),
    );

    state = result.fold(
      (Failure failure) => state.copyWith(
        status: ItemsStatus.error,
        errorMessage: failure.message,
      ),
      (paginated) {
        final status = paginated.items.isEmpty
            ? ItemsStatus.empty
            : ItemsStatus.success;
        return state.copyWith(
          status: status,
          items: paginated.items,
          hasMore: paginated.hasMore,
          query: state.query.copyWith(offset: paginated.nextOffset),
          clearSelectedItem: true,
          errorMessage: null,
        );
      },
    );
  }

  Future<void> refresh() async {
    await loadInitial();
  }

  Future<void> loadNextPage() async {
    if (state.status == ItemsStatus.loading ||
        state.status == ItemsStatus.paginating ||
        !state.hasMore) {
      return;
    }

    state = state.copyWith(status: ItemsStatus.paginating, errorMessage: null);

    final result = await _getItemsUseCase.execute(state.query);

    state = result.fold(
      (Failure failure) => state.copyWith(
        status: ItemsStatus.error,
        errorMessage: failure.message,
      ),
      (paginated) {
        final merged = <ItemEntity>[...state.items, ...paginated.items];
        return state.copyWith(
          status: merged.isEmpty ? ItemsStatus.empty : ItemsStatus.success,
          items: merged,
          hasMore: paginated.hasMore,
          query: state.query.copyWith(offset: paginated.nextOffset),
          errorMessage: null,
        );
      },
    );
  }

  void onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      final String normalized = value.trim();
      state = state.copyWith(
        query: state.query.copyWith(search: normalized, offset: 0),
      );
      unawaited(loadInitial());
    });
  }

  void onItemGroupChanged(String? group) {
    state = state.copyWith(
      query: state.query.copyWith(
        itemGroup: group,
        clearItemGroup: group == null,
        offset: 0,
      ),
    );
    unawaited(loadInitial());
  }

  void onDisabledFilterChanged(bool? disabled) {
    state = state.copyWith(
      query: state.query.copyWith(
        disabled: disabled,
        clearDisabled: disabled == null,
        offset: 0,
      ),
    );
    unawaited(loadInitial());
  }

  void onViewModeChanged(ItemListViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  void onSortChanged({required ItemSortField field, required bool ascending}) {
    state = state.copyWith(
      query: state.query.copyWith(
        sortField: field,
        sortAscending: ascending,
        offset: 0,
      ),
    );
    unawaited(loadInitial());
  }

  void selectItem(String? itemId) {
    state = state.copyWith(selectedItemId: itemId);
  }

  Future<void> toggleDisabled(ItemEntity item, bool nextValue) async {
    final result = await _updateItemUseCase.execute(
      item.id,
      UpdateItemInput(
        itemName: item.itemName,
        itemGroup: item.itemGroup,
        stockUom: item.stockUom,
        description: item.description,
        disabled: nextValue,
        hasVariants: item.hasVariants,
        maintainStock: item.maintainStock,
        valuationRate: item.valuationRate,
        standardRate: item.standardRate,
      ),
    );

    state = result.fold(
      (Failure failure) => state.copyWith(
        status: ItemsStatus.error,
        errorMessage: failure.message,
      ),
      (updated) {
        final List<ItemEntity> mapped = state.items
            .map(
              (ItemEntity element) =>
                  element.id == updated.id ? updated : element,
            )
            .toList(growable: false);
        return state.copyWith(
          status: ItemsStatus.success,
          items: mapped,
          errorMessage: null,
        );
      },
    );
  }

  Future<Failure?> softDelete(String id) async {
    final result = await _softDeleteItemUseCase.execute(id);
    return result.fold((Failure failure) => failure, (_) {
      final List<ItemEntity> mapped = state.items
          .map(
            (ItemEntity item) =>
                item.id == id ? item.copyWith(disabled: true) : item,
          )
          .toList(growable: false);
      state = state.copyWith(
        items: mapped,
        status: ItemsStatus.success,
        errorMessage: null,
      );
      return null;
    });
  }

  Future<Failure?> hardDelete(String id) async {
    final result = await _hardDeleteItemUseCase.execute(id);
    return result.fold((Failure failure) => failure, (_) {
      final List<ItemEntity> mapped = state.items
          .where((ItemEntity item) => item.id != id)
          .toList(growable: false);
      state = state.copyWith(
        items: mapped,
        status: mapped.isEmpty ? ItemsStatus.empty : ItemsStatus.success,
        errorMessage: null,
      );
      return null;
    });
  }

  Future<void> _loadItemGroups() async {
    final result = await _getItemGroupsUseCase.execute();
    result.fold((_) {}, (List<String> groups) {
      state = state.copyWith(itemGroups: groups);
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
