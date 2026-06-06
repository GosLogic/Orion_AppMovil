import 'package:orion_app/core/error/failures.dart';

sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  final T value;

  const Success(this.value);
}

final class Error<T> extends Result<T> {
  final Failure failure;

  const Error(this.failure);
}
