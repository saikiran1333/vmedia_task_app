import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common_widgets/shimmer.dart';
import '../../../enquiry/domain/enquiry_rules.dart';
import '../../../enquiry/presentation/viewmodels/enquiry_viewmodels.dart' hide LoadStatus;
import '../../../../theme/catalogue_theme.dart';
import '../../domain/entities/product_entity.dart';
import '../ui/catalog_widgets.dart';
import '../viewmodels/catalog_viewmodels.dart';
import 'catalogue_shell.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(productDetailViewModelProvider(widget.id).notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(productDetailViewModelProvider(widget.id));
    return Theme(
      data: CatalogueTheme.light(),
      child: CatalogueScaffold(
        title: 'Product',
        body: switch (detail.status) {
          LoadStatus.loading || LoadStatus.idle => Shimmer(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: const [
                  ShimmerBlock(height: 280, radius: 16),
                  SizedBox(height: 16),
                  ShimmerBlock(height: 28, width: 220),
                  SizedBox(height: 8),
                  ShimmerBlock(height: 20, width: 140),
                  SizedBox(height: 16),
                  ShimmerBlock(height: 14),
                  SizedBox(height: 8),
                  ShimmerBlock(height: 14, width: 260),
                  SizedBox(height: 8),
                  ShimmerBlock(height: 14, width: 180),
                ],
              ),
            ),
          LoadStatus.error => StatusPanel(
              title: 'Product unavailable',
              body: detail.error ?? 'This product is not available.',
              actionLabel: 'Back to catalogue',
              onAction: () => context.go('/catalogue'),
            ),
          LoadStatus.ready => detail.product == null
              ? const StatusPanel(title: 'Product unavailable', body: 'This product is not available.')
              : _Detail(product: detail.product!, related: detail.related),
        },
      ),
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.product, required this.related});
  final ProductEntity product;
  final List<ProductEntity> related;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final images = [if (product.imageKey != null) product.imageKey!, ...product.galleryKeys.where((key) => key != product.imageKey)];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 280,
            child: images.isEmpty
                ? const CatalogImage(aspectRatio: 1.2)
                : PageView(children: [for (final key in images) CatalogImage(imageKey: key, aspectRatio: 1.2)]),
          ),
        ),
        const SizedBox(height: 16),
        Text(product.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600, height: 1.2)),
        const SizedBox(height: 8),
        Text(product.priceLabel ?? 'Price on request', style: const TextStyle(color: CatalogueTheme.terracotta, fontSize: 18, fontWeight: FontWeight.w600)),
        if (product.category != null) ...[const SizedBox(height: 8), Text(product.category!, style: const TextStyle(color: CatalogueTheme.green, fontWeight: FontWeight.w600))],
        if (product.siteCategories.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('Also listed under ${product.siteCategories.join(', ')}', style: const TextStyle(color: CatalogueTheme.muted)),
        ],
        const SizedBox(height: 16),
        Text(product.description?.trim().isNotEmpty == true ? product.description! : 'Details for this gift are confirmed in the quote.', style: const TextStyle(height: 1.45)),
        if (product.occasions.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('Occasions', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final occasion in product.occasions) Chip(label: Text(occasion))]),
        ],
        if (product.customisationOptions.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Customisation', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final option in product.customisationOptions) Chip(label: Text(option))]),
        ],
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            ref.read(selectionProvider.notifier).add(SelectedGift(
                  id: product.id,
                  name: product.name,
                  imageKey: product.imageKey,
                  customisationOptions: product.customisationOptions,
                ));
            context.go('/enquire');
          },
          child: const Text('Enquire now'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () async {
            try {
              await openWhatsApp(name: product.name, id: product.id, price: product.priceLabel);
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WhatsApp is not available on this phone.')));
              }
            }
          },
          child: const Text('WhatsApp enquiry'),
        ),
        if (related.isNotEmpty) ...[
          const SizedBox(height: 28),
          const Text('More in this category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          for (final item in related) ...[
            ProductCard(product: item, onTap: () => context.push('/products/${item.id}')),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }
}
