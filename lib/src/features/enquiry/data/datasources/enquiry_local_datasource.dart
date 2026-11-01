import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/enquiry_rules.dart';
import '../../domain/repositories/enquiry_repository.dart';

class UnavailableStore implements KeyValueStore {
  @override
  Future<String?> read(String key) async {
    throw const HistoryReadException('Saved enquiries on this phone could not be read.');
  }

  @override
  Future<void> write(String key, String value) async {
    throw const HistoryWriteException('The enquiry was sent, but it could not be saved on this phone.');
  }

  @override
  Future<void> remove(String key) async {}
}

class SharedPrefsStore implements KeyValueStore {
  SharedPrefsStore(this._prefs);
  final SharedPreferences _prefs;

  @override
  Future<String?> read(String key) async => _prefs.getString(key);
  @override
  Future<void> write(String key, String value) async => _prefs.setString(key, value);
  @override
  Future<void> remove(String key) async => _prefs.remove(key);
}

class EnquiryHistoryRepositoryImpl implements EnquiryHistoryRepository {
  EnquiryHistoryRepositoryImpl(this._store);
  final KeyValueStore _store;
  static const historyKey = 'vmedia_enquiries_v1';
  static const pendingKey = 'vmedia_enquiry_pending_v1';

  @override
  Future<List<StoredEnquiry>> read() async {
    final raw = await _store.read(historyKey);
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final records = <StoredEnquiry>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final record = StoredEnquiry.fromJson(Map<String, dynamic>.from(item));
        if (record.enquiryNumber.isEmpty) continue;
        records.add(record);
      }
      return records;
    } catch (_) {
      throw const HistoryReadException('Saved enquiries on this phone could not be read.');
    }
  }

  @override
  Future<void> save(StoredEnquiry enquiry) async {
    final current = await _safeRead();
    final next = [enquiry, ...current.where((item) => item.enquiryNumber != enquiry.enquiryNumber)];
    try {
      await _store.write(historyKey, jsonEncode(next.map((item) => item.toJson()).toList()));
    } catch (_) {
      throw const HistoryWriteException('The enquiry was sent, but it could not be saved on this phone.');
    }
  }

  Future<List<StoredEnquiry>> _safeRead() async {
    try {
      return await read();
    } on HistoryReadException {
      return const [];
    }
  }

  @override
  Future<PendingSubmission?> readPending() async {
    final raw = await _store.read(pendingKey);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw);
      if (map is! Map) return null;
      final key = map['key'] as String? ?? '';
      final fingerprint = map['fingerprint'] as String? ?? '';
      if (key.isEmpty || fingerprint.isEmpty) return null;
      return PendingSubmission(key: key, fingerprint: fingerprint);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> writePending(PendingSubmission pending) => _store.write(pendingKey, jsonEncode({'key': pending.key, 'fingerprint': pending.fingerprint}));

  @override
  Future<void> clearPending() => _store.remove(pendingKey);

  @override
  Future<void> clearHistory() => _store.write(historyKey, '[]');
}

class HistoryReadException implements Exception {
  const HistoryReadException(this.message);
  final String message;
  @override
  String toString() => message;
}

class HistoryWriteException implements Exception {
  const HistoryWriteException(this.message);
  final String message;
  @override
  String toString() => message;
}
