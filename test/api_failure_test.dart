import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vmedia/src/core/network/api_failure.dart';
import 'package:vmedia/src/features/catalog/data/datasources/catalog_remote_datasource.dart';
import 'package:vmedia/src/features/enquiry/data/datasources/enquiry_remote_datasource.dart';

void main() {
  test('maps timeouts, connection loss and status codes', () {
    expect(mapDioError(DioException(requestOptions: RequestOptions(), type: DioExceptionType.connectionTimeout)).message, contains('too long'));
    expect(mapDioError(DioException(requestOptions: RequestOptions(), type: DioExceptionType.connectionError, message: 'Failed host lookup')).message, contains('could not be found'));
    expect(mapDioError(DioException(requestOptions: RequestOptions(), type: DioExceptionType.cancel)).cancelled, isTrue);
    final bad = mapDioError(DioException(
      requestOptions: RequestOptions(),
      type: DioExceptionType.badResponse,
      response: Response(requestOptions: RequestOptions(), statusCode: 422, data: {
        'message': 'Enquiry could not be saved.',
        'errors': [
          {'field': 'email', 'message': 'Enter a valid email address.'},
        ],
      }),
    ));
    expect(bad.statusCode, 422);
    expect(bad.fieldErrors.single['field'], 'email');
  });

  test('catalogue datasource reads a product page and rejects a bad envelope', () async {
    final dio = Dio()
      ..interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        handler.resolve(Response(requestOptions: options, statusCode: 200, data: {
          'success': true,
          'data': [
            {'id': 'tg-9', 'slug': 'mug', 'name': 'Mug'},
          ],
          'meta': {'page': 1, 'pageSize': 12, 'total': 1},
        }));
      }));
    final page = await CatalogRemoteDatasourceImpl(dio).list({'page': 1});
    expect(page.page.items.single.name, 'Mug');

    final failing = Dio()
      ..interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        handler.resolve(Response(requestOptions: options, statusCode: 200, data: 'nope'));
      }));
    expect(CatalogRemoteDatasourceImpl(failing).categories(), throwsA(isA<ApiFailure>()));
  });

  test('enquiry datasource returns the receipt', () async {
    final dio = Dio()
      ..interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        expect(options.headers['Idempotency-Key'], 'abcd1234');
        handler.resolve(Response(requestOptions: options, statusCode: 201, data: {
          'success': true,
          'data': {'id': '1', 'enquiryNumber': 'TG-1001', 'createdAt': '2026-11-01T00:00:00.000Z', 'units': 4},
        }));
      }));
    final receipt = await EnquiryRemoteDatasource(dio).submit({'name': 'Asha'}, 'abcd1234');
    expect(receipt.enquiryNumber, 'TG-1001');
  });
}
