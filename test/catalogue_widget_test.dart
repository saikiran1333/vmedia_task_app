import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vmedia/src/app/app.dart';
import 'package:vmedia/src/app/app_router.dart';
import 'package:vmedia/src/features/catalog/domain/entities/product_entity.dart';
import 'package:vmedia/src/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:vmedia/src/features/catalog/presentation/viewmodels/catalog_viewmodels.dart';
import 'package:vmedia/src/features/enquiry/domain/enquiry_rules.dart';
import 'package:vmedia/src/features/enquiry/domain/repositories/enquiry_repository.dart';
import 'package:vmedia/src/features/enquiry/presentation/viewmodels/enquiry_viewmodels.dart';

void main() {
  testWidgets('home shows branding, groups and the enquiry action', (tester) async {
    _tall(tester);
    await tester.pumpWidget(_app(_ReadyCatalog()));
    await tester.pumpAndSettle();
    expect(find.text('Corporate gifts, considered.'), findsOneWidget);
    expect(find.text('Just in'), findsOneWidget);
    expect(find.text('Fast selling'), findsOneWidget);
    expect(find.text('Smart Bottle'), findsWidgets);
    expect(find.text('Start an enquiry'), findsOneWidget);
  });

  testWidgets('catalogue shows an empty result', (tester) async {
    await tester.pumpWidget(_app(_EmptyCatalog(), location: '/catalogue'));
    await tester.pumpAndSettle();
    expect(find.text('No products match'), findsOneWidget);
  });

  testWidgets('catalogue can retry an error', (tester) async {
    await tester.pumpWidget(_app(_ErrorCatalog(), location: '/catalogue'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Catalogue unavailable'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('product details show the gift and enquiry actions', (tester) async {
    _tall(tester);
    await tester.pumpWidget(_app(_ReadyCatalog(), location: '/products/tg-1'));
    await tester.pumpAndSettle();
    expect(find.text('Smart Bottle'), findsOneWidget);
    expect(find.text('Enquire now'), findsOneWidget);
    expect(find.text('WhatsApp enquiry'), findsOneWidget);
    expect(find.text('Logo printing'), findsOneWidget);
  });

  testWidgets('a missing product explains that it is unavailable', (tester) async {
    await tester.pumpWidget(_app(_MissingProduct(), location: '/products/tg-missing'));
    await tester.pumpAndSettle();
    expect(find.text('Product unavailable'), findsOneWidget);
  });

  testWidgets('enquiry form validates before sending', (tester) async {
    _tall(tester);
    await tester.pumpWidget(_app(_ReadyCatalog(), location: '/enquire'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send enquiry'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a name between 2 and 80 characters.'), findsOneWidget);
  });

  testWidgets('success page shows the returned enquiry number', (tester) async {
    final history = _MemoryHistory();
    await tester.pumpWidget(_app(_ReadyCatalog(), location: '/enquiry-sent', history: history, form: _PresetForm(history)));
    await tester.pumpAndSettle();
    expect(find.text('Enquiry received'), findsOneWidget);
    expect(find.textContaining('TG-1001'), findsOneWidget);
  });

  testWidgets('my enquiries shows a saved record and an empty history', (tester) async {
    final history = _MemoryHistory()
      ..items = [
        const StoredEnquiry(enquiryNumber: 'TG-1001', createdAt: '2026-11-01', occasion: 'Corporate Diwali Gifting', budget: 'Flexible / Not sure', units: 3, status: 'Submitted', products: [SelectedGift(id: 'tg-1', name: 'Smart Bottle', quantity: 3)]),
      ];
    await tester.pumpWidget(_app(_ReadyCatalog(), location: '/enquiries', history: history));
    await tester.pumpAndSettle();
    expect(find.text('TG-1001'), findsOneWidget);
    expect(find.textContaining('Smart Bottle'), findsOneWidget);
  });

  testWidgets('my enquiries explains an empty history', (tester) async {
    await tester.pumpWidget(_app(_ReadyCatalog(), location: '/enquiries'));
    await tester.pumpAndSettle();
    expect(find.text('No enquiries yet'), findsOneWidget);
  });

  testWidgets('an unknown route is recoverable', (tester) async {
    await tester.pumpWidget(_app(_ReadyCatalog(), location: '/missing-page'));
    await tester.pumpAndSettle();
    expect(find.textContaining('not part of the catalogue'), findsOneWidget);
  });
}

void _tall(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _app(CatalogRepository catalog, {String location = '/', EnquiryHistoryRepository? history, EnquiryFormViewModel? form}) {
  return ProviderScope(
    overrides: [
      initialLocationProvider.overrideWithValue(location),
      catalogRepositoryProvider.overrideWithValue(catalog),
      if (history != null) enquiryHistoryRepositoryProvider.overrideWithValue(history),
      if (form != null) enquiryFormViewModelProvider.overrideWith((ref) => form),
    ],
    child: const VmediaApp(),
  );
}

class _ReadyCatalog implements CatalogRepository {
  @override
  Future<List<CategoryEntity>> categories() async => const [CategoryEntity(name: 'Drinkware', productCount: 1)];
  @override
  Future<List<String>> customisations() async => const ['Logo printing'];
  @override
  Future<ProductEntity> getById(String id) async => const ProductEntity(
        id: 'tg-1',
        slug: 'bottle',
        name: 'Smart Bottle',
        category: 'Drinkware',
        displayedPrice: 1499,
        description: 'A bottle for the desk.',
        imageKey: null,
        occasions: ['Employee Onboarding'],
        customisationOptions: ['Logo printing'],
      );
  @override
  Future<List<OccasionEntity>> occasions() async => const [
        OccasionEntity(name: 'Corporate Diwali Gifting', enquiryLabel: 'Corporate Diwali Gifting', catalogueFilter: true),
      ];
  @override
  Future<ProductPageEntity> list(CatalogQuery query, {Object? cancelToken}) async {
    return const ProductPageEntity(items: [ProductEntity(id: 'tg-1', slug: 'bottle', name: 'Smart Bottle', displayedPrice: 1499, justIn: true, fastSelling: true)], page: 1, pageSize: 12, total: 1);
  }
}

class _EmptyCatalog extends _ReadyCatalog {
  @override
  Future<ProductPageEntity> list(CatalogQuery query, {Object? cancelToken}) async {
    return const ProductPageEntity(items: [], page: 1, pageSize: 12, total: 0);
  }
}

class _ErrorCatalog extends _ReadyCatalog {
  @override
  Future<ProductPageEntity> list(CatalogQuery query, {Object? cancelToken}) async {
    throw Exception('offline');
  }
}

class _MissingProduct extends _ReadyCatalog {
  @override
  Future<ProductEntity> getById(String id) async => throw Exception('This product is not available.');
}

class _PresetForm extends EnquiryFormViewModel {
  _PresetForm(EnquiryHistoryRepository history) : super(_EnquiryOk(), history) {
    state = const EnquiryFormState(
      status: EnquirySubmitStatus.sent,
      receipt: EnquiryReceipt(id: '1', enquiryNumber: 'TG-1001', createdAt: '2026-11-01', units: 3),
    );
  }
}

class _EnquiryOk implements EnquiryRepository {
  @override
  Future<EnquiryReceipt> submit(Map<String, dynamic> body, String idempotencyKey) async {
    return const EnquiryReceipt(id: '1', enquiryNumber: 'TG-1001', createdAt: '2026-11-01', units: 3);
  }
}

class _MemoryHistory implements EnquiryHistoryRepository {
  List<StoredEnquiry> items = const [];
  @override
  Future<void> clearHistory() async => items = const [];
  @override
  Future<void> clearPending() async {}
  @override
  Future<List<StoredEnquiry>> read() async => items;
  @override
  Future<PendingSubmission?> readPending() async => null;
  @override
  Future<void> save(StoredEnquiry enquiry) async => items = [enquiry];
  @override
  Future<void> writePending(PendingSubmission pending) async {}
}
