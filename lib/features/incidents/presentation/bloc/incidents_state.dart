import 'package:equatable/equatable.dart';
import 'package:orion_app/features/incidents/domain/entities/maintenance_request.dart';

enum IncidentsStatus { initial, loading, success, failure }

class IncidentsState extends Equatable {
  final IncidentsStatus status;
  final String? message;
  final String? errorMessage;
  final List<MaintenanceRequest> maintenanceHistory;

  const IncidentsState({
    this.status = IncidentsStatus.initial,
    this.message,
    this.errorMessage,
    this.maintenanceHistory = const [],
  });

  bool get isLoading => status == IncidentsStatus.loading;

  IncidentsState copyWith({
    IncidentsStatus? status,
    String? message,
    String? errorMessage,
    List<MaintenanceRequest>? maintenanceHistory,
    bool clearMessages = false,
  }) {
    return IncidentsState(
      status: status ?? this.status,
      message: clearMessages ? null : (message ?? this.message),
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      maintenanceHistory: maintenanceHistory ?? this.maintenanceHistory,
    );
  }

  @override
  List<Object?> get props =>
      [status, message, errorMessage, maintenanceHistory];
}
