import 'package:dio/dio.dart';

import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../datasources/catalog_remote_datasource.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  CatalogRepositoryImpl(this._remote);
  final CatalogRemoteDatasource _remote;

  @override
  Future<ProductPageEntity> list(CatalogQuery query, {Object? cancelToken}) {
    return _remote.list(query.toParams(), cancelToken: cancelToken is CancelToken ? cancelToken : null).then((model) => model.page);
  }

  @override
  Future<ProductEntity> getById(String id) => _remote.getById(id).then((model) => model.toEntity());

  @override
  Future<List<CategoryEntity>> categories() => _remote.categories().then((rows) => rows.map((row) => row.entity).toList());

  @override
  Future<List<OccasionEntity>> occasions() => _remote.occasions().then((rows) => rows.map((row) => row.entity).toList());

  @override
  Future<List<String>> customisations() => _remote.customisations();
}
