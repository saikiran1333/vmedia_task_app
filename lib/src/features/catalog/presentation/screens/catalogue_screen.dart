import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common_widgets/shimmer.dart';
import '../../../../theme/catalogue_theme.dart';
import '../../domain/entities/product_entity.dart';
import '../ui/catalog_widgets.dart';
import '../viewmodels/catalog_viewmodels.dart';
import 'catalogue_shell.dart';

class CatalogueScreen extends ConsumerStatefulWidget {
  const CatalogueScreen({super.key});

  @override
  ConsumerState<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends ConsumerState<CatalogueScreen> {
  final _search = TextEditingController();
  String? _applied;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final params = GoRouterState.of(context).uri.queryParameters;
    final signature = '${params['q'] ?? ''}|${params['category'] ?? ''}';
    if (signature == _applied) return;
    _applied = signature;
    _search.text = params['q'] ?? '';
    Future.microtask(() {
      ref.read(catalogListViewModelProvider.notifier).applyRoute(q: params['q'] ?? '', category: params['category'] ?? '');
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(catalogListViewModelProvider);
    final occasions = ref.watch(occasionsProvider).value ?? const [];
    return CatalogueScaffold(
      title: 'Catalogue',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _search,
              onChanged: (value) => ref.read(catalogListViewModelProvider.notifier).search(value),
              decoration: const InputDecoration(hintText: 'Search by name', prefixIcon: Icon(Icons.search)),
            ),
          ),
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _FilterChip(label: list.query.category.isEmpty ? 'Category' : list.query.category, onTap: () => _pick(context, 'Category', ['', ...categoryArt.keys], list.query.category, (value) => ref.read(catalogListViewModelProvider.notifier).setFilters(category: value))),
                _FilterChip(label: list.query.occasion.isEmpty ? 'Occasion' : list.query.occasion, onTap: () => _pick(context, 'Occasion', ['', ...occasions.where((item) => item.catalogueFilter && item.name != null).map((item) => item.name!)], list.query.occasion, (value) => ref.read(catalogListViewModelProvider.notifier).setFilters(occasion: value))),
                _FilterChip(label: list.query.budget.isEmpty ? 'Budget' : list.query.budget, onTap: () => _pick(context, 'Budget', ['', ...catalogueBudgets], list.query.budget, (value) => ref.read(catalogListViewModelProvider.notifier).setFilters(budget: value))),
                _FilterChip(label: 'Sort', onTap: () => _pickSort(context, list.query)),
                TextButton(onPressed: () => ref.read(catalogListViewModelProvider.notifier).clearFilters(), child: const Text('Clear')),
              ],
            ),
          ),
          Expanded(child: _body(list)),
        ],
      ),
    );
  }

  Widget _body(CatalogListState list) {
    if (list.status == LoadStatus.loading || list.status == LoadStatus.idle) {
      return Shimmer(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            ShimmerBlock(height: 220),
            SizedBox(height: 12),
            ShimmerBlock(height: 220),
            SizedBox(height: 12),
            ShimmerBlock(height: 220),
          ],
        ),
      );
    }
    if (list.status == LoadStatus.error && list.items.isEmpty) {
      return StatusPanel(title: 'Catalogue unavailable', body: list.error ?? 'Try again.', actionLabel: 'Retry', onAction: () => ref.read(catalogListViewModelProvider.notifier).load());
    }
    if (list.items.isEmpty) {
      return const StatusPanel(title: 'No products match', body: 'Try another search or clear the filters.');
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = gridColumns(constraints.maxWidth);
        if (columns == 1) {
          return RefreshIndicator(
            onRefresh: () => ref.read(catalogListViewModelProvider.notifier).load(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final item in list.items) ...[
                  ProductCard(product: item, onTap: () => context.push('/products/${item.id}')),
                  const SizedBox(height: 12),
                ],
                if (list.hasMore)
                  OutlinedButton(
                    onPressed: list.loadingMore ? null : () => ref.read(catalogListViewModelProvider.notifier).loadMore(),
                    child: list.loadingMore ? const Shimmer(child: ShimmerBlock(height: 16, width: 96)) : const Text('Load more'),
                  ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.read(catalogListViewModelProvider.notifier).load(),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.68),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => ProductCard(product: list.items[index], onTap: () => context.push('/products/${list.items[index].id}')),
                    childCount: list.items.length,
                  ),
                ),
              ),
              if (list.hasMore)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: OutlinedButton(
                      onPressed: list.loadingMore ? null : () => ref.read(catalogListViewModelProvider.notifier).loadMore(),
                      child: list.loadingMore ? const Shimmer(child: ShimmerBlock(height: 16, width: 96)) : const Text('Load more'),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pick(BuildContext context, String title, List<String> values, String current, ValueChanged<String> onSelected) async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(padding: const EdgeInsets.all(16), child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18))),
            for (final value in values)
              ListTile(
                title: Text(value.isEmpty ? 'Any' : value),
                trailing: value == current ? const Icon(Icons.check, color: CatalogueTheme.green) : null,
                onTap: () => Navigator.pop(context, value),
              ),
          ],
        ),
      ),
    );
    if (chosen != null) onSelected(chosen);
  }

  Future<void> _pickSort(BuildContext context, CatalogQuery query) async {
    const options = [('name', 'asc', 'Name'), ('price', 'asc', 'Price, low to high'), ('price', 'desc', 'Price, high to low'), ('newest', 'desc', 'Newest')];
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in options)
              ListTile(
                title: Text(option.$3),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(catalogListViewModelProvider.notifier).setFilters(sort: option.$1, order: option.$2);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 160), child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
        onPressed: onTap,
      ),
    );
  }
}
