import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common_widgets/shimmer.dart';
import '../../../../theme/catalogue_theme.dart';
import '../../domain/entities/product_entity.dart';
import '../ui/catalog_widgets.dart';
import '../viewmodels/catalog_viewmodels.dart';
import 'catalogue_shell.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(homeViewModelProvider.notifier).load());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openSearch() {
    final q = _search.text.trim();
    context.go(q.isEmpty ? '/catalogue' : '/catalogue?q=${Uri.encodeQueryComponent(q)}');
  }

  @override
  Widget build(BuildContext context) {
    final home = ref.watch(homeViewModelProvider);
    return CatalogueScaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(homeViewModelProvider.notifier).load(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const Entrance(child: Text('Corporate gifts, considered.', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, height: 1.2))),
            const SizedBox(height: 8),
            const Text('Browse the TribeGreen catalogue and send a quote request. No account and no checkout.', style: TextStyle(color: CatalogueTheme.muted, height: 1.4)),
            const SizedBox(height: 16),
            TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _openSearch(),
              decoration: InputDecoration(
                hintText: 'Search gifts',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(onPressed: _openSearch, icon: const Icon(Icons.arrow_forward)),
              ),
            ),
            const SizedBox(height: 20),
            const _Hero(),
            const SizedBox(height: 28),
            if (home.status == LoadStatus.loading) const _HomeShimmer(),
            if (home.status == LoadStatus.error)
              StatusPanel(title: 'Catalogue unavailable', body: home.error ?? 'Try again.', actionLabel: 'Retry', onAction: () => ref.read(homeViewModelProvider.notifier).load()),
            if (home.status == LoadStatus.ready) ...[
              _SectionTitle(title: 'Categories'),
              SizedBox(
                height: 116,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: home.categories.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final category = home.categories[index];
                    return _CategoryTile(
                      name: category.name,
                      onTap: () => context.go('/catalogue?category=${Uri.encodeQueryComponent(category.name)}'),
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),
              _Rail(title: 'Just in', products: home.justIn),
              const SizedBox(height: 28),
              _Rail(title: 'Fast selling', products: home.fastSelling),
            ],
            const SizedBox(height: 28),
            const _SectionTitle(title: 'How a gift enquiry works'),
            const _Step(index: '01', title: 'Tell us the occasion', body: 'Share who the gifts are for and when you need them.'),
            const _Step(index: '02', title: 'We shortlist', body: 'A specialist replies with options that fit the brief.'),
            const _Step(index: '03', title: 'Confirm branding', body: 'Logo, names, and packaging are agreed before production.'),
            const _Step(index: '04', title: 'We prepare delivery', body: 'Quantities and the city help us plan the shipment.'),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () => context.go('/enquire'), child: const Text('Start an enquiry')),
          ],
        ),
      ),
    );
  }
}

class _HomeShimmer extends StatelessWidget {
  const _HomeShimmer();

  @override
  Widget build(BuildContext context) {
    return const Shimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBlock(height: 18, width: 140),
          SizedBox(height: 12),
          SizedBox(height: 116, child: ShimmerBlock(height: 116)),
          SizedBox(height: 28),
          ShimmerBlock(height: 18, width: 120),
          SizedBox(height: 12),
          ShimmerBlock(height: 180),
          SizedBox(height: 28),
          ShimmerBlock(height: 18, width: 140),
          SizedBox(height: 12),
          ShimmerBlock(height: 180),
        ],
      ),
    );
  }
}

class _Hero extends StatefulWidget {
  const _Hero();

  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> {
  final _controller = PageController();
  int _index = 0;
  static const _slides = [
    'assets/images/banners/home-banner-tablet.webp',
    'assets/images/banners/sign-in-banner.jpg',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: PageView.builder(
              controller: _controller,
              itemCount: _slides.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (_, index) => CatalogImage(assetPath: _slides[index], aspectRatio: 16 / 9),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_slides.length, (index) {
            return Container(
              width: index == _index ? 18 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(color: index == _index ? CatalogueTheme.terracotta : CatalogueTheme.border, borderRadius: BorderRadius.circular(8)),
            );
          }),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)));
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.name, required this.onTap});
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      child: Material(
        color: CatalogueTheme.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CatalogImage(assetPath: categoryArt[name], aspectRatio: 2.1),
              Padding(padding: const EdgeInsets.all(8), child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
            ],
          ),
        ),
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.title, required this.products});
  final String title;
  final List<ProductEntity> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: title),
        SizedBox(
          height: 292,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final product = products[index];
              return SizedBox(width: 180, child: ProductCard(product: product, onTap: () => context.push('/products/${product.id}')));
            },
          ),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.index, required this.title, required this.body});
  final String index;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(index, style: const TextStyle(color: CatalogueTheme.terracotta, fontWeight: FontWeight.w700)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w600)), Text(body, style: const TextStyle(color: CatalogueTheme.muted, height: 1.35))])),
        ],
      ),
    );
  }
}
