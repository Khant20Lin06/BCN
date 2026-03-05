import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exception_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/frappe_file_upload_service.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/create_item_input.dart';
import '../../domain/entities/update_item_input.dart';
import '../../domain/usecases/create_item_usecase.dart';
import '../../domain/usecases/get_item_detail_usecase.dart';
import '../../domain/usecases/get_item_groups_usecase.dart';
import '../../domain/usecases/get_uoms_usecase.dart';
import '../../domain/usecases/update_item_usecase.dart';
import '../state/item_form_state.dart';
import 'items_controller.dart';

final createItemUseCaseProvider = Provider<CreateItemUseCase>((Ref ref) {
  return CreateItemUseCase(ref.watch(itemRepositoryProvider));
});

final itemFormControllerProvider =
    StateNotifierProvider.autoDispose<ItemFormController, ItemFormState>((
      Ref ref,
    ) {
      return ItemFormController(
        getItemGroupsUseCase: ref.watch(getItemGroupsUseCaseProvider),
        getUomsUseCase: ref.watch(getUomsUseCaseProvider),
        getItemDetailUseCase: ref.watch(getItemDetailUseCaseProvider),
        createItemUseCase: ref.watch(createItemUseCaseProvider),
        updateItemUseCase: ref.watch(updateItemUseCaseProvider),
        fileUploadService: FrappeFileUploadService(
          ref.watch(frappeApiClientProvider),
        ),
      );
    });

class ItemFormController extends StateNotifier<ItemFormState> {
  ItemFormController({
    required GetItemGroupsUseCase getItemGroupsUseCase,
    required GetUomsUseCase getUomsUseCase,
    required GetItemDetailUseCase getItemDetailUseCase,
    required CreateItemUseCase createItemUseCase,
    required UpdateItemUseCase updateItemUseCase,
    required FrappeFileUploadService fileUploadService,
  }) : _getItemGroupsUseCase = getItemGroupsUseCase,
       _getUomsUseCase = getUomsUseCase,
       _getItemDetailUseCase = getItemDetailUseCase,
       _createItemUseCase = createItemUseCase,
       _updateItemUseCase = updateItemUseCase,
       _fileUploadService = fileUploadService,
       super(const ItemFormState.initial());

  final GetItemGroupsUseCase _getItemGroupsUseCase;
  final GetUomsUseCase _getUomsUseCase;
  final GetItemDetailUseCase _getItemDetailUseCase;
  final CreateItemUseCase _createItemUseCase;
  final UpdateItemUseCase _updateItemUseCase;
  final FrappeFileUploadService _fileUploadService;

  Future<Either<Failure, String>> uploadItemImage({
    required String filePath,
    String? itemId,
  }) async {
    try {
      final bool canAttachToExistingDoc =
          itemId != null && itemId.trim().isNotEmpty;
      final String fileUrl = await _fileUploadService.uploadImage(
        filePath: filePath,
        doctype: canAttachToExistingDoc ? 'Item' : null,
        docname: canAttachToExistingDoc ? itemId : null,
        fieldname: canAttachToExistingDoc ? 'image' : null,
      );
      return Right<Failure, String>(fileUrl);
    } catch (error) {
      return Left<Failure, String>(mapExceptionToFailure(error));
    }
  }

  Future<void> initialize({String? itemId}) async {
    state = state.copyWith(status: ItemFormStatus.loading, errorMessage: null);

    final groupsResult = await _getItemGroupsUseCase.execute();
    final uomsResult = await _getUomsUseCase.execute();

    List<String> groups = const <String>[];
    List<String> uoms = const <String>[];
    String? error;

    groupsResult.fold(
      (Failure failure) => error = failure.message,
      (value) => groups = value,
    );
    uomsResult.fold(
      (Failure failure) => error = failure.message,
      (value) => uoms = value,
    );

    if (itemId != null) {
      final detailResult = await _getItemDetailUseCase.execute(itemId);
      state = detailResult.fold(
        (Failure failure) => state.copyWith(
          status: ItemFormStatus.error,
          errorMessage: failure.message,
        ),
        (item) => state.copyWith(
          status: error == null ? ItemFormStatus.ready : ItemFormStatus.error,
          item: item,
          itemGroups: groups,
          uoms: uoms,
          errorMessage: error,
        ),
      );
      return;
    }

    state = state.copyWith(
      status: error == null ? ItemFormStatus.ready : ItemFormStatus.error,
      itemGroups: groups,
      uoms: uoms,
      errorMessage: error,
    );
  }

  Future<Failure?> submitCreate({
    required String? itemCode,
    required String itemName,
    required String itemGroup,
    required String stockUom,
    required String? image,
    required String? description,
    required bool disabled,
    required bool hasVariants,
    required bool maintainStock,
    required double? openingStock,
    required double? valuationRate,
    required double? standardRate,
    required bool isFixedAsset,
  }) async {
    state = state.copyWith(
      status: ItemFormStatus.submitting,
      errorMessage: null,
    );

    final result = await _createItemUseCase.execute(
      CreateItemInput(
        itemCode: itemCode,
        itemName: itemName,
        itemGroup: itemGroup,
        stockUom: stockUom,
        image: image,
        description: description,
        disabled: disabled,
        hasVariants: hasVariants,
        maintainStock: maintainStock,
        openingStock: openingStock,
        valuationRate: valuationRate,
        standardRate: standardRate,
        isFixedAsset: isFixedAsset,
      ),
    );

    return result.fold(
      (Failure failure) {
        state = state.copyWith(
          status: ItemFormStatus.error,
          errorMessage: failure.message,
        );
        return failure;
      },
      (_) {
        state = state.copyWith(
          status: ItemFormStatus.success,
          errorMessage: null,
        );
        return null;
      },
    );
  }

  Future<Failure?> submitUpdate({
    required String id,
    required String itemName,
    required String itemGroup,
    required String stockUom,
    required String? image,
    required String? description,
    required bool disabled,
    required bool hasVariants,
    required bool maintainStock,
    required double? openingStock,
    required double? valuationRate,
    required double? standardRate,
    required bool isFixedAsset,
  }) async {
    state = state.copyWith(
      status: ItemFormStatus.submitting,
      errorMessage: null,
    );

    final result = await _updateItemUseCase.execute(
      id,
      UpdateItemInput(
        itemName: itemName,
        itemGroup: itemGroup,
        stockUom: stockUom,
        image: image,
        description: description,
        disabled: disabled,
        hasVariants: hasVariants,
        maintainStock: maintainStock,
        openingStock: openingStock,
        valuationRate: valuationRate,
        standardRate: standardRate,
        isFixedAsset: isFixedAsset,
      ),
    );

    return result.fold(
      (Failure failure) {
        state = state.copyWith(
          status: ItemFormStatus.error,
          errorMessage: failure.message,
        );
        return failure;
      },
      (_) {
        state = state.copyWith(
          status: ItemFormStatus.success,
          errorMessage: null,
        );
        return null;
      },
    );
  }
}
