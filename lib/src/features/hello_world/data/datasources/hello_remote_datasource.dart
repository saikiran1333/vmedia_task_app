import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../models/hello_model.dart';

abstract class HelloRemoteDatasource {
  Future<HelloModel> fetchHelloData();
}

class HelloRemoteDatasourceImpl implements HelloRemoteDatasource {
  final Dio _dio;

  HelloRemoteDatasourceImpl(this._dio);

  @override
  Future<HelloModel> fetchHelloData() async {
    try {
      final response = await _dio.get(ApiEndpoints.dummyPost);
      if (response.data != null && response.data is Map<String, dynamic>) {
        return HelloModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw DioException(
        requestOptions: response.requestOptions,
        error: 'Invalid response format',
      );
    } catch (e) {
      rethrow;
    }
  }
}
