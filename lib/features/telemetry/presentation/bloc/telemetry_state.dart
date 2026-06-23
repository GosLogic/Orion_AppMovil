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
  final int pendingCount;
  final DateTime? lastSyncedAt;
  final bool isSyncing;
  final String? errorMessage;
  final String? warningMessage;

  const TelemetryState({
    this.status = TelemetryStatus.trackingStopped,
    this.activeVehicleId,
    this.activeRouteSheetId,
    this.pendingCount = 0,
    this.lastSyncedAt,
    this.isSyncing = false,
    this.errorMessage,
    this.warningMessage,
  });

  bool get isTrackingActive => status == TelemetryStatus.trackingActive;

  TelemetryState copyWith({
    TelemetryStatus? status,
    int? activeVehicleId,
    int? activeRouteSheetId,
    int? pendingCount,
    DateTime? lastSyncedAt,
    bool? isSyncing,
    String? errorMessage,
    String? warningMessage,
    bool clearError = false,
    bool clearWarning = false,
    bool clearContext = false,
  }) {
    return TelemetryState(
      status: status ?? this.status,
      activeVehicleId:
          clearContext ? null : (activeVehicleId ?? this.activeVehicleId),
      activeRouteSheetId: clearContext
          ? null
          : (activeRouteSheetId ?? this.activeRouteSheetId),
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isSyncing: isSyncing ?? this.isSyncing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      warningMessage:
          clearWarning ? null : (warningMessage ?? this.warningMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        activeVehicleId,
        activeRouteSheetId,
        pendingCount,
        lastSyncedAt,
        isSyncing,
        errorMessage,
        warningMessage,
      ];
}
