import 'package:dio/dio.dart';

String mapMaintenanceError(DioException e) {
  final status = e.response?.statusCode;
  final data = e.response?.data;
  String? serverMessage;
  if (data is Map<String, dynamic>) {
    serverMessage = data['message'] as String?;
  }

  if (serverMessage != null && serverMessage.isNotEmpty) {
    return serverMessage;
  }

  return switch (status) {
    400 => 'Datos inválidos. Revisa descripción y severidad.',
    404 => 'Solicitud no encontrada.',
    409 => 'Conflicto al registrar la solicitud.',
    500 => 'Error interno del servidor de mantenimiento.',
    _ => e.message ?? 'Error de red al enviar mantenimiento.',
  };
}
