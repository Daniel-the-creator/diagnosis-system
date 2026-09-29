import 'package:get/get.dart';
import '../models/patient_model.dart';
import '../repositories/patient_repository.dart';
import '../core/errors/firebase_error_handler.dart';

/// Manages patient search, profile, and registration state.
class PatientController extends GetxController {
  PatientController(this._patientRepo);
  final PatientRepository _patientRepo;

  final RxList<PatientModel> searchResults = <PatientModel>[].obs;
  final Rx<PatientModel?> selectedPatient = Rx<PatientModel?>(null);
  final RxList<PatientModel> recentPatients = <PatientModel>[].obs;

  final RxBool isSearching = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadRecentPatients();
  }

  Future<void> searchPatients(String query) async {
    if (query.trim().isEmpty) {
      searchResults.clear();
      return;
    }
    searchQuery.value = query;
    isSearching.value = true;
    errorMessage.value = '';
    try {
      final results = await _patientRepo.searchPatients(query.trim());
      searchResults.assignAll(results);
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
    } finally {
      isSearching.value = false;
    }
  }

  Future<void> selectPatient(PatientModel patient) async {
    selectedPatient.value = patient;
  }

  Future<void> loadPatientById(String patientId) async {
    isLoading.value = true;
    try {
      selectedPatient.value =
          await _patientRepo.getPatientById(patientId);
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<PatientModel?> registerPatient({
    required String fullName,
    required String gender,
    required String phone,
    DateTime? dateOfBirth,
    String? email,
    String? address,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? bloodGroup,
    String? genotype,
    List<String>? allergies,
    String? medicalHistory,
    String? insuranceProvider,
    String? insuranceNumber,
  }) async {
    isSaving.value = true;
    errorMessage.value = '';
    try {
      final patient = await _patientRepo.registerPatient(
        fullName: fullName,
        gender: gender,
        phone: phone,
        dateOfBirth: dateOfBirth,
        email: email,
        address: address,
        emergencyContactName: emergencyContactName,
        emergencyContactPhone: emergencyContactPhone,
        bloodGroup: bloodGroup,
        genotype: genotype,
        allergies: allergies,
        medicalHistory: medicalHistory,
        insuranceProvider: insuranceProvider,
        insuranceNumber: insuranceNumber,
      );
      selectedPatient.value = patient;
      return patient;
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
      return null;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> updatePatient(
      String patientId, Map<String, dynamic> data) async {
    isSaving.value = true;
    errorMessage.value = '';
    try {
      await _patientRepo.updatePatient(patientId, data);
      // Refresh selected patient
      selectedPatient.value =
          await _patientRepo.getPatientById(patientId);
      return true;
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> loadRecentPatients() async {
    try {
      final patients = await _patientRepo.getRecentPatients();
      recentPatients.assignAll(patients);
    } catch (_) {
      // Non-critical; fail silently
    }
  }

  void clearSearch() {
    searchResults.clear();
    searchQuery.value = '';
  }

  void clearSelectedPatient() => selectedPatient.value = null;
  void clearError() => errorMessage.value = '';
}
