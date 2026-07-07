import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:orion_app/core/utils/result.dart';
import 'package:orion_app/features/telemetry/domain/entities/vehicle_position.dart';
import 'package:orion_app/features/telemetry/domain/usecases/save_position_usecase.dart';

/// Motor de telemetría GPS. Captura posiciones y persiste en SQLite.
class GpsTrackerService {
  GpsTrackerService({required SavePositionUseCase savePositionUseCase})
      : _savePositionUseCase = savePositionUseCase;

  final SavePositionUseCase _savePositionUseCase;

  VoidCallback? onPositionSaved;

  /// Última posición capturada (para UI en vivo).
  final ValueNotifier<VehiclePosition?> lastPosition =
      ValueNotifier<VehiclePosition?>(null);

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

    try {
      await _captureAndPersist();
      _timer = Timer.periodic(captureInterval, (_) => _captureSafely());
    } catch (e) {
      _isTracking = false;
      _vehicleId = null;
      _routeSheetId = null;
      rethrow;
    }
  }

  Future<void> stopTracking() async {
    _isTracking = false;
    _timer?.cancel();
    _timer = null;
    _vehicleId = null;
    _routeSheetId = null;
    lastPosition.value = null;
  }

  Future<void> _ensureLocationPermissions() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const GpsTrackerException(
        'Servicio de ubicación desactivado. Actívalo en Ajustes del teléfono '
        'o en el emulador: Extended Controls → Location.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const GpsTrackerException(
        'Permiso de ubicación denegado. Acepta el permiso cuando la app lo pida.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const GpsTrackerException(
        'Permiso denegado permanentemente. Ve a Ajustes → Apps → Orion → '
        'Permisos → Ubicación y actívalo.',
      );
    }
  }

  Future<void> _captureSafely() async {
    try {
      await _captureAndPersist();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[GPS] Captura periódica fallida: $e');
      }
    }
  }

  Future<void> _captureAndPersist() async {
    if (!_isTracking || _vehicleId == null) return;

    final position = await _readPosition();

    final lat = position.latitude;
    final lng = position.longitude;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      throw GpsTrackerException(
        'Coordenadas inválidas ($lat, $lng)',
      );
    }

    final heading = position.heading.isNaN
        ? 0
        : position.heading.round().clamp(0, 359);
    final speedKmh = position.speed.isNaN
        ? 0.0
        : (position.speed * 3.6).clamp(0.0, 300.0);

    final vehiclePosition = VehiclePosition(
      time: DateTime.now(),
      vehicleId: _vehicleId!,
      latitude: lat,
      longitude: lng,
      speedKmh: speedKmh,
      heading: heading,
      routeSheetId: _routeSheetId,
      isMocked: position.isMocked,
    );

    final result = await _savePositionUseCase(vehiclePosition);
    if (result case Error(failure: final failure)) {
      throw GpsTrackerException(failure.message);
    }

    if (kDebugMode) {
      debugPrint(
        '[GPS] Guardado local: $lat, $lng · vehicle=${_vehicleId!} '
        '· mocked=${position.isMocked}',
      );
    }

    lastPosition.value = vehiclePosition;
    onPositionSaved?.call();
  }

  /// Última posición conocida primero; si no hay, espera fix actual (emulador).
  Future<Position> _readPosition() async {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.medium,
      timeLimit: Duration(seconds: 20),
    );

    final lastKnown = await Geolocator.getLastKnownPosition();
    if (lastKnown != null) {
      final age = DateTime.now().difference(lastKnown.timestamp);
      if (age.inMinutes < 5) {
        if (kDebugMode) {
          debugPrint('[GPS] Usando última posición conocida (${age.inSeconds}s)');
        }
        return lastKnown;
      }
    }

    try {
      return await Geolocator.getCurrentPosition(locationSettings: settings);
    } catch (e) {
      if (lastKnown != null) {
        if (kDebugMode) {
          debugPrint('[GPS] getCurrentPosition falló, usando lastKnown: $e');
        }
        return lastKnown;
      }
      throw GpsTrackerException(
        'No se pudo obtener ubicación: $e. '
        'En emulador: Extended Controls (⋯) → Location → elige un punto.',
      );
    }
  }
}

class GpsTrackerException implements Exception {
  final String message;

  const GpsTrackerException(this.message);

  @override
  String toString() => message;
}
