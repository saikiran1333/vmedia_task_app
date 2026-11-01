import '../../domain/enquiry_rules.dart';
import '../../domain/repositories/enquiry_repository.dart';
import '../datasources/enquiry_remote_datasource.dart';

class EnquiryRepositoryImpl implements EnquiryRepository {
  EnquiryRepositoryImpl(this._remote);
  final EnquiryRemoteDatasource _remote;

  @override
  Future<EnquiryReceipt> submit(Map<String, dynamic> body, String idempotencyKey) {
    return _remote.submit(body, idempotencyKey);
  }
}
