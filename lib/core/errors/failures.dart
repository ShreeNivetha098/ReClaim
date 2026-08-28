/// Base failure class for Clean Architecture Domain layer
abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'A server error occurred', String? code])
      : super(code: code);
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'Network connection failed. Please check your connection.',
    String? code,
  ]) : super(code: code);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed', String? code])
      : super(code: code);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Permission denied', String? code])
      : super(code: code);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([
    super.message = 'Requested resource was not found',
    String? code,
  ]) : super(code: code);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Invalid input data', String? code])
      : super(code: code);
}
