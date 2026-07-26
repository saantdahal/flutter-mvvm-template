import '../error/app.failure.dart';

sealed class Result<T> {
  const Result();
}

final class Ok<T> extends Result<T> {
  final T value;

  const Ok(this.value);
}

final class Err<T> extends Result<T> {
  final AppFailure failure;

  const Err(this.failure);
}
