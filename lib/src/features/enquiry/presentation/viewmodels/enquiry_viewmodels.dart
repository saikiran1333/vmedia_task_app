import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/network_providers.dart';
import '../../data/datasources/enquiry_local_datasource.dart';
import '../../data/datasources/enquiry_remote_datasource.dart';
import '../../data/repository_impl/enquiry_repository_impl.dart';
import '../../domain/enquiry_rules.dart';
import '../../domain/repositories/enquiry_repository.dart';

final storeProvider = Provider<KeyValueStore>((ref) => MemoryStore());

final enquiryHistoryRepositoryProvider = Provider<EnquiryHistoryRepository>((ref) {
  return EnquiryHistoryRepositoryImpl(ref.watch(storeProvider));
});

final enquiryRepositoryProvider = Provider<EnquiryRepository>((ref) {
  return EnquiryRepositoryImpl(EnquiryRemoteDatasource(ref.watch(catalogDioProvider)));
});

class SelectionViewModel extends StateNotifier<List<SelectedGift>> {
  SelectionViewModel() : super(const []);

  void add(SelectedGift gift) {
    if (state.any((item) => item.id == gift.id)) return;
    if (gift.quantity < 1) return;
    state = [...state, gift];
  }

  void remove(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  void setQuantity(String id, int quantity) {
    if (quantity < 1 || quantity > 10000) return;
    state = [for (final item in state) item.id == id ? item.copyWith(quantity: quantity) : item];
  }

  void clear() => state = const [];

  int get units => totalUnits(state);
}

final selectionProvider = StateNotifierProvider<SelectionViewModel, List<SelectedGift>>((ref) {
  return SelectionViewModel();
});

enum EnquirySubmitStatus { editing, submitting, sent, localSaveFailed }

class EnquiryFormState extends Equatable {
  final EnquirySubmitStatus status;
  final Map<String, String> errors;
  final String? message;
  final EnquiryReceipt? receipt;
  final StoredEnquiry? pendingRecord;

  const EnquiryFormState({
    this.status = EnquirySubmitStatus.editing,
    this.errors = const {},
    this.message,
    this.receipt,
    this.pendingRecord,
  });

  EnquiryFormState copyWith({
    EnquirySubmitStatus? status,
    Map<String, String>? errors,
    String? message,
    bool clearMessage = false,
    EnquiryReceipt? receipt,
    StoredEnquiry? pendingRecord,
  }) {
    return EnquiryFormState(
      status: status ?? this.status,
      errors: errors ?? this.errors,
      message: clearMessage ? null : message ?? this.message,
      receipt: receipt ?? this.receipt,
      pendingRecord: pendingRecord ?? this.pendingRecord,
    );
  }

  @override
  List<Object?> get props => [status, errors, message, receipt, pendingRecord];
}

class EnquiryFormViewModel extends StateNotifier<EnquiryFormState> {
  EnquiryFormViewModel(this._remote, this._history) : super(const EnquiryFormState());
  final EnquiryRepository _remote;
  final EnquiryHistoryRepository _history;

  Future<bool> submit(
    EnquiryDraft draft, {
    required List<String> occasions,
    required List<String> customisations,
  }) async {
    if (state.status == EnquirySubmitStatus.submitting) return false;
    final validation = validateEnquiry(draft, occasions: occasions, customisations: customisations);
    if (!validation.ok) {
      state = EnquiryFormState(status: EnquirySubmitStatus.editing, errors: validation.errors);
      return false;
    }
    state = const EnquiryFormState(status: EnquirySubmitStatus.submitting);
    final body = validation.body!;
    final fingerprint = enquiryFingerprint(body);
    PendingSubmission? stored;
    try {
      stored = await _history.readPending();
    } catch (_) {
      stored = null;
    }
    final pending = resolveIdempotencyKey(stored, fingerprint);
    try {
      await _history.writePending(pending);
    } catch (error) {
      debugPrint('[Vmedia][enquiry] pending key was not stored');
    }
    try {
      final receipt = await _remote.submit(body, pending.key);
      try {
        await _history.clearPending();
      } catch (_) {}
      final record = StoredEnquiry(
        enquiryNumber: receipt.enquiryNumber,
        createdAt: receipt.createdAt,
        occasion: draft.occasion,
        budget: draft.budget,
        units: receipt.units,
        status: 'Submitted',
        products: draft.gifts,
      );
      try {
        await _history.save(record);
        state = EnquiryFormState(status: EnquirySubmitStatus.sent, receipt: receipt, pendingRecord: record);
        debugPrint('[Vmedia][enquiry] sent ${receipt.enquiryNumber}');
      } on HistoryWriteException catch (error) {
        state = EnquiryFormState(
          status: EnquirySubmitStatus.localSaveFailed,
          receipt: receipt,
          pendingRecord: record,
          message: error.message,
        );
      }
      return true;
    } on ApiFailure catch (error) {
      if (error.statusCode == 409) {
        try {
          await _history.clearPending();
        } catch (_) {}
      }
      final errors = {for (final item in error.fieldErrors) item['field'] ?? 'form': item['message'] ?? error.message};
      state = EnquiryFormState(
        status: EnquirySubmitStatus.editing,
        message: error.message,
        errors: errors,
      );
      return false;
    } catch (_) {
      state = const EnquiryFormState(
        status: EnquirySubmitStatus.editing,
        message: 'The enquiry could not be sent. Your details are still here.',
      );
      return false;
    }
  }

  Future<bool> retryLocalSave() async {
    final record = state.pendingRecord;
    final receipt = state.receipt;
    if (record == null || receipt == null) return false;
    try {
      await _history.save(record);
      state = EnquiryFormState(status: EnquirySubmitStatus.sent, receipt: receipt, pendingRecord: record);
      return true;
    } on HistoryWriteException catch (error) {
      state = state.copyWith(message: error.message);
      return false;
    }
  }
}

final enquiryFormViewModelProvider = StateNotifierProvider<EnquiryFormViewModel, EnquiryFormState>((ref) {
  return EnquiryFormViewModel(ref.watch(enquiryRepositoryProvider), ref.watch(enquiryHistoryRepositoryProvider));
});

class HistoryState extends Equatable {
  final LoadStatus status;
  final List<StoredEnquiry> items;
  final String? error;

  const HistoryState({this.status = LoadStatus.idle, this.items = const [], this.error});

  @override
  List<Object?> get props => [status, items, error];
}

enum LoadStatus { idle, loading, ready, error }

class HistoryViewModel extends StateNotifier<HistoryState> {
  HistoryViewModel(this._history) : super(const HistoryState());
  final EnquiryHistoryRepository _history;

  Future<void> load() async {
    state = const HistoryState(status: LoadStatus.loading);
    try {
      final items = await _history.read();
      state = HistoryState(status: LoadStatus.ready, items: items);
    } catch (error) {
      state = HistoryState(status: LoadStatus.error, error: error.toString());
    }
  }

  Future<void> discardUnreadable() async {
    await _history.clearHistory();
    await load();
  }
}

final historyViewModelProvider = StateNotifierProvider<HistoryViewModel, HistoryState>((ref) {
  return HistoryViewModel(ref.watch(enquiryHistoryRepositoryProvider));
});
