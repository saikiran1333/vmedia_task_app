import 'package:equatable/equatable.dart';
import '../../../domain/entities/hello_entity.dart';

enum HelloStatus { initial, loading, success, error }

class HelloState extends Equatable {
  final HelloStatus status;
  final HelloEntity? helloData;
  final String? errorMessage;

  const HelloState({
    this.status = HelloStatus.initial,
    this.helloData,
    this.errorMessage,
  });

  HelloState copyWith({
    HelloStatus? status,
    HelloEntity? helloData,
    String? errorMessage,
  }) {
    return HelloState(
      status: status ?? this.status,
      helloData: helloData ?? this.helloData,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, helloData, errorMessage];
}
