import 'package:equatable/equatable.dart';

enum TelemetryStatus {
  trackingStopped,
  trackingActive,
  gpsError,
}

class TelemetryState extends Equatable {
  final TelemetryStatus status;
  final int? activeVehicleId;
  final int? activeRouteSheetId;
  final String? errorMessage;

  const TelemetryState({
    this.status = TelemetryStatus.trackingStopped,
    this.activeVehicleId,
    this.activeRouteSheetId,
    this.errorMessage,
  });

  bool get isTrackingActive => status == TelemetryStatus.trackingActive;

  TelemetryState copyWith({
    TelemetryStatus? status,
    int? activeVehicleId,
    int? activeRouteSheetId,
    String? errorMessage,
    bool clearError = false,
    bool clearContext = false,
  }) {
    return TelemetryState(
      status: status ?? this.status,
      activeVehicleId:
          clearContext ? null : (activeVehicleId ?? this.activeVehicleId),
      activeRouteSheetId: clearContext
          ? null
          : (activeRouteSheetId ?? this.activeRouteSheetId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props =>
      [status, activeVehicleId, activeRouteSheetId, errorMessage];
}
