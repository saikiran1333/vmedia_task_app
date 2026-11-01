import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common_widgets/shimmer.dart';
import '../../../../theme/catalogue_theme.dart';
import '../../../catalog/presentation/screens/catalogue_shell.dart';
import '../../../catalog/presentation/ui/catalog_widgets.dart';
import '../../domain/enquiry_rules.dart';
import '../viewmodels/enquiry_viewmodels.dart';

class MyEnquiriesScreen extends ConsumerStatefulWidget {
  const MyEnquiriesScreen({super.key});

  @override
  ConsumerState<MyEnquiriesScreen> createState() => _MyEnquiriesScreenState();
}

class _MyEnquiriesScreenState extends ConsumerState<MyEnquiriesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(historyViewModelProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyViewModelProvider);
    return CatalogueScaffold(
      title: 'My enquiries',
      body: switch (history.status) {
        LoadStatus.loading || LoadStatus.idle => Shimmer(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                ShimmerBlock(height: 120, radius: 16),
                SizedBox(height: 12),
                ShimmerBlock(height: 120, radius: 16),
                SizedBox(height: 12),
                ShimmerBlock(height: 120, radius: 16),
              ],
            ),
          ),
        LoadStatus.error => StatusPanel(
            title: 'History unavailable',
            body: history.error ?? 'Saved enquiries on this phone could not be read.',
            actionLabel: 'Clear unreadable history',
            onAction: () => ref.read(historyViewModelProvider.notifier).discardUnreadable(),
          ),
        LoadStatus.ready when history.items.isEmpty => const StatusPanel(
            title: 'No enquiries yet',
            body: 'Enquiries you send from this phone appear here. This list is stored on the device.',
          ),
        LoadStatus.ready => RefreshIndicator(
            onRefresh: () => ref.read(historyViewModelProvider.notifier).load(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: history.items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _EnquiryCard(enquiry: history.items[index]),
            ),
          ),
      },
    );
  }
}

class _EnquiryCard extends StatelessWidget {
  const _EnquiryCard({required this.enquiry});
  final StoredEnquiry enquiry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CatalogueTheme.white,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(enquiry.enquiryNumber, style: const TextStyle(fontWeight: FontWeight.w700, color: CatalogueTheme.terracotta)),
            const SizedBox(height: 4),
            Text(enquiry.createdAt, style: const TextStyle(color: CatalogueTheme.muted, fontSize: 13)),
            const SizedBox(height: 8),
            Text('${enquiry.occasion} · ${enquiry.budget}'),
            Text('${enquiry.units} units · ${enquiry.status}'),
            if (enquiry.products.isEmpty)
              const Padding(padding: EdgeInsets.only(top: 8), child: Text('No catalogue products were attached.'))
            else
              for (final product in enquiry.products)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('${product.name} × ${product.quantity}', maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(onPressed: () => context.go('/catalogue'), child: const Text('Browse catalogue')),
            ),
          ],
        ),
      ),
    );
  }
}
