import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:orion_app/core/constants/api_constants.dart';
import 'package:orion_app/core/network/auth_token_provider.dart';

/// Cliente HTTP para orion-notification-service.
/// Requiere X-Tenant-Id en todas las peticiones.
class NotificationApiClient {
  NotificationApiClient({
    required AuthTokenProvider tokenProvider,
    String? baseUrl,
    Dio? dio,
  })  : _tokenProvider = tokenProvider,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? ApiConstants.notificationBaseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                sendTimeout: const Duration(seconds: 15),
                headers: const {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(onRequest: _onRequest),
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
    if (tenantId == null || tenantId.isEmpty) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.cancel,
          message: 'X-Tenant-Id obligatorio para notificaciones.',
        ),
      );
      return;
    }

    options.headers[ApiConstants.tenantIdHeader] = tenantId;

    final jwt = await _tokenProvider.getJwt();
    if (jwt != null && jwt.isNotEmpty) {
      options.headers[ApiConstants.authorizationHeader] =
          '${ApiConstants.bearerPrefix}$jwt';
    }

    handler.next(options);
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(String path, {Object? data}) {
    return _dio.post<T>(path, data: data);
  }
}
