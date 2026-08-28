/// Custom Exceptions for Data layer operations
class ServerException implements Exception {
  final String message;
  final String? code;

  ServerException([this.message = 'Server Exception', this.code]);
}

class NetworkException implements Exception {
  final String message;

  NetworkException([this.message = 'Network Exception']);
}

class AuthException implements Exception {
  final String message;
  final String? code;

  AuthException([this.message = 'Authentication Exception', this.code]);
}

class StorageException implements Exception {
  final String message;

  StorageException([this.message = 'Storage Exception']);
}
