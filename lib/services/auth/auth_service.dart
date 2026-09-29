import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/firebase_error_handler.dart';

/// Low-level Firebase Authentication service.
/// Only interacts with FirebaseAuth — no business logic.
class AuthService {
  AuthService(this._auth);
  final FirebaseAuth _auth;

  /// Returns the currently signed-in Firebase user.
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Signs in with email and password.
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw FirebaseErrorHandler.handleAuthError(e);
    } catch (e) {
      throw AuthException(
          message: FirebaseErrorHandler.toMessage(e),
          originalError: e);
    }
  }

  /// Creates a new user with email and password.
  Future<UserCredential> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw FirebaseErrorHandler.handleAuthError(e);
    } catch (e) {
      throw AuthException(
          message: FirebaseErrorHandler.toMessage(e),
          originalError: e);
    }
  }

  /// Sends a password reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw FirebaseErrorHandler.handleAuthError(e);
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw AuthException(
          message: 'Sign out failed. Please try again.',
          originalError: e);
    }
  }

  /// Returns true if a user is currently signed in.
  bool get isSignedIn => _auth.currentUser != null;

  /// Returns the current user's UID or throws if not authenticated.
  String get currentUid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const UnauthorisedException();
    return uid;
  }
}
