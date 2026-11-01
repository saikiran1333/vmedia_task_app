import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/network_providers.dart';
import '../../data/datasources/hello_remote_datasource.dart';
import '../../data/repository_impl/hello_repository_impl.dart';
import '../../domain/repositories/hello_repository.dart';
import 'state/hello_state.dart';

// Datasource Provider
final helloRemoteDatasourceProvider = Provider<HelloRemoteDatasource>((ref) {
  final dio = ref.watch(dioProvider);
  return HelloRemoteDatasourceImpl(dio);
});

// Repository Provider
final helloRepositoryProvider = Provider<HelloRepository>((ref) {
  final datasource = ref.watch(helloRemoteDatasourceProvider);
  return HelloRepositoryImpl(datasource);
});

// ViewModel Provider
final helloViewModelProvider =
    StateNotifierProvider<HelloViewModel, HelloState>((ref) {
  final repository = ref.watch(helloRepositoryProvider);
  return HelloViewModel(repository);
});

class HelloViewModel extends StateNotifier<HelloState> {
  final HelloRepository _repository;

  HelloViewModel(this._repository) : super(const HelloState());

  Future<void> fetchHelloData() async {
    debugPrint('[Vmedia][hello] loading');
    state = state.copyWith(status: HelloStatus.loading);
    try {
      final data = await _repository.fetchHelloData();
      if (data.title.trim().isEmpty) {
        debugPrint('[Vmedia][hello] empty title');
        state = state.copyWith(
          status: HelloStatus.error,
          errorMessage: 'No data found',
        );
        return;
      }
      debugPrint('[Vmedia][hello] success id=${data.id}');
      state = state.copyWith(
        status: HelloStatus.success,
        helloData: data,
      );
    } catch (e) {
      debugPrint('[Vmedia][hello] error $e');
      state = state.copyWith(
        status: HelloStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}
