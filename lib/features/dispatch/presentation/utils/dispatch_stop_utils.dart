import 'package:orion_app/features/dispatch/domain/entities/trip_stop.dart';

/// Utilidades de paradas para navegación y entregas.
class DispatchStopUtils {
  DispatchStopUtils._();

  /// Primera parada pendiente o en llegada, por orden de secuencia.
  static TripStop? nextNavigableStop(List<TripStop> stops) {
    final candidates = stops
        .where(
          (s) =>
              s.status == TripStopStatus.pending ||
              s.status == TripStopStatus.arrived,
        )
        .toList()
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    return candidates.isEmpty ? null : candidates.first;
  }
}
