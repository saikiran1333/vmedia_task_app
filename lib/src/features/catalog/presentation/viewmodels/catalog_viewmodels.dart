import 'dart:async';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/network_providers.dart';
import '../../data/datasources/catalog_remote_datasource.dart';
import '../../data/repository_impl/catalog_repository_impl.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/catalog_repository.dart';

final catalogRemoteDatasourceProvider = Provider<CatalogRemoteDatasource>((ref) {
  return CatalogRemoteDatasourceImpl(ref.watch(catalogDioProvider));
});

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepositoryImpl(ref.watch(catalogRemoteDatasourceProvider));
});

enum LoadStatus { idle, loading, ready, error }

class HomeState extends Equatable {
  final LoadStatus status;
  final List<CategoryEntity> categories;
  final List<ProductEntity> justIn;
  final List<ProductEntity> fastSelling;
  final String? error;

  const HomeState({
    this.status = LoadStatus.idle,
    this.categories = const [],
    this.justIn = const [],
    this.fastSelling = const [],
    this.error,
  });

  HomeState copyWith({
    LoadStatus? status,
    List<CategoryEntity>? categories,
    List<ProductEntity>? justIn,
    List<ProductEntity>? fastSelling,
    String? error,
    bool clearError = false,
  }) {
    return HomeState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      justIn: justIn ?? this.justIn,
      fastSelling: fastSelling ?? this.fastSelling,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, categories, justIn, fastSelling, error];
}

class HomeViewModel extends StateNotifier<HomeState> {
  HomeViewModel(this._repository) : super(const HomeState());
  final CatalogRepository _repository;
  int _ticket = 0;

  Future<void> load() async {
    final ticket = ++_ticket;
    state = state.copyWith(status: LoadStatus.loading, clearError: true);
    try {
      final results = await Future.wait([
        _repository.categories(),
        _repository.list(const CatalogQuery(justIn: true, pageSize: 12, sort: 'updated', order: 'desc')),
        _repository.list(const CatalogQuery(fastSelling: true, pageSize: 12, sort: 'updated', order: 'desc')),
      ]);
      if (ticket != _ticket) return;
      state = HomeState(
        status: LoadStatus.ready,
        categories: results[0] as List<CategoryEntity>,
        justIn: (results[1] as ProductPageEntity).items,
        fastSelling: (results[2] as ProductPageEntity).items,
      );
      debugPrint('[Vmedia][catalog] home ready');
    } catch (error) {
      if (ticket != _ticket) return;
      state = state.copyWith(status: LoadStatus.error, error: _message(error));
    }
  }

  @override
  void dispose() {
    _ticket++;
    super.dispose();
  }
}

class CatalogListState extends Equatable {
  final LoadStatus status;
  final List<ProductEntity> items;
  final CatalogQuery query;
  final bool hasMore;
  final bool loadingMore;
  final String? error;
  final int total;

  const CatalogListState({
    this.status = LoadStatus.idle,
    this.items = const [],
    this.query = const CatalogQuery(),
    this.hasMore = false,
    this.loadingMore = false,
    this.error,
    this.total = 0,
  });

  CatalogListState copyWith({
    LoadStatus? status,
    List<ProductEntity>? items,
    CatalogQuery? query,
    bool? hasMore,
    bool? loadingMore,
    String? error,
    bool clearError = false,
    int? total,
  }) {
    return CatalogListState(
      status: status ?? this.status,
      items: items ?? this.items,
      query: query ?? this.query,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      error: clearError ? null : error ?? this.error,
      total: total ?? this.total,
    );
  }

  @override
  List<Object?> get props => [status, items, query, hasMore, loadingMore, error, total];
}

class CatalogListViewModel extends StateNotifier<CatalogListState> {
  CatalogListViewModel(this._repository) : super(const CatalogListState());
  final CatalogRepository _repository;
  Timer? _debounce;
  CancelToken? _token;
  int _ticket = 0;

  void applyRoute({required String q, required String category}) {
    final next = state.query.copyWith(q: q, category: category, occasion: '', budget: '', page: 1);
    if (next == state.query && state.status != LoadStatus.idle) return;
    state = state.copyWith(query: next);
    load(reset: true);
  }

  void search(String value) {
    state = state.copyWith(query: state.query.copyWith(q: value, page: 1));
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 320), () => load(reset: true));
  }

  void setFilters({String? category, String? occasion, String? budget, String? sort, String? order}) {
    state = state.copyWith(
      query: state.query.copyWith(
        category: category,
        occasion: occasion,
        budget: budget,
        sort: sort,
        order: order,
        page: 1,
      ),
    );
    load(reset: true);
  }

  void clearFilters() {
    final q = state.query.q;
    state = state.copyWith(query: CatalogQuery(q: q));
    load(reset: true);
  }

  Future<void> load({bool reset = true}) async {
    _token?.cancel();
    final token = CancelToken();
    _token = token;
    final ticket = ++_ticket;
    final query = state.query.copyWith(page: reset ? 1 : state.query.page);
    state = state.copyWith(
      status: reset ? LoadStatus.loading : state.status,
      loadingMore: !reset,
      query: query,
      clearError: true,
    );
    try {
      final page = await _repository.list(query, cancelToken: token);
      if (ticket != _ticket) return;
      state = state.copyWith(
        status: LoadStatus.ready,
        items: reset ? page.items : [...state.items, ...page.items],
        hasMore: page.hasMore,
        loadingMore: false,
        total: page.total,
        query: query,
      );
    } catch (error) {
      if (ticket != _ticket || _cancelled(error)) return;
      state = state.copyWith(status: LoadStatus.error, loadingMore: false, error: _message(error));
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.loadingMore || state.status == LoadStatus.loading) return;
    state = state.copyWith(query: state.query.copyWith(page: state.query.page + 1));
    await load(reset: false);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _token?.cancel();
    _ticket++;
    super.dispose();
  }
}

class ProductDetailState extends Equatable {
  final LoadStatus status;
  final ProductEntity? product;
  final List<ProductEntity> related;
  final String? error;

  const ProductDetailState({this.status = LoadStatus.idle, this.product, this.related = const [], this.error});

  @override
  List<Object?> get props => [status, product, related, error];
}

class ProductDetailViewModel extends StateNotifier<ProductDetailState> {
  ProductDetailViewModel(this._repository, this.id) : super(const ProductDetailState());
  final CatalogRepository _repository;
  final String id;

  Future<void> load() async {
    state = const ProductDetailState(status: LoadStatus.loading);
    try {
      final product = await _repository.getById(id);
      var related = <ProductEntity>[];
      if (product.category != null && product.category!.isNotEmpty) {
        final page = await _repository.list(CatalogQuery(category: product.category!, pageSize: 8));
        related = page.items.where((item) => item.id != product.id).take(6).toList();
      }
      state = ProductDetailState(status: LoadStatus.ready, product: product, related: related);
    } catch (error) {
      state = ProductDetailState(status: LoadStatus.error, error: _message(error));
    }
  }
}

final homeViewModelProvider = StateNotifierProvider<HomeViewModel, HomeState>((ref) {
  return HomeViewModel(ref.watch(catalogRepositoryProvider));
});

final catalogListViewModelProvider = StateNotifierProvider<CatalogListViewModel, CatalogListState>((ref) {
  return CatalogListViewModel(ref.watch(catalogRepositoryProvider));
});

final productDetailViewModelProvider = StateNotifierProvider.autoDispose.family<ProductDetailViewModel, ProductDetailState, String>((ref, id) {
  return ProductDetailViewModel(ref.watch(catalogRepositoryProvider), id);
});

final occasionsProvider = FutureProvider<List<OccasionEntity>>((ref) {
  return ref.watch(catalogRepositoryProvider).occasions();
});

final customisationsProvider = FutureProvider<List<String>>((ref) {
  return ref.watch(catalogRepositoryProvider).customisations();
});

bool _cancelled(Object error) => error is ApiFailure && error.cancelled;

String _message(Object error) {
  if (error is ApiFailure) return error.message;
  return 'The catalogue could not be loaded. Try again.';
}
