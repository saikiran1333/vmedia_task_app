import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_failure.dart';
import '../../models/product_model.dart';

abstract class CatalogRemoteDatasource {
  Future<ProductPageModel> list(Map<String, dynamic> query, {CancelToken? cancelToken});
  Future<ProductModel> getById(String id);
  Future<List<CategoryModel>> categories();
  Future<List<OccasionModel>> occasions();
  Future<List<String>> customisations();
}

class CatalogRemoteDatasourceImpl implements CatalogRemoteDatasource {
  CatalogRemoteDatasourceImpl(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> _get(String path, {Map<String, dynamic>? query, CancelToken? cancelToken}) async {
    try {
      final response = await _dio.get(path, queryParameters: query, cancelToken: cancelToken);
      return readEnvelope(response.data);
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  @override
  Future<ProductPageModel> list(Map<String, dynamic> query, {CancelToken? cancelToken}) async {
    return ProductPageModel.fromEnvelope(await _get(ApiEndpoints.products, query: query, cancelToken: cancelToken));
  }

  @override
  Future<ProductModel> getById(String id) async {
    final envelope = await _get('${ApiEndpoints.products}/$id');
    final data = envelope['data'];
    if (data is! Map) throw const ApiFailure('The product response was incomplete.');
    final model = ProductModel.fromJson(Map<String, dynamic>.from(data));
    if (model.entity.id.isEmpty) throw const ApiFailure('The product response was incomplete.');
    return model;
  }

  @override
  Future<List<CategoryModel>> categories() async {
    final data = (await _get(ApiEndpoints.categories))['data'];
    if (data is! List) throw const ApiFailure('The category response was not a list.');
    return data.whereType<Map>().map((row) => CategoryModel.fromJson(Map<String, dynamic>.from(row))).where((item) => item.entity.name.isNotEmpty).toList();
  }

  @override
  Future<List<OccasionModel>> occasions() async {
    final data = (await _get(ApiEndpoints.occasions))['data'];
    if (data is! List) throw const ApiFailure('The occasion response was not a list.');
    return data.whereType<Map>().map((row) => OccasionModel.fromJson(Map<String, dynamic>.from(row))).where((item) => item.entity.enquiryLabel.isNotEmpty).toList();
  }

  @override
  Future<List<String>> customisations() async {
    final data = (await _get(ApiEndpoints.customisations))['data'];
    if (data is! List) throw const ApiFailure('The customisation response was not a list.');
    return data.whereType<Map>().map((row) => row['name']).whereType<String>().toList();
  }
}
