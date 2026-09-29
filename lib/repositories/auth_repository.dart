import '../models/user_model.dart';
import '../models/patient_model.dart';
import '../services/auth/auth_service.dart';
import '../services/firestore/user_firestore_service.dart';
import '../services/firestore/patient_firestore_service.dart';
import '../core/errors/app_exception.dart';

/// Repository bridging AuthService, UserFirestoreService and PatientFirestoreService.
/// Provides the full sign-in flow: auth + fetch user profile.
class AuthRepository {
  AuthRepository(
    this._authService,
    this._userService,
    this._patientService,
  );

  final AuthService _authService;
  final UserFirestoreService _userService;
  final PatientFirestoreService _patientService;

  Stream<UserModel?> get userStream {
    return _authService.authStateChanges.asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      try {
        var user = await _userService.getUserById(firebaseUser.uid);
        // If a patient profile exists in /patients, strictly enforce role: 'patient'
        final patient = await _patientService.getPatientById(firebaseUser.uid);
        if (patient != null) {
          if (user == null || user.role != 'patient') {
            final patientUser = UserModel(
              uid: firebaseUser.uid,
              fullName: patient.fullName,
              email: patient.email ?? firebaseUser.email ?? '',
              phone: patient.phone,
              role: 'patient',
              patientId: firebaseUser.uid,
              active: true,
              createdAt: patient.createdAt,
            );
            await _userService.saveUser(patientUser);
            user = patientUser;
          }
        }
        return user;
      } catch (_) {
        return null;
      }
    });
  }

  /// Sign in and return the UserModel with role info.
  Future<UserModel> signIn(String email, String password) async {
    final credential = await _authService.signInWithEmailAndPassword(
        email, password);
    final uid = credential.user!.uid;

    // 1. Check if this account has an associated patient record in /patients
    PatientModel? patientRecord;
    try {
      patientRecord = await _patientService.getPatientById(uid);
    } catch (_) {}

    var user = await _userService.getUserById(uid);

    // If patient record exists, strictly enforce role: 'patient' (self-healing)
    if (patientRecord != null) {
      if (user == null || user.role != 'patient') {
        final patientUser = UserModel(
          uid: uid,
          fullName: patientRecord.fullName,
          email: patientRecord.email ?? email,
          phone: patientRecord.phone,
          role: 'patient',
          patientId: uid,
          active: true,
          createdAt: patientRecord.createdAt,
        );
        try {
          await _userService.saveUser(patientUser);
        } catch (_) {}
        user = patientUser;
      }
    }

    if (user == null) {
      final hasUsers = await _userService.hasAnyUsers();
      final namePart = email.split('@')[0].replaceAll('.', ' ');
      final formattedName = namePart.split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
      if (!hasUsers) {
        // Auto-provision initial super_admin profile for the very first account
        final newUser = UserModel(
          uid: uid,
          fullName: credential.user?.displayName?.isNotEmpty == true
              ? credential.user!.displayName!
              : formattedName,
          email: email,
          phone: credential.user?.phoneNumber ?? '',
          role: 'super_admin',
          active: true,
          createdAt: DateTime.now(),
        );
        try {
          await _userService.saveUser(newUser);
          user = newUser;
        } catch (e) {
          await _authService.signOut();
          throw const AuthException(
            message: 'Failed to initialize administrator account profile. Please try again.',
            code: 'profile_creation_failed',
          );
        }
      } else {
        // Account exists in Firebase Auth but has no Firestore profile (e.g. registration step was interrupted).
        // Safely create pending staff profile for administrator approval.
        final pendingUser = UserModel(
          uid: uid,
          fullName: credential.user?.displayName?.isNotEmpty == true
              ? credential.user!.displayName!
              : formattedName,
          email: email,
          phone: credential.user?.phoneNumber ?? '',
          role: 'doctor',
          active: false,
          createdAt: DateTime.now(),
        );
        try {
          await _userService.saveUser(pendingUser);
        } catch (_) {}
        await _authService.signOut();
        throw const AuthException(
          message: 'Your registration has been submitted and is pending administrator approval. Please wait for an administrator to activate your account.',
          code: 'account_pending_approval',
        );
      }
    }
    if (!user.active) {
      await _authService.signOut();
      throw const AuthException(
        message: 'Your account is pending approval or has been deactivated. '
            'Please contact your administrator.',
        code: 'account_inactive',
      );
    }
    return user;
  }

  /// Register a new staff account and create their Firestore profile.
  /// All sign-up accounts are created with active:false and require
  /// admin approval before they can log in.
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
    String? departmentId,
  }) async {
    final credential = await _authService
        .createUserWithEmailAndPassword(email, password)
        .timeout(const Duration(seconds: 25));
    final uid = credential.user!.uid;

    final newUser = UserModel(
      uid: uid,
      fullName: fullName.trim(),
      email: email.trim(),
      phone: phone.trim(),
      role: role,
      departmentId: departmentId,
      active: false, // All new staff accounts require admin approval
      createdAt: DateTime.now(),
    );

    // Write the user doc. The newly created Firebase Auth user is the
    // only one who can create their own /users/{uid} document (per rules).
    try {
      await _userService
          .saveUser(newUser)
          .timeout(const Duration(seconds: 25));
    } catch (e) {
      try {
        await _authService.signOut().timeout(const Duration(seconds: 5));
      } catch (_) {}
      rethrow;
    }

    // Sign out immediately — staff account is pending approval.
    try {
      await _authService.signOut().timeout(const Duration(seconds: 10));
    } catch (_) {
      // Even if sign out fails, the pending account is saved
    }
    return newUser;
  }

  /// Register a new patient account and create both UserModel and PatientModel.
  /// Patient accounts are ACTIVE immediately and stay logged in.
  Future<UserModel> signUpPatient({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String gender,
    DateTime? dateOfBirth,
    String? address,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? bloodGroup,
    String? genotype,
    List<String> allergies = const [],
    String? medicalHistory,
    String? insuranceProvider,
    String? insuranceNumber,
  }) async {
    final credential = await _authService
        .createUserWithEmailAndPassword(email, password)
        .timeout(const Duration(seconds: 25));
    final uid = credential.user!.uid;

    final timestampSuffix = DateTime.now().millisecondsSinceEpoch.toString();
    final hospitalNumber = 'MFP-${timestampSuffix.substring(timestampSuffix.length - 6)}';

    // 1. Create PatientModel
    final patient = PatientModel(
      patientId: uid,
      hospitalNumber: hospitalNumber,
      fullName: fullName.trim(),
      gender: gender,
      phone: phone.trim(),
      dateOfBirth: dateOfBirth,
      email: email.trim(),
      address: address,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
      bloodGroup: bloodGroup,
      genotype: genotype,
      allergies: allergies,
      medicalHistory: medicalHistory,
      insuranceProvider: insuranceProvider,
      insuranceNumber: insuranceNumber,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _patientService.savePatient(patient);

    // 2. Create UserModel
    final newUser = UserModel(
      uid: uid,
      fullName: fullName.trim(),
      email: email.trim(),
      phone: phone.trim(),
      role: 'patient',
      patientId: uid,
      active: true, // Patients are active immediately!
      createdAt: DateTime.now(),
    );

    await _userService.saveUser(newUser);
    return newUser;
  }

  Stream<List<UserModel>> streamPendingUsers() =>
      _userService.streamPendingUsers();

  Stream<List<UserModel>> streamAllStaff() => _userService.streamAllStaff();

  Future<void> activateUser(String uid) => _userService.activateUser(uid);

  Future<void> deactivateUser(String uid) => _userService.deactivateUser(uid);

  Future<void> updateUser(String uid, Map<String, dynamic> data) =>
      _userService.updateUser(uid, data);

  Future<void> rejectUser(String uid) => _userService.deleteUser(uid);

  Future<void> sendPasswordResetEmail(String email) =>
      _authService.sendPasswordResetEmail(email);

  Future<void> signOut() => _authService.signOut();

  UserModel? _cachedUser;

  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser == null) return null;
    _cachedUser = await _userService.getUserById(firebaseUser.uid);
    return _cachedUser;
  }

  bool get isSignedIn => _authService.isSignedIn;

  Stream<UserModel?> streamCurrentUser() {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return Stream.value(null);
    return _userService.streamUser(uid);
  }
}
