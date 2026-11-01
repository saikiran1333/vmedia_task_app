import 'package:dio/dio.dart';
import 'api_endpoints.dart';
import 'app_interceptor.dart';

class DioClient {
  final Dio _dio;

  DioClient({String? baseUrl})
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl ?? ApiEndpoints.baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            sendTimeout: const Duration(seconds: 10),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          ),
        ) {
    _dio.interceptors.add(AppInterceptor());
  }

  Dio get dio => _dio;
}
