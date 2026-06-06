import 'package:dio/dio.dart';
import 'package:orion_app/core/config/debug_auth_config.dart';
import 'package:orion_app/core/error/failures.dart';
import 'package:orion_app/core/utils/result.dart';
import 'package:orion_app/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:orion_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:orion_app/features/auth/data/models/login_request_model.dart';
import 'package:orion_app/features/auth/domain/entities/auth_credentials.dart';
import 'package:orion_app/features/auth/domain/entities/driver_session.dart';
import 'package:orion_app/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  @override
  Future<Result<DriverSession>> login(AuthCredentials credentials) async {
    try {
      if (DebugAuthConfig.matchesDemoCredentials(credentials)) {
        final session = DebugAuthConfig.createDemoSession();
        await _localDataSource.saveSession(session);
        return Success(session.toEntity());
      }

      final request = LoginRequestModel.fromEntity(credentials);
      final session = await _remoteDataSource.login(request);
      await _localDataSource.saveSession(session);
      return Success(session.toEntity());
    } on DioException catch (e) {
      return Error(AuthFailure(e.message ?? 'Error al iniciar sesión'));
    } catch (e) {
      return Error(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _localDataSource.clearSession();
      return const Success(null);
    } catch (e) {
      return Error(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Result<DriverSession?>> getActiveSession() async {
    try {
      final session = await _localDataSource.getSession();
      if (session == null) return const Success(null);
      if (session.isExpired) {
        await _localDataSource.clearSession();
        return const Error(SessionExpiredFailure());
      }
      return Success(session.toEntity());
    } catch (e) {
      return Error(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Result<bool>> isSessionValid() async {
    final result = await getActiveSession();
    return switch (result) {
      Success(value: final session) => Success(session?.isValid ?? false),
      Error(failure: final failure) => Error(failure),
    };
  }
}
