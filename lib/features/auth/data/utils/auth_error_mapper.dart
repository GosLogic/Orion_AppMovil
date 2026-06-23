import 'package:dio/dio.dart';

String mapAuthLoginError(DioException exception) {
  switch (exception.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Tiempo de espera agotado. Verifica que el backend esté en ejecución.';
    case DioExceptionType.connectionError:
      return 'Sin conexión al servidor. Revisa la red y la URL del API.';
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
