import '../../data/remote/app.exception.dart';

sealed class AppFailure {
  final String message;

  const AppFailure(this.message);
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message);
}

final class ServerFailure extends AppFailure {
  const ServerFailure(super.message);
}

final class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure(super.message);
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure(super.message);
}

AppFailure mapExceptionToFailure(Object error) {
  if (error is FetchDataException) return NetworkFailure(error.toString());
  if (error is UnauthorisedException) {
    return UnauthorizedFailure(error.toString());
  }
  if (error is BadRequestException) return ServerFailure(error.toString());
  return UnknownFailure(error.toString());
}
