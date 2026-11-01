import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vmedia/src/core/network/api_failure.dart';
import 'package:vmedia/src/features/catalog/domain/entities/product_entity.dart';
import 'package:vmedia/src/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:vmedia/src/features/catalog/presentation/viewmodels/catalog_viewmodels.dart';
import 'package:vmedia/src/features/enquiry/data/datasources/enquiry_local_datasource.dart';
import 'package:vmedia/src/features/enquiry/domain/enquiry_rules.dart';
import 'package:vmedia/src/features/enquiry/domain/repositories/enquiry_repository.dart';
import 'package:vmedia/src/features/enquiry/presentation/viewmodels/enquiry_viewmodels.dart';

void main() {
  test('history skips corrupt rows and rejects a corrupt file', () async {
    final store = MemoryStore();
    final history = EnquiryHistoryRepositoryImpl(store);
    await store.write(EnquiryHistoryRepositoryImpl.historyKey, jsonEncode([
      {'enquiryNumber': 'TG-1', 'createdAt': 'today', 'occasion': 'Diwali', 'budget': enquiryBudgets.first, 'units': 2, 'status': 'Submitted', 'products': []},
      {'enquiryNumber': ''},
      'broken',
    ]));
    final rows = await history.read();
    expect(rows.single.enquiryNumber, 'TG-1');

    await store.write(EnquiryHistoryRepositoryImpl.historyKey, '{');
    expect(history.read(), throwsA(isA<HistoryReadException>()));
    await history.clearHistory();
    expect(await history.read(), isEmpty);
  });

  test('catalogue load more appends and a stale call is ignored', () async {
    final repo = _CatalogFake();
    final model = CatalogListViewModel(repo);
    await model.load();
    expect(model.state.items, hasLength(1));
    await model.loadMore();
    expect(model.state.items, hasLength(2));
    expect(model.state.hasMore, isFalse);
  });

  test('selection totals and ignores a duplicate product', () {
    final selection = SelectionViewModel();
    selection.add(const SelectedGift(id: 'tg-1', name: 'Bottle', quantity: 2));
    selection.add(const SelectedGift(id: 'tg-1', name: 'Bottle', quantity: 9));
    selection.setQuantity('tg-1', 4);
    selection.setQuantity('tg-1', 0);
    expect(selection.units, 4);
    selection.remove('tg-1');
    expect(selection.state, isEmpty);
  });

  test('a failed submit is not stored and a second tap does not duplicate', () async {
    final remote = _EnquiryFake()..failure = const ApiFailure('No internet connection.', statusCode: null);
    final history = EnquiryHistoryRepositoryImpl(MemoryStore());
    final model = EnquiryFormViewModel(remote, history);
    final draft = _draft();
    final first = model.submit(draft, occasions: const ['Corporate Diwali Gifting'], customisations: const []);
    final second = model.submit(draft, occasions: const ['Corporate Diwali Gifting'], customisations: const []);
    expect(await first, isFalse);
    expect(await second, isFalse);
    expect(remote.calls, 1);
    expect(await history.read(), isEmpty);
    expect(model.state.status, EnquirySubmitStatus.editing);
  });

  test('local save failure keeps the enquiry number and does not resubmit', () async {
    final remote = _EnquiryFake();
    final history = _FailingHistory();
    final model = EnquiryFormViewModel(remote, history);
    final sent = await model.submit(_draft(), occasions: const ['Corporate Diwali Gifting'], customisations: const []);
    expect(sent, isTrue);
    expect(model.state.receipt?.enquiryNumber, 'TG-1001');
    expect(model.state.status, EnquirySubmitStatus.localSaveFailed);
    expect(remote.calls, 1);
    history.failWrite = false;
    expect(await model.retryLocalSave(), isTrue);
    expect(remote.calls, 1);
    expect(model.state.status, EnquirySubmitStatus.sent);
  });
}

EnquiryDraft _draft() {
  return EnquiryDraft(
    name: 'Asha Rao',
    email: 'asha@example.com',
    phone: '9876543210',
    city: 'Hyderabad',
    occasion: 'Corporate Diwali Gifting',
    budget: enquiryBudgets.first,
    message: 'Please share a branded quote.',
    units: '3',
  );
}

class _CatalogFake implements CatalogRepository {
  @override
  Future<List<CategoryEntity>> categories() async => const [];
  @override
  Future<List<String>> customisations() async => const [];
  @override
  Future<ProductEntity> getById(String id) async => ProductEntity(id: id, slug: id, name: id);
  @override
  Future<List<OccasionEntity>> occasions() async => const [];
  @override
  Future<ProductPageEntity> list(CatalogQuery query, {Object? cancelToken}) async {
    return ProductPageEntity(
      items: [ProductEntity(id: 'tg-${query.page}', slug: 'item', name: 'Gift ${query.page}')],
      page: query.page,
      pageSize: 1,
      total: 2,
    );
  }
}

class _EnquiryFake implements EnquiryRepository {
  int calls = 0;
  ApiFailure? failure;
  @override
  Future<EnquiryReceipt> submit(Map<String, dynamic> body, String idempotencyKey) async {
    calls += 1;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    if (failure != null) throw failure!;
    return const EnquiryReceipt(id: '1', enquiryNumber: 'TG-1001', createdAt: '2026-11-01', units: 3);
  }
}

class _FailingHistory implements EnquiryHistoryRepository {
  bool failWrite = true;
  StoredEnquiry? saved;
  @override
  Future<void> clearHistory() async {}
  @override
  Future<void> clearPending() async {}
  @override
  Future<List<StoredEnquiry>> read() async => saved == null ? [] : [saved!];
  @override
  Future<PendingSubmission?> readPending() async => null;
  @override
  Future<void> save(StoredEnquiry enquiry) async {
    if (failWrite) throw const HistoryWriteException('The enquiry was sent, but it could not be saved on this phone.');
    saved = enquiry;
  }
  @override
  Future<void> writePending(PendingSubmission pending) async {}
}
