import 'package:dio/dio.dart';

String mapNotificationError(DioException e) {
  final status = e.response?.statusCode;
  final data = e.response?.data;
  String? serverMessage;
  if (data is Map<String, dynamic>) {
    serverMessage = data['message'] as String?;
  }

  if (serverMessage != null && serverMessage.isNotEmpty) {
    return serverMessage;
  }

  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout) {
    return 'Tiempo de espera agotado. Verifica que el servicio de notificaciones esté activo.';
  }

  if (e.type == DioExceptionType.connectionError) {
    return 'No hay conexión con el servidor de notificaciones (puerto 8086).';
  }

  return switch (status) {
    400 => 'Solicitud inválida al servicio de notificaciones.',
    404 => 'Notificación no encontrada o no pertenece a tu tenant.',
    500 => 'Error interno del servidor de notificaciones.',
    _ => e.message ?? 'Error de red al cargar notificaciones.',
  };
}
