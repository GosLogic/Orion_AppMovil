import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:orion_app/core/constants/api_constants.dart';
import 'package:orion_app/core/network/auth_token_provider.dart';

/// Cliente HTTP para maintenance-service.
/// Requiere X-Tenant-Id y X-Driver-Id; JWT opcional (gateway).
class MaintenanceApiClient {
  MaintenanceApiClient({
    required AuthTokenProvider tokenProvider,
    String? baseUrl,
    Dio? dio,
  })  : _tokenProvider = tokenProvider,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? ApiConstants.maintenanceBaseUrl,
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 30),
                sendTimeout: const Duration(seconds: 30),
                headers: const {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
        ),
      );
    }
  }

  final AuthTokenProvider _tokenProvider;
  final Dio _dio;

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final tenantId = await _tokenProvider.getTenantId();
    final driverId = await _tokenProvider.getDriverId();

    if (tenantId == null || tenantId.isEmpty) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.cancel,
          message: 'X-Tenant-Id obligatorio para mantenimiento.',
        ),
      );
      return;
    }

    if (driverId == null || driverId.isEmpty) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.cancel,
          message: 'X-Driver-Id obligatorio para mantenimiento.',
        ),
      );
      return;
    }

    options.headers[ApiConstants.tenantIdHeader] = tenantId;
    options.headers[ApiConstants.driverIdHeader] = driverId;

    final jwt = await _tokenProvider.getJwt();
    if (jwt != null && jwt.isNotEmpty) {
      options.headers[ApiConstants.authorizationHeader] =
          '${ApiConstants.bearerPrefix}$jwt';
    }

    handler.next(options);
  }

  Future<Response<T>> post<T>(String path, {Object? data}) {
    return _dio.post<T>(path, data: data);
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get<T>(path, queryParameters: queryParameters);
  }
}
