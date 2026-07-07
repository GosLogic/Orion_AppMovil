import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:orion_app/features/dispatch/data/services/stop_destination_resolver.dart';
import 'package:orion_app/features/dispatch/domain/entities/trip_stop.dart';
import 'package:url_launcher/url_launcher.dart';

/// Abre Waze (o Google Maps como respaldo) hacia una parada de entrega.
class WazeNavigationService {
  WazeNavigationService({required StopDestinationResolver destinationResolver})
      : _destinationResolver = destinationResolver;

  final StopDestinationResolver _destinationResolver;

  Future<WazeLaunchResult> navigateToStop(TripStop stop) async {
    try {
      final destination = await _destinationResolver.resolve(stop);

      if (destination != null) {
        final opened = await _openWithCoordinates(destination);
        if (opened) {
          return WazeLaunchResult.success(app: NavigationApp.waze);
        }
      }

      final query = _buildSearchQuery(stop);
      final openedByQuery = await _openWithQuery(query);
      if (openedByQuery) {
        return WazeLaunchResult.success(app: NavigationApp.waze);
      }

      if (destination != null) {
        final mapsOpened = await _openGoogleMapsCoordinates(destination);
        if (mapsOpened) {
          return WazeLaunchResult.success(app: NavigationApp.googleMaps);
        }
      }

      final mapsQueryOpened = await _openGoogleMapsQuery(query);
      if (mapsQueryOpened) {
        return WazeLaunchResult.success(app: NavigationApp.googleMaps);
      }

      return WazeLaunchResult.failure(
        'No se pudo abrir Waze ni Google Maps. '
        'Instala Waze desde Play Store e intenta de nuevo.',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WazeNavigation] error: $e');
      }
      return WazeLaunchResult.failure('Error al abrir navegación: $e');
    }
  }

  String _buildSearchQuery(TripStop stop) {
    if (stop.locationName.isNotEmpty && stop.address.isNotEmpty) {
      return '${stop.locationName}, ${stop.address}, Lima, Perú';
    }
    if (stop.locationName.isNotEmpty) {
      return '${stop.locationName}, Lima, Perú';
    }
    return '${stop.address}, Lima, Perú';
  }

  Future<bool> _openWithCoordinates(LatLng destination) async {
    final lat = destination.latitude;
    final lng = destination.longitude;

    final candidates = [
      Uri.parse('waze://?ll=$lat,$lng&navigate=yes'),
      Uri.parse('https://waze.com/ul?ll=$lat,$lng&navigate=yes'),
    ];

    for (final uri in candidates) {
      if (await _tryLaunch(uri)) return true;
    }

    return false;
  }

  Future<bool> _openWithQuery(String query) async {
    final encoded = Uri.encodeComponent(query);
    final candidates = [
      Uri.parse('waze://?q=$encoded&navigate=yes'),
      Uri.parse('https://waze.com/ul?q=$encoded&navigate=yes'),
    ];

    for (final uri in candidates) {
      if (await _tryLaunch(uri)) return true;
    }
    return false;
  }

  Future<bool> _openGoogleMapsCoordinates(LatLng destination) async {
    final lat = destination.latitude;
    final lng = destination.longitude;
    return _tryLaunch(
      Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving'),
    );
  }

  Future<bool> _openGoogleMapsQuery(String query) async {
    final encoded = Uri.encodeComponent(query);
    return _tryLaunch(
      Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$encoded&travelmode=driving'),
    );
  }

  Future<bool> _tryLaunch(Uri uri) async {
    try {
      final can = await canLaunchUrl(uri);
      if (!can) return false;
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}

enum NavigationApp { waze, googleMaps }

class WazeLaunchResult {
  const WazeLaunchResult._({
    required this.ok,
    this.app,
    this.message,
  });

  factory WazeLaunchResult.success({required NavigationApp app}) {
    return WazeLaunchResult._(ok: true, app: app);
  }

  factory WazeLaunchResult.failure(String message) {
    return WazeLaunchResult._(ok: false, message: message);
  }

  final bool ok;
  final NavigationApp? app;
  final String? message;
}
