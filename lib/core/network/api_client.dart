import 'package:dio/dio.dart';
import 'package:orion_app/core/constants/api_constants.dart';
import 'package:orion_app/core/network/auth_token_provider.dart';

class ApiClient {
  ApiClient({
    required AuthTokenProvider tokenProvider,
    String? baseUrl,
    Dio? dio,
  })  : _tokenProvider = tokenProvider,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? ApiConstants.baseUrl,
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 30),
                sendTimeout: const Duration(seconds: 30),
                headers: const {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    _dio.interceptors.addAll([
      _MultiTenantAuthInterceptor(_tokenProvider),
      LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
      ),
    ]);
  }

  final AuthTokenProvider _tokenProvider;
  final Dio _dio;

  Dio get dio => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get<T>(path, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}

class _MultiTenantAuthInterceptor extends Interceptor {
  _MultiTenantAuthInterceptor(this._tokenProvider);

  final AuthTokenProvider _tokenProvider;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final jwt = await _tokenProvider.getJwt();
    final tenantId = await _tokenProvider.getTenantId();
    final driverId = await _tokenProvider.getDriverId();

    if (jwt == null || jwt.isEmpty) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.cancel,
          message: 'JWT obligatorio: no hay sesión activa del conductor.',
        ),
      );
      return;
    }

    if (tenantId == null || tenantId.isEmpty) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.cancel,
          message: 'TenantId obligatorio: contexto multi-tenant no resuelto.',
        ),
      );
      return;
    }

    options.headers[ApiConstants.authorizationHeader] =
        '${ApiConstants.bearerPrefix}$jwt';
    options.headers[ApiConstants.tenantIdHeader] = tenantId;
    if (driverId != null && driverId.isNotEmpty) {
      options.headers[ApiConstants.driverIdHeader] = driverId;
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          type: DioExceptionType.badResponse,
          message: 'Sesión expirada o token inválido.',
        ),
      );
      return;
    }

    handler.next(err);
  }
}
