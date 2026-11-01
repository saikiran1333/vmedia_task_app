import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_endpoints.dart';
import 'dio_client.dart';

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

final dioProvider = Provider<Dio>((ref) {
  return ref.watch(dioClientProvider).dio;
});

final catalogDioProvider = Provider<Dio>((ref) {
  return DioClient(baseUrl: ApiEndpoints.catalogBaseUrl).dio;
});
