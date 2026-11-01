import 'package:dio/dio.dart';

class ApiFailure implements Exception {
  final String message;
  final int? statusCode;
  final bool cancelled;
  final List<Map<String, String>> fieldErrors;

  const ApiFailure(
    this.message, {
    this.statusCode,
    this.cancelled = false,
    this.fieldErrors = const [],
  });

  @override
  String toString() => message;
}

ApiFailure mapDioError(DioException error) {
  if (error.type == DioExceptionType.cancel) {
    return const ApiFailure('Request cancelled.', cancelled: true);
  }
  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.receiveTimeout) {
    return const ApiFailure('The catalogue took too long to respond. Try again.');
  }
  if (error.type == DioExceptionType.connectionError) {
    final detail = error.message?.toLowerCase() ?? '';
    if (detail.contains('failed host lookup') || detail.contains('nodename')) {
      return const ApiFailure('The catalogue address could not be found. Check the API host and try again.');
    }
    return const ApiFailure('No internet connection. Check the network and try again.');
  }
  if (error.type == DioExceptionType.badResponse) {
    return _fromResponse(error.response);
  }
  if (error.error is FormatException) {
    return const ApiFailure('The server returned a response that was not valid JSON.');
  }
  return const ApiFailure('The catalogue could not be reached. Try again.');
}

ApiFailure _fromResponse(Response<dynamic>? response) {
  final status = response?.statusCode;
  final data = response?.data;
  if (data is! Map) {
    return ApiFailure('The server returned an unexpected response.', statusCode: status);
  }
  final message = data['message'];
  final errors = <Map<String, String>>[];
  final rawErrors = data['errors'];
  if (rawErrors is List) {
    for (final item in rawErrors) {
      if (item is Map && item['message'] is String) {
        errors.add({
          'field': item['field'] is String ? item['field'] as String : 'form',
          'message': item['message'] as String,
        });
      }
    }
  }
  final text = message is String && message.trim().isNotEmpty
      ? message
      : switch (status) {
          400 => 'The request is not valid.',
          401 => 'Sign in required.',
          403 => 'You do not have access to this resource.',
          404 => 'That item is not available.',
          409 => 'This submission was already used for a different enquiry.',
          422 => 'The request is not valid.',
          429 => 'Too many requests. Wait a moment and try again.',
          500 => 'The server could not complete the request.',
          _ => 'The request failed.',
        };
  return ApiFailure(text, statusCode: status, fieldErrors: errors);
}

Map<String, dynamic> readEnvelope(dynamic data) {
  if (data is! Map) {
    throw const ApiFailure('The server returned a response that was not valid JSON.');
  }
  final map = Map<String, dynamic>.from(data);
  if (map['success'] != true) {
    throw ApiFailure(
      map['message'] is String ? map['message'] as String : 'The request failed.',
      statusCode: map['statusCode'] is int ? map['statusCode'] as int : null,
    );
  }
  return map;
}
