/// Base application exception.
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'AppException($code): $message';
}

/// Thrown when authentication fails or session is invalid.
class AuthException extends AppException {
  const AuthException({required super.message, super.code, super.originalError});
}

/// Thrown when a Firestore operation fails.
class DatabaseException extends AppException {
  const DatabaseException({required super.message, super.code, super.originalError});
}

/// Thrown when a network operation fails.
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'No internet connection. Please check your network.',
    super.code = 'no_network',
    super.originalError,
  });
}

/// Thrown when data validation fails.
class ValidationException extends AppException {
  const ValidationException({required super.message, super.code, super.originalError});
}

/// Thrown when a requested resource is not found.
class NotFoundException extends AppException {
  const NotFoundException({required super.message, super.code, super.originalError});
}

/// Thrown when a user attempts an unauthorised action.
class UnauthorisedException extends AppException {
  const UnauthorisedException({
    super.message = 'You are not authorised to perform this action.',
    super.code = 'unauthorised',
    super.originalError,
  });
}

/// Thrown when a duplicate record is detected.
class DuplicateException extends AppException {
  const DuplicateException({required super.message, super.code, super.originalError});
}
