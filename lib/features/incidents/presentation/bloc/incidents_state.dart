import 'package:equatable/equatable.dart';

enum IncidentsStatus { initial, loading, success, failure }

class IncidentsState extends Equatable {
  final IncidentsStatus status;
  final String? message;
  final String? errorMessage;

  const IncidentsState({
    this.status = IncidentsStatus.initial,
    this.message,
    this.errorMessage,
  });

  bool get isLoading => status == IncidentsStatus.loading;

  IncidentsState copyWith({
    IncidentsStatus? status,
    String? message,
    String? errorMessage,
    bool clearMessages = false,
  }) {
    return IncidentsState(
      status: status ?? this.status,
      message: clearMessages ? null : (message ?? this.message),
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, message, errorMessage];
}
