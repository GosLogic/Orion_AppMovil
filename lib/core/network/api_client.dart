import 'dart:async';

import 'package:dio/dio.dart';
import 'package:orion_app/core/auth/session_expired_notifier.dart';
import 'package:orion_app/core/constants/api_constants.dart';
import 'package:orion_app/core/network/auth_token_provider.dart';
import 'package:orion_app/features/auth/data/datasources/auth_local_datasource.dart';

class ApiClient {
  ApiClient({
    required AuthTokenProvider tokenProvider,
    AuthLocalDataSource? authLocalDataSource,
    String? baseUrl,
    Dio? dio,
  })  : _tokenProvider = tokenProvider,
        _authLocalDataSource = authLocalDataSource,
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
      _SessionExpiredInterceptor(_authLocalDataSource),
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
  final AuthLocalDataSource? _authLocalDataSource;
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

    options.headers[ApiConstants.authorizationHeader] =
        '${ApiConstants.bearerPrefix}$jwt';

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

class _SessionExpiredInterceptor extends Interceptor {
  _SessionExpiredInterceptor(this._authLocalDataSource);

  final AuthLocalDataSource? _authLocalDataSource;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      final local = _authLocalDataSource;
      if (local != null) {
        unawaited(local.clearSession());
      }
      SessionExpiredNotifier.instance.notify();
    }
    handler.next(err);
  }
}
