import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Logs temporales de integración Dispatch (solo debug).
class DispatchIntegrationLog {
  DispatchIntegrationLog._();

  static void request({
    required String method,
    required String path,
    Map<String, dynamic>? headers,
    Object? body,
  }) {
    if (!kDebugMode) return;
    debugPrint('[Dispatch] → $method ${Uri.parse(path).path}');
    if (headers != null) {
      debugPrint('[Dispatch]   headers: ${_sanitizeHeaders(headers)}');
    }
    if (body != null) {
      debugPrint('[Dispatch]   body: $body');
    }
  }

  static void response(Response<dynamic> response) {
    if (!kDebugMode) return;
    debugPrint(
      '[Dispatch] ← ${response.statusCode} ${response.requestOptions.uri.path}',
    );
    debugPrint('[Dispatch]   body: ${response.data}');
  }

  static void error(DioException error) {
    if (!kDebugMode) return;
    debugPrint(
      '[Dispatch] ✗ ${error.response?.statusCode ?? '—'} '
      '${error.requestOptions.uri.path}',
    );
    debugPrint('[Dispatch]   message: ${error.message}');
    if (error.response?.data != null) {
      debugPrint('[Dispatch]   body: ${error.response?.data}');
    }
  }

  static Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
    final sanitized = Map<String, dynamic>.from(headers);
    for (final key in ['Authorization', 'authorization']) {
      final value = sanitized[key]?.toString();
      if (value != null && value.startsWith('Bearer ')) {
        final token = value.substring(7);
        sanitized[key] = 'Bearer ${_maskToken(token)}';
      }
    }
    return sanitized;
  }

  static String _maskToken(String token) {
    if (token.length <= 12) return '***';
    return '${token.substring(0, 6)}...${token.substring(token.length - 4)}';
  }
}
