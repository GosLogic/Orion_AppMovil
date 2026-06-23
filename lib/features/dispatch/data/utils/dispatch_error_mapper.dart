import 'package:dio/dio.dart';

/// Mensajes de error HTTP legibles para operaciones Dispatch.
String mapDispatchError(DioException exception) {
  switch (exception.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Sin conexión. Los cambios se sincronizarán automáticamente.';
    case DioExceptionType.connectionError:
      return 'Sin conexión al servidor. Los cambios se guardan localmente.';
    case DioExceptionType.badResponse:
      return _mapStatusCode(exception.response?.statusCode);
    case DioExceptionType.cancel:
      return exception.message ?? 'Solicitud cancelada';
    case DioExceptionType.badCertificate:
      return 'Certificado del servidor no válido';
    case DioExceptionType.unknown:
      return exception.message ??
          'Error de red al comunicarse con Dispatch';
  }
}

String _mapStatusCode(int? statusCode) {
  return switch (statusCode) {
    401 => 'Sesión expirada. Vuelve a iniciar sesión.',
    403 => 'No tienes permiso para esta hoja de ruta.',
    404 => 'Recurso no encontrado.',
    409 => 'La jornada ya fue completada.',
    _ => 'Error del servidor (${statusCode ?? 'desconocido'}).',
  };
}
