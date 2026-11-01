import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_failure.dart';
import '../../domain/enquiry_rules.dart';

class EnquiryRemoteDatasource {
  EnquiryRemoteDatasource(this._dio);
  final Dio _dio;

  Future<EnquiryReceipt> submit(Map<String, dynamic> body, String idempotencyKey) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.enquiries,
        data: body,
        options: Options(headers: {'Idempotency-Key': idempotencyKey}),
      );
      final envelope = readEnvelope(response.data);
      final data = envelope['data'];
      if (data is! Map) throw const ApiFailure('The enquiry response was incomplete.');
      final map = Map<String, dynamic>.from(data);
      final number = map['enquiryNumber'] as String? ?? '';
      if (number.isEmpty) throw const ApiFailure('The enquiry response was incomplete.');
      return EnquiryReceipt(
        id: map['id'] as String? ?? '',
        enquiryNumber: number,
        createdAt: map['createdAt'] as String? ?? '',
        units: map['units'] is num ? (map['units'] as num).toInt() : 0,
      );
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }
}
