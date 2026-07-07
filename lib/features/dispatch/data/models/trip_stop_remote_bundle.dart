import 'package:orion_app/features/dispatch/data/models/delivery_model.dart';
import 'package:orion_app/features/dispatch/data/models/trip_stop_model.dart';

/// Parada + entregas anidadas del GET /dispatch/trip-stops (P1-2).
class TripStopRemoteBundle {
  const TripStopRemoteBundle({
    required this.stop,
    required this.deliveries,
    required this.deliveriesFromApi,
  });

  final TripStopModel stop;
  final List<DeliveryModel> deliveries;
  final bool deliveriesFromApi;
}
