import 'package:dio/dio.dart';
import 'package:orion_app/core/constants/api_constants.dart';
import 'package:orion_app/features/auth/data/models/driver_session_model.dart';
import 'package:orion_app/features/auth/data/models/login_request_model.dart';

abstract class AuthRemoteDataSource {
  Future<DriverSessionModel> login(LoginRequestModel request);

  Future<DriverSessionModel> refresh(String accessToken);

  Future<void> logoutRemote(String accessToken);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<DriverSessionModel> login(LoginRequestModel request) async {
    final response = await _dio.post(
      ApiConstants.login,
      data: request.toJson(),
    );
    return DriverSessionModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<DriverSessionModel> refresh(String accessToken) async {
    final response = await _dio.post(
      ApiConstants.refreshToken,
      options: Options(
        headers: {
          ApiConstants.authorizationHeader:
              '${ApiConstants.bearerPrefix}$accessToken',
        },
      ),
    );
    return DriverSessionModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<void> logoutRemote(String accessToken) async {
    await _dio.post(
      ApiConstants.logout,
      options: Options(
        headers: {
          ApiConstants.authorizationHeader:
              '${ApiConstants.bearerPrefix}$accessToken',
        },
      ),
    );
  }
}
