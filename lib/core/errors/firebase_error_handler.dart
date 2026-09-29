import 'package:firebase_auth/firebase_auth.dart';
import 'app_exception.dart';

/// Converts raw Firebase exceptions into user-friendly [AppException]s.
class FirebaseErrorHandler {
  FirebaseErrorHandler._();

  /// Handles [FirebaseAuthException] and returns an [AuthException].
  static AuthException handleAuthError(FirebaseAuthException e) {
    final code = e.code.replaceFirst('auth/', '');
    String message;
    switch (code) {
      case 'user-not-found':
      case 'EMAIL_NOT_FOUND':
        message = 'No account found with this email address.';
        break;
      case 'wrong-password':
      case 'INVALID_PASSWORD':
        message = 'Incorrect password. Please try again.';
        break;
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        message = 'Invalid credentials. Please check your email and password.';
        break;
      case 'email-already-in-use':
      case 'EMAIL_EXISTS':
        message = 'An account with this email already exists. Please sign in instead.';
        break;
      case 'weak-password':
      case 'WEAK_PASSWORD':
        message = 'Password is too weak. Use at least 8 characters.';
        break;
      case 'invalid-email':
      case 'INVALID_EMAIL':
        message = 'The email address is not valid.';
        break;
      case 'user-disabled':
      case 'USER_DISABLED':
        message = 'This account has been disabled. Contact your administrator.';
        break;
      case 'too-many-requests':
      case 'TOO_MANY_ATTEMPTS_TRY_LATER':
        message = 'Too many failed attempts. Please try again later.';
        break;
      case 'network-request-failed':
        message = 'Network error. Please check your internet connection.';
        break;
      case 'requires-recent-login':
        message = 'Please log in again to complete this action.';
        break;
      case 'operation-not-allowed':
        message = 'Email sign-in is not enabled. Please contact your administrator.';
        break;
      default:
        message = e.message?.isNotEmpty == true
            ? e.message!
            : 'Authentication error ($code). Please try again.';
    }
    return AuthException(message: message, code: code, originalError: e);
  }

  /// Handles [FirebaseException] (Firestore/Storage) and returns a [DatabaseException].
  static DatabaseException handleFirestoreError(FirebaseException e) {
    String message;
    switch (e.code) {
      case 'permission-denied':
        message = 'You do not have permission to perform this operation.';
        break;
      case 'not-found':
        message = 'The requested record was not found.';
        break;
      case 'already-exists':
        message = 'A record with this ID already exists.';
        break;
      case 'resource-exhausted':
        message = 'Service is temporarily unavailable. Please try again.';
        break;
      case 'unavailable':
        message = 'Service is currently unavailable. Please check your connection.';
        break;
      case 'deadline-exceeded':
        message = 'The operation timed out. Please try again.';
        break;
      case 'cancelled':
        message = 'The operation was cancelled.';
        break;
      case 'aborted':
        message = 'Operation aborted due to a conflict. Please retry.';
        break;
      default:
        message = e.message?.isNotEmpty == true
            ? e.message!
            : 'A database error occurred. Please try again.';
    }
    return DatabaseException(message: message, code: e.code, originalError: e);
  }

  /// Converts any exception into a user-friendly message string.
  static String toMessage(dynamic error) {
    if (error == null) return '';

    // If it's an AppException, check if it wraps a more specific originalError
    if (error is AppException) {
      if (error.originalError != null &&
          (error.message == 'Sign up failed. Please try again.' ||
           error.message == 'Sign in failed. Please try again.' ||
           error.message.startsWith('An unexpected error'))) {
        return toMessage(error.originalError);
      }
      return error.message;
    }

    if (error is FirebaseAuthException) {
      return handleAuthError(error).message;
    }

    if (error is FirebaseException) {
      if (error.plugin == 'firebase_auth' || error.code.startsWith('auth/')) {
        return handleAuthError(
          FirebaseAuthException(code: error.code, message: error.message),
        ).message;
      }
      return handleFirestoreError(error).message;
    }

    // Inspect error string for common codes (vital for Web JS interop & PlatformException)
    final errStr = error.toString().toLowerCase();

    if (errStr.contains('timeout') || errStr.contains('timeoutexception')) {
      return 'The request timed out. Please check your internet connection and try again.';
    }
    if (errStr.contains('getfirestore')) {
      return 'Database service is connecting. Please refresh the page and try again.';
    }
    if (errStr.contains('email-already-in-use') ||
        errStr.contains('email_exists') ||
        errStr.contains('already in use')) {
      return 'An account with this email already exists. Please sign in instead.';
    }
    if (errStr.contains('user-not-found') || errStr.contains('email_not_found')) {
      return 'No account found with this email address.';
    }
    if (errStr.contains('wrong-password') || errStr.contains('invalid_password')) {
      return 'Incorrect password. Please try again.';
    }
    if (errStr.contains('invalid-credential') ||
        errStr.contains('invalid_credential') ||
        errStr.contains('invalid_login_credentials')) {
      return 'Invalid credentials. Please check your email and password.';
    }
    if (errStr.contains('weak-password') || errStr.contains('weak_password')) {
      return 'Password is too weak. Use at least 8 characters.';
    }
    if (errStr.contains('permission-denied') ||
        errStr.contains('permission_denied')) {
      return 'You do not have permission to perform this operation.';
    }
    if (errStr.contains('network') ||
        errStr.contains('offline') ||
        errStr.contains('unavailable')) {
      return 'Network error. Please check your internet connection.';
    }

    // Clean up generic exception string if readable
    final cleaned = error
        .toString()
        .replaceAll(RegExp(r'^(Exception|Error|PlatformException\([^)]*\)):\s*'), '')
        .trim();
    if (cleaned.isNotEmpty && cleaned.length < 120 && !cleaned.contains('{')) {
      return cleaned;
    }

    return 'An unexpected error occurred. Please try again.';
  }
}
