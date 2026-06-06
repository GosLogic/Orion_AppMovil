import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:orion_app/core/utils/result.dart';
import 'package:orion_app/features/telemetry/domain/entities/vehicle_position.dart';
import 'package:orion_app/features/telemetry/domain/usecases/save_position_usecase.dart';

/// Motor silencioso de telemetría GPS.
/// Captura posiciones cada 5 segundos y persiste exclusivamente en SQLite.
class GpsTrackerService {
  GpsTrackerService({required SavePositionUseCase savePositionUseCase})
      : _savePositionUseCase = savePositionUseCase;

  final SavePositionUseCase _savePositionUseCase;

  static const Duration captureInterval = Duration(seconds: 5);

  Timer? _timer;
  int? _vehicleId;
  int? _routeSheetId;
  bool _isTracking = false;

  bool get isTracking => _isTracking;

  Future<void> startTracking(int vehicleId, int routeSheetId) async {
    if (_isTracking) return;

    await _ensureLocationPermissions();

    _vehicleId = vehicleId;
    _routeSheetId = routeSheetId;
    _isTracking = true;

    await _captureAndPersist();

    _timer = Timer.periodic(captureInterval, (_) => _captureAndPersist());
  }

  Future<void> stopTracking() async {
    _isTracking = false;
    _timer?.cancel();
    _timer = null;
    _vehicleId = null;
    _routeSheetId = null;
  }

  Future<void> _ensureLocationPermissions() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const GpsTrackerException('Servicio de ubicación desactivado');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const GpsTrackerException('Permiso de ubicación denegado');
    }

    if (permission == LocationPermission.deniedForever) {
      throw const GpsTrackerException(
        'Permiso de ubicación denegado permanentemente',
      );
    }
  }

  Future<void> _captureAndPersist() async {
    if (!_isTracking || _vehicleId == null) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 4),
        ),
      );

      final heading = position.heading.round().clamp(0, 359);
      final speedKmh = (position.speed * 3.6).clamp(0.0, 300.0);

      final vehiclePosition = VehiclePosition(
        time: DateTime.now().toUtc(),
        vehicleId: _vehicleId!,
        latitude: position.latitude,
        longitude: position.longitude,
        speedKmh: speedKmh,
        heading: heading,
        routeSheetId: _routeSheetId,
        isMocked: position.isMocked,
      );

      final result = await _savePositionUseCase(vehiclePosition);
      if (result case Error(failure: final failure)) {
        throw GpsTrackerException(failure.message);
      }
    } on GpsTrackerException {
      rethrow;
    } catch (e) {
      throw GpsTrackerException('Error capturando posición: $e');
    }
  }
}

class GpsTrackerException implements Exception {
  final String message;

  const GpsTrackerException(this.message);

  @override
  String toString() => message;
}
