import 'package:dio/dio.dart';

String mapAuthLoginError(DioException exception) {
  switch (exception.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'No se pudo conectar al backend. Verifica que docker esté activo, '
          'que PC y celular estén en la misma Wi‑Fi, y que el firewall permita el puerto 8080.';
    case DioExceptionType.connectionError:
      return 'Sin conexión al servidor. En celular físico la app usa la IP de tu PC '
          '(no localhost). Revisa la red y que el Gateway esté en :8080.';
    case DioExceptionType.badResponse:
      final statusCode = exception.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        return 'Credenciales inválidas';
      }
      if (statusCode == 404) {
        return 'Servicio no encontrado. Verifica que el API Gateway esté en ejecución y enrutando /v1/auth.';
      }
      return 'Error del servidor (${statusCode ?? 'desconocido'})';
    case DioExceptionType.cancel:
      return exception.message ?? 'Solicitud cancelada';
    case DioExceptionType.badCertificate:
      return 'Certificado del servidor no válido';
    case DioExceptionType.unknown:
      return exception.message ?? 'Error de red al iniciar sesión';
  }
}
