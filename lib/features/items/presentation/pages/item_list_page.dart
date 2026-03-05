import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/permissions/app_permission_resolver.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/item_entity.dart';
import '../../domain/value_objects/item_query.dart';
import '../controllers/items_controller.dart';
import '../state/items_state.dart';
import '../widgets/filter_chip_bar.dart';
import '../widgets/item_cart_card.dart';
import '../widgets/item_list_tile.dart';
import '../widgets/search_field.dart';
import 'item_detail_page.dart';
import 'item_scan_page.dart';

class ItemListPage extends ConsumerStatefulWidget {
  const ItemListPage({super.key});

  @override
  ConsumerState<ItemListPage> createState() => _ItemListPageState();
}

class _ItemListPageState extends ConsumerState<ItemListPage> {
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController = ScrollController()..addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(itemsControllerProvider.notifier).loadInitial();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final double max = _scrollController.position.maxScrollExtent;
    final double current = _scrollController.position.pixels;
    if (current >= max - 280) {
      ref.read(itemsControllerProvider.notifier).loadNextPage();
    }
  }

  Future<void> _scanBarcodeOrQr() async {
    final String? code = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const ItemScanPage()),
    );
    if (!mounted || code == null || code.trim().isEmpty) {
      return;
    }

    final String normalized = code.trim();
    _searchController.text = normalized;
    ref.read(itemsControllerProvider.notifier).onSearchChanged(normalized);
  }

  @override
  Widget build(BuildContext context) {
    final ItemsState state = ref.watch(itemsControllerProvider);
    final session = ref.watch(authControllerProvider).session;
    final bool canRead = AppPermissionResolver.can(
      session,
      AppModule.items,
      PermissionAction.read,
    );
    final bool canCreate = AppPermissionResolver.can(
      session,
      AppModule.items,
      PermissionAction.create,
    );
    final bool canWrite = AppPermissionResolver.can(
      session,
      AppModule.items,
      PermissionAction.write,
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isTablet = constraints.maxWidth >= 600;

        final Widget listPane = _ListPane(
          state: state,
          searchController: _searchController,
          scrollController: _scrollController,
          onMenuTap: () => Scaffold.of(context).openDrawer(),
          onScanTap: _scanBarcodeOrQr,
          onAddTap: () => context.push('/items/new'),
          canRead: canRead,
          canCreate: canCreate,
          canWrite: canWrite,
          onRetry: () =>
              ref.read(itemsControllerProvider.notifier).loadInitial(),
          onRefresh: () => ref.read(itemsControllerProvider.notifier).refresh(),
          onSearch: (String value) =>
              ref.read(itemsControllerProvider.notifier).onSearchChanged(value),
          onItemGroupChanged: (String? group) => ref
              .read(itemsControllerProvider.notifier)
              .onItemGroupChanged(group),
          onDisabledChanged: (bool? disabled) => ref
              .read(itemsControllerProvider.notifier)
              .onDisabledFilterChanged(disabled),
          onViewModeChanged: (ItemListViewMode mode) => ref
              .read(itemsControllerProvider.notifier)
              .onViewModeChanged(mode),
          onSortChanged:
              ({required ItemSortField field, required bool ascending}) => ref
                  .read(itemsControllerProvider.notifier)
                  .onSortChanged(field: field, ascending: ascending),
          onSelect: (String id) {
            if (isTablet) {
              ref.read(itemsControllerProvider.notifier).selectItem(id);
            } else {
              context.push('/items/$id');
            }
          },
          onStatusChanged: (ItemEntity item, bool disabled) => ref
              .read(itemsControllerProvider.notifier)
              .toggleDisabled(item, disabled),
        );

        if (!isTablet) {
          return listPane;
        }

        return Row(
          children: <Widget>[
            SizedBox(width: 420, child: listPane),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            Expanded(
              child: state.selectedItemId == null
                  ? const _PlaceholderDetail()
                  : ItemDetailPage(
                      itemId: state.selectedItemId!,
                      embedded: true,
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _ListPane extends StatelessWidget {
  const _ListPane({
    required this.state,
    required this.searchController,
    required this.scrollController,
    required this.onMenuTap,
    required this.onScanTap,
    required this.onAddTap,
    required this.canRead,
    required this.canCreate,
    required this.canWrite,
    required this.onRetry,
    required this.onRefresh,
    required this.onSearch,
    required this.onItemGroupChanged,
    required this.onDisabledChanged,
    required this.onViewModeChanged,
    required this.onSortChanged,
    required this.onSelect,
    required this.onStatusChanged,
  });

  final ItemsState state;
  final TextEditingController searchController;
  final ScrollController scrollController;
  final VoidCallback onMenuTap;
  final Future<void> Function() onScanTap;
  final VoidCallback onAddTap;
  final bool canRead;
  final bool canCreate;
  final bool canWrite;
  final VoidCallback onRetry;
  final Future<void> Function() onRefresh;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onItemGroupChanged;
  final ValueChanged<bool?> onDisabledChanged;
  final ValueChanged<ItemListViewMode> onViewModeChanged;
  final void Function({required ItemSortField field, required bool ascending})
  onSortChanged;
  final ValueChanged<String> onSelect;
  final void Function(ItemEntity item, bool disabled) onStatusChanged;

  static const List<_SortChoice> _sortChoices = <_SortChoice>[
    _SortChoice(
      label: 'Item Name A-Z',
      field: ItemSortField.itemName,
      ascending: true,
    ),
    _SortChoice(
      label: 'Item Name Z-A',
      field: ItemSortField.itemName,
      ascending: false,
    ),
    _SortChoice(
      label: 'Item Code A-Z',
      field: ItemSortField.itemCode,
      ascending: true,
    ),
    _SortChoice(
      label: 'Item Code Z-A',
      field: ItemSortField.itemCode,
      ascending: false,
    ),
    _SortChoice(
      label: 'Price Low-High',
      field: ItemSortField.price,
      ascending: true,
    ),
    _SortChoice(
      label: 'Price High-Low',
      field: ItemSortField.price,
      ascending: false,
    ),
    _SortChoice(
      label: 'Qty Low-High',
      field: ItemSortField.qty,
      ascending: true,
    ),
    _SortChoice(
      label: 'Qty High-Low',
      field: ItemSortField.qty,
      ascending: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Row(
            children: <Widget>[
              IconButton(
                onPressed: onMenuTap,
                icon: const Icon(Icons.menu_rounded),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Items',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                onPressed: onScanTap,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                tooltip: 'Scan Barcode / QR',
              ),
              const SizedBox(width: 2),
              if (canCreate)
                FilledButton.icon(
                  onPressed: onAddTap,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add'),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: SearchField(controller: searchController, onChanged: onSearch),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: <Widget>[
              Expanded(
                child: SegmentedButton<ItemListViewMode>(
                  showSelectedIcon: false,
                  segments: const <ButtonSegment<ItemListViewMode>>[
                    ButtonSegment<ItemListViewMode>(
                      value: ItemListViewMode.list,
                      icon: Icon(Icons.list_rounded),
                      label: Text('List View'),
                    ),
                    ButtonSegment<ItemListViewMode>(
                      value: ItemListViewMode.cart,
                      icon: Icon(Icons.grid_view_rounded),
                      label: Text('Cart View'),
                    ),
                  ],
                  selected: <ItemListViewMode>{state.viewMode},
                  onSelectionChanged: (Set<ItemListViewMode> values) {
                    final ItemListViewMode mode = values.first;
                    onViewModeChanged(mode);
                  },
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<_SortChoice>(
                onSelected: (_SortChoice value) {
                  onSortChanged(field: value.field, ascending: value.ascending);
                },
                itemBuilder: (BuildContext context) => _sortChoices
                    .map(
                      (_SortChoice choice) => PopupMenuItem<_SortChoice>(
                        value: choice,
                        child: Text(choice.label),
                      ),
                    )
                    .toList(growable: false),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(Icons.swap_vert_rounded),
                      const SizedBox(width: 6),
                      Text(_sortLabel(state.query)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: FilterChipBar(
            itemGroups: state.itemGroups,
            selectedItemGroup: state.query.itemGroup,
            selectedDisabled: state.query.disabled,
            onItemGroupChanged: onItemGroupChanged,
            onDisabledChanged: onDisabledChanged,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(child: _buildBody(context)),
      ],
    );
  }

  String _sortLabel(ItemQuery query) {
    for (final _SortChoice choice in _sortChoices) {
      if (choice.field == query.sortField &&
          choice.ascending == query.sortAscending) {
        return choice.label;
      }
    }
    return 'Sort';
  }

  Widget _buildBody(BuildContext context) {
    if (state.status == ItemsStatus.loading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == ItemsStatus.error && state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(state.errorMessage ?? 'Failed to load items'),
              const SizedBox(height: 10),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (state.items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No items found. Tap Add to create your first item.'),
        ),
      );
    }

    if (state.viewMode == ItemListViewMode.cart) {
      return _buildCartView();
    }

    return _buildListView(context);
  }

  Widget _buildListView(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
        itemCount:
            state.items.length +
            (state.status == ItemsStatus.paginating ? 1 : 0),
        separatorBuilder: (BuildContext context, int index) => Divider(
          height: 1,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        itemBuilder: (BuildContext context, int index) {
          if (index >= state.items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }

          final ItemEntity item = state.items[index];
          return ItemListTile(
            item: item,
            onTap: canRead ? () => onSelect(item.id) : null,
            onStatusChanged: canWrite
                ? (bool disabled) => onStatusChanged(item, disabled)
                : null,
          );
        },
      ),
    );
  }

  Widget _buildCartView() {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        controller: scrollController,
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.72,
              ),
              delegate: SliverChildBuilderDelegate((
                BuildContext context,
                int index,
              ) {
                final ItemEntity item = state.items[index];
                return ItemCartCard(
                  item: item,
                  onTap: canRead ? () => onSelect(item.id) : null,
                );
              }, childCount: state.items.length),
            ),
          ),
          if (state.status == ItemsStatus.paginating)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(12, 0, 12, 20),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
        ],
      ),
    );
  }
}

class _SortChoice {
  const _SortChoice({
    required this.label,
    required this.field,
    required this.ascending,
  });

  final String label;
  final ItemSortField field;
  final bool ascending;
}

class _PlaceholderDetail extends StatelessWidget {
  const _PlaceholderDetail();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Select an item to see details',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
