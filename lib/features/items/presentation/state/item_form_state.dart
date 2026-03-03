import '../../domain/entities/item_entity.dart';

enum ItemFormStatus { idle, loading, ready, submitting, success, error }

class ItemFormState {
  const ItemFormState({
    required this.status,
    this.item,
    this.itemGroups = const <String>[],
    this.uoms = const <String>[],
    this.errorMessage,
  });

  const ItemFormState.initial() : this(status: ItemFormStatus.idle);

  final ItemFormStatus status;
  final ItemEntity? item;
  final List<String> itemGroups;
  final List<String> uoms;
  final String? errorMessage;

  ItemFormState copyWith({
    ItemFormStatus? status,
    ItemEntity? item,
    bool clearItem = false,
    List<String>? itemGroups,
    List<String>? uoms,
    String? errorMessage,
  }) {
    return ItemFormState(
      status: status ?? this.status,
      item: clearItem ? null : (item ?? this.item),
      itemGroups: itemGroups ?? this.itemGroups,
      uoms: uoms ?? this.uoms,
      errorMessage: errorMessage,
    );
  }
}
