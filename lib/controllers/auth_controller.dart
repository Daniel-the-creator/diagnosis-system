import 'package:get/get.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../core/constants/route_constants.dart';
import '../core/errors/firebase_error_handler.dart';

/// Manages authentication state and role-based navigation.
class AuthController extends GetxController {
  AuthController(this._authRepo);
  final AuthRepository _authRepo;

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isSignedIn = false.obs;
  final RxBool isSigningUp = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Listen to auth state changes
    _authRepo.userStream.listen(
      (user) {
        if (isSigningUp.value) {
          // Do not auto-navigate or auto-sign-out while sign-up flow is handling itself
          return;
        }
        currentUser.value = user;
        isSignedIn.value = user != null;
        if (user != null) {
          if (!user.active) {
            // Account is pending approval — force sign out immediately
            _authRepo.signOut();
            return;
          }
          _navigateByRole(user.role);
        }
      },
      onError: (_) {
        // Prevent uncaught stream errors from breaking the reactive stream
      },
    );
  }

  Future<void> signIn(String email, String password, {String? targetPortal}) async {
    if (email.trim().isEmpty || password.isEmpty) {
      errorMessage.value = 'Please enter your email and password.';
      return;
    }
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final user = await _authRepo.signIn(email.trim(), password);

      // Enforce portal isolation
      if (targetPortal == 'staff' && user.isPatient) {
        await _authRepo.signOut();
        currentUser.value = null;
        isSignedIn.value = false;
        errorMessage.value =
            'This account is registered as a Patient. Please use the Patient Portal to sign in.';
        return;
      }

      if (targetPortal == 'patient' && !user.isPatient) {
        await _authRepo.signOut();
        currentUser.value = null;
        isSignedIn.value = false;
        errorMessage.value =
            'This account is registered as Hospital Staff. Please use Staff Login.';
        return;
      }

      currentUser.value = user;
      isSignedIn.value = true;
      _navigateByRole(user.role);
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
    String? departmentId,
  }) async {
    isSigningUp.value = true;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final user = await _authRepo
          .signUp(
            email: email,
            password: password,
            fullName: fullName,
            phone: phone,
            role: role,
            departmentId: departmentId,
          )
          .timeout(const Duration(seconds: 30));
      if (user.active) {
        currentUser.value = user;
        isSignedIn.value = true;
        _navigateByRole(user.role);
      }
      return user;
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
      return null;
    } finally {
      isSigningUp.value = false;
      isLoading.value = false;
    }
  }

  Future<UserModel?> signUpPatient({
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
    isSigningUp.value = true;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final user = await _authRepo
          .signUpPatient(
            email: email,
            password: password,
            fullName: fullName,
            phone: phone,
            gender: gender,
            dateOfBirth: dateOfBirth,
            address: address,
            emergencyContactName: emergencyContactName,
            emergencyContactPhone: emergencyContactPhone,
            bloodGroup: bloodGroup,
            genotype: genotype,
            allergies: allergies,
            medicalHistory: medicalHistory,
            insuranceProvider: insuranceProvider,
            insuranceNumber: insuranceNumber,
          )
          .timeout(const Duration(seconds: 30));
      currentUser.value = user;
      isSignedIn.value = true;
      _navigateByRole(user.role);
      return user;
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
      return null;
    } finally {
      isSigningUp.value = false;
      isLoading.value = false;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    if (email.trim().isEmpty) {
      errorMessage.value = 'Please enter your email address.';
      return;
    }
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await _authRepo.sendPasswordResetEmail(email.trim());
      Get.snackbar(
        'Email Sent',
        'Password reset instructions have been sent to $email',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    isLoading.value = true;
    try {
      await _authRepo.signOut();
      currentUser.value = null;
      isSignedIn.value = false;
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  void _navigateByRole(String role) {
    switch (role) {
      case 'super_admin':
      case 'hospital_admin':
        Get.offAllNamed(AppRoutes.adminDashboard);
        break;
      case 'gate_officer':
        Get.offAllNamed(AppRoutes.gateDashboard);
        break;
      case 'registration_officer':
        Get.offAllNamed(AppRoutes.registrationDashboard);
        break;
      case 'doctor':
        Get.offAllNamed(AppRoutes.doctorDashboard);
        break;
      case 'patient':
        Get.offAllNamed(AppRoutes.patientDashboard);
        break;
      case 'diagnostic_staff':
        Get.offAllNamed(AppRoutes.diagnosticDashboard);
        break;
      case 'account_officer':
        Get.offAllNamed(AppRoutes.accountDashboard);
        break;
      case 'pharmacist':
        Get.offAllNamed(AppRoutes.pharmacyDashboard);
        break;
      case 'admission_officer':
        Get.offAllNamed(AppRoutes.admissionDashboard);
        break;
      default:
        Get.offAllNamed(AppRoutes.login);
    }
  }

  void clearError() => errorMessage.value = '';

  UserModel? get user => currentUser.value;
  bool get isAdmin => user?.isAdmin ?? false;
  bool get isPatient => user?.isPatient ?? false;
  bool get isAccountOfficer => user?.isAccountOfficer ?? false;
  String get userName => user?.fullName ?? '';
  String get userRole => user?.role ?? '';
  String get userDeptId => user?.departmentId ?? '';
  String? get patientId => user?.patientId;
}
