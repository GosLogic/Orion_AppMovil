import 'package:orion_app/features/auth/domain/entities/auth_credentials.dart';

class LoginRequestModel {
  final String email;
  final String password;

  const LoginRequestModel({
    required this.email,
    required this.password,
  });

  factory LoginRequestModel.fromEntity(AuthCredentials credentials) {
    return LoginRequestModel(
      email: credentials.email,
      password: credentials.password,
    );
  }

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}
