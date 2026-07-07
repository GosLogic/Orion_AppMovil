import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

/// Geocodifica direcciones con Nominatim (OpenStreetMap).
class GeocodingService {
  GeocodingService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: const {
                  'User-Agent': 'OrionDriverApp/1.0 (fleet navigation)',
                  'Accept': 'application/json',
                },
              ),
            );

  final Dio _dio;

  /// Busca coordenadas probando nombre del lugar + dirección + Lima.
  Future<LatLng?> geocodeStop({
    required String address,
    String? locationName,
  }) async {
    final queries = <String>{
      if (locationName != null && locationName.trim().isNotEmpty)
        '$locationName, $address, Lima, Perú',
      if (locationName != null && locationName.trim().isNotEmpty)
        '$locationName, Lima, Perú',
      '$address, Lima, Perú',
      address.trim(),
    }.where((q) => q.isNotEmpty).toList();

    for (final query in queries) {
      final result = await _search(query, countryCodes: 'pe');
      if (result != null) return result;
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }

    for (final query in queries) {
      final result = await _search(query);
      if (result != null) return result;
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }

    return null;
  }

  Future<LatLng?> _search(String query, {String? countryCodes}) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'limit': 1,
          if (countryCodes != null) 'countrycodes': countryCodes,
        },
      );

      final results = response.data;
      if (results == null || results.isEmpty) return null;

      final first = results.first as Map<String, dynamic>;
      final lat = double.tryParse(first['lat'] as String? ?? '');
      final lon = double.tryParse(first['lon'] as String? ?? '');
      if (lat == null || lon == null) return null;

      if (kDebugMode) {
        debugPrint('[Geocoding] "$query" → $lat, $lon');
      }
      return LatLng(lat, lon);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Geocoding] falló "$query": $e');
      }
      return null;
    }
  }
}
