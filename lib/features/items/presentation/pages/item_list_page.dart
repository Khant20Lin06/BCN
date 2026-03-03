import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/items_controller.dart';
import '../state/items_state.dart';
import '../widgets/filter_chip_bar.dart';
import '../widgets/item_list_tile.dart';
import '../widgets/search_field.dart';
import 'item_detail_page.dart';

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

    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    if (current >= max - 280) {
      ref.read(itemsControllerProvider.notifier).loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ItemsState state = ref.watch(itemsControllerProvider);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isTablet = constraints.maxWidth >= 600;

        final Widget listPane = _ListPane(
          state: state,
          isTablet: isTablet,
          searchController: _searchController,
          scrollController: _scrollController,
          onMenuTap: () => Scaffold.of(context).openDrawer(),
          onAddTap: () => context.push('/items/new'),
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
          onSelect: (String id) {
            if (isTablet) {
              ref.read(itemsControllerProvider.notifier).selectItem(id);
            } else {
              context.push('/items/$id');
            }
          },
          onStatusChanged: (item, disabled) => ref
              .read(itemsControllerProvider.notifier)
              .toggleDisabled(item, disabled),
        );

        if (!isTablet) {
          return listPane;
        }

        // Tablet gets a split-pane master/detail flow, while mobile keeps
        // navigation-based detail pages to preserve familiar UX patterns.
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
    required this.isTablet,
    required this.searchController,
    required this.scrollController,
    required this.onMenuTap,
    required this.onAddTap,
    required this.onRetry,
    required this.onRefresh,
    required this.onSearch,
    required this.onItemGroupChanged,
    required this.onDisabledChanged,
    required this.onSelect,
    required this.onStatusChanged,
  });

  final ItemsState state;
  final bool isTablet;
  final TextEditingController searchController;
  final ScrollController scrollController;
  final VoidCallback onMenuTap;
  final VoidCallback onAddTap;
  final VoidCallback onRetry;
  final Future<void> Function() onRefresh;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onItemGroupChanged;
  final ValueChanged<bool?> onDisabledChanged;
  final ValueChanged<String> onSelect;
  final void Function(dynamic item, bool disabled) onStatusChanged;

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

          final item = state.items[index];
          return ItemListTile(
            item: item,
            onTap: () => onSelect(item.id),
            onStatusChanged: (bool disabled) => onStatusChanged(item, disabled),
          );
        },
      ),
    );
  }
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
