import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Ubicación del dispositivo al momento de un evento (arrived, delivery, etc.).
class DeviceLocation {
  const DeviceLocation({this.latitude, this.longitude});

  final double? latitude;
  final double? longitude;

  bool get hasFix => latitude != null && longitude != null;

  Map<String, dynamic> toApiFields() => {
        'latitude': latitude,
        'longitude': longitude,
      };
}

/// Captura GPS puntual para auditoría de eventos dispatch.
class DeviceLocationService {
  /// Intenta obtener ubicación actual. Devuelve coords nulas si no hay fix.
  Future<DeviceLocation> captureForEvent() async {
    try {
      await _ensureLocationPermissions();
      final position = await _readPosition();
      return DeviceLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DeviceLocation] Sin fix GPS para evento: $e');
      }
      return const DeviceLocation();
    }
  }

  Future<void> _ensureLocationPermissions() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw StateError('Servicio de ubicación desactivado');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError('Permiso de ubicación denegado');
    }
  }

  Future<Position> _readPosition() async {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.medium,
      timeLimit: Duration(seconds: 15),
    );

    final lastKnown = await Geolocator.getLastKnownPosition();
    if (lastKnown != null) {
      final age = DateTime.now().difference(lastKnown.timestamp);
      if (age.inMinutes < 5) {
        return lastKnown;
      }
    }

    try {
      return await Geolocator.getCurrentPosition(locationSettings: settings);
    } catch (e) {
      if (lastKnown != null) return lastKnown;
      rethrow;
    }
  }
}
