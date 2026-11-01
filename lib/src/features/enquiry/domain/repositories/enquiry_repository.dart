import '../enquiry_rules.dart';

abstract class EnquiryRepository {
  Future<EnquiryReceipt> submit(Map<String, dynamic> body, String idempotencyKey);
}

abstract class EnquiryHistoryRepository {
  Future<List<StoredEnquiry>> read();
  Future<void> save(StoredEnquiry enquiry);
  Future<PendingSubmission?> readPending();
  Future<void> writePending(PendingSubmission pending);
  Future<void> clearPending();
  Future<void> clearHistory();
}

abstract class KeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
}

class MemoryStore implements KeyValueStore {
  final Map<String, String> values = {};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
  @override
  Future<void> remove(String key) async => values.remove(key);
}
