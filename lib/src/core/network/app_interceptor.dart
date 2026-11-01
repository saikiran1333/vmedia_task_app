import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AppInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('➡️ [REQUEST] ${options.method} ${options.uri}');
      debugPrint('Headers: ${_redact(options.headers)}');
      final path = options.uri.path;
      final sensitive = path.contains('/enquiries') || path.contains('/auth');
      if (options.data != null && !sensitive) debugPrint('Data: ${_redact(options.data)}');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('✔️ [RESPONSE] ${response.statusCode} ${response.requestOptions.uri}');
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('❌ [ERROR] ${err.message} (${err.requestOptions.uri})');
    }
    super.onError(err, handler);
  }
}

Object? _redact(Object? value) {
  if (value is Map) {
    return value.map((key, item) {
      final name = key.toString().toLowerCase();
      final hidden = name.contains('password') || name.contains('token') || name.contains('authorization');
      return MapEntry(key, hidden ? '[redacted]' : _redact(item));
    });
  }
  return value;
}
