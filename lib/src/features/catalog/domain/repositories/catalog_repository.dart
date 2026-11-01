import '../entities/product_entity.dart';

abstract class CatalogRepository {
  Future<ProductPageEntity> list(CatalogQuery query, {Object? cancelToken});
  Future<ProductEntity> getById(String id);
  Future<List<CategoryEntity>> categories();
  Future<List<OccasionEntity>> occasions();
  Future<List<String>> customisations();
}
