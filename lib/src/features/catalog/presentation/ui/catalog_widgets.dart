import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../theme/catalogue_theme.dart';
import '../../domain/entities/product_entity.dart';

class CatalogImage extends StatelessWidget {
  const CatalogImage({super.key, this.imageKey, this.assetPath, this.aspectRatio = 1});
  final String? imageKey;
  final String? assetPath;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final path = assetPath ?? assetFor(imageKey);
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: CatalogueTheme.softGreen),
        child: path == null
            ? const _ImageFallback()
            : Image.asset(path, fit: BoxFit.cover, errorBuilder: (context, error, stack) => const _ImageFallback()),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: CatalogueTheme.softGreen,
      child: Center(child: Icon(Icons.card_giftcard, color: CatalogueTheme.green, size: 36)),
    );
  }
}

class Entrance extends StatelessWidget {
  const Entrance({super.key, required this.child, this.delay = Duration.zero});
  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420) + delay,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(offset: Offset(0, (1 - value) * 12), child: child),
        );
      },
      child: child,
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap});
  final ProductEntity product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CatalogueTheme.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CatalogImage(imageKey: product.imageKey, aspectRatio: 1.15),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.category != null)
                    Text(product.category!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: CatalogueTheme.green, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, height: 1.3)),
                  const SizedBox(height: 8),
                  Text(product.priceLabel ?? 'Price on request', style: const TextStyle(color: CatalogueTheme.terracotta, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatusPanel extends StatelessWidget {
  const StatusPanel({super.key, required this.title, required this.body, this.actionLabel, this.onAction});
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center, style: const TextStyle(color: CatalogueTheme.muted, height: 1.4)),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

int gridColumns(double width) {
  if (width >= 1024) return 4;
  if (width >= 600) return 2;
  return 1;
}

Future<void> openWhatsApp({required String name, required String id, String? price}) async {
  final message = 'Hello TribeGreen, I would like a quote for $name ($id)${price == null ? '' : '. Guide price $price'}.';
  final uri = Uri.https('wa.me', '/919063099063', {'text': message});
  final opened = await canLaunchUrl(uri) && await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened) {
    throw const WhatsAppUnavailable();
  }
}

class WhatsAppUnavailable implements Exception {
  const WhatsAppUnavailable();
}
