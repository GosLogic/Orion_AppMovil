import 'package:latlong2/latlong.dart';
import 'package:orion_app/features/dispatch/data/services/geocoding_service.dart';
import 'package:orion_app/features/dispatch/domain/entities/trip_stop.dart';

/// Resuelve coordenadas de una parada (backend o geocoding).
class StopDestinationResolver {
  StopDestinationResolver({required GeocodingService geocodingService})
      : _geocodingService = geocodingService;

  final GeocodingService _geocodingService;
  final _cache = <String, LatLng>{};

  Future<LatLng?> resolve(TripStop stop) async {
    if (stop.hasCoordinates) {
      return LatLng(stop.latitude!, stop.longitude!);
    }

    final cached = _cache[stop.id];
    if (cached != null) return cached;

    final geocoded = await _geocodingService.geocodeStop(
      address: stop.address,
      locationName: stop.locationName,
    );
    if (geocoded != null) {
      _cache[stop.id] = geocoded;
    }
    return geocoded;
  }
}
