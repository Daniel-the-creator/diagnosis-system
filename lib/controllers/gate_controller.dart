import 'package:get/get.dart';
import '../models/patient_model.dart';
import '../models/visit_model.dart';
import '../models/queue_item_model.dart';
import '../repositories/patient_repository.dart';
import '../repositories/visit_repository.dart';
import '../repositories/department_repository.dart';
import '../models/department_model.dart';
import '../core/errors/firebase_error_handler.dart';

/// Controller for the Gate Officer dashboard.
/// Handles: patient search/registration → visit creation → queue entry.
class GateController extends GetxController {
  GateController(
      this._patientRepo, this._visitRepo, this._deptRepo);
  final PatientRepository _patientRepo;
  final VisitRepository _visitRepo;
  final DepartmentRepository _deptRepo;

  final RxList<PatientModel> searchResults = <PatientModel>[].obs;
  final Rx<PatientModel?> selectedPatient = Rx<PatientModel?>(null);
  final Rx<VisitModel?> createdVisit = Rx<VisitModel?>(null);
  final Rx<QueueItemModel?> generatedQueueItem = Rx<QueueItemModel?>(null);
  final RxList<DepartmentModel> departments = <DepartmentModel>[].obs;

  final RxBool isSearching = false.obs;
  final RxBool isCreatingVisit = false.obs;
  final RxBool isSavingPatient = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString successMessage = ''.obs;
  final RxString selectedPatientType = 'REGULAR'.obs;

  String _registrationDeptCode = 'REG';
  String _registrationDeptName = 'Registration';

  @override
  void onInit() {
    super.onInit();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    try {
      final depts = await _deptRepo.getDepartments();
      departments.assignAll(depts);
      final regDept = depts.firstWhereOrNull((d) => d.code == 'REG');
      if (regDept != null) {
        _registrationDeptCode = regDept.code;
        _registrationDeptName = regDept.name;
      }
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
    }
  }

  Future<void> searchPatients(String query) async {
    if (query.trim().isEmpty) {
      searchResults.clear();
      return;
    }
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

  void selectPatient(PatientModel patient) {
    selectedPatient.value = patient;
    searchResults.clear();
    createdVisit.value = null;
    generatedQueueItem.value = null;
    errorMessage.value = '';
    successMessage.value = '';
  }

  Future<PatientModel?> registerNewPatient({
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
    String? insuranceProvider,
    String? insuranceNumber,
  }) async {
    isSavingPatient.value = true;
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
        insuranceProvider: insuranceProvider,
        insuranceNumber: insuranceNumber,
      );
      selectedPatient.value = patient;
      successMessage.value =
          'Patient registered successfully. Hospital No: ${patient.hospitalNumber}';
      return patient;
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
      return null;
    } finally {
      isSavingPatient.value = false;
    }
  }

  Future<bool> createVisit({
    required String staffId,
    String? patientType,
  }) async {
    final patient = selectedPatient.value;
    if (patient == null) {
      errorMessage.value = 'Please select or register a patient first.';
      return false;
    }
    isCreatingVisit.value = true;
    errorMessage.value = '';
    successMessage.value = '';
    try {
      final result = await _visitRepo.createVisitAndEnqueue(
        patientId: patient.patientId,
        patientType: patientType ?? selectedPatientType.value,
        createdByStaffId: staffId,
        registrationDeptCode: _registrationDeptCode,
        registrationDeptName: _registrationDeptName,
      );
      createdVisit.value = result.visit;
      generatedQueueItem.value = result.queueItem;
      successMessage.value =
          'Visit created! Queue number: ${result.queueItem.queueNumber}';
      return true;
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
      return false;
    } finally {
      isCreatingVisit.value = false;
    }
  }

  void setPatientType(String type) => selectedPatientType.value = type;

  void reset() {
    selectedPatient.value = null;
    createdVisit.value = null;
    generatedQueueItem.value = null;
    searchResults.clear();
    errorMessage.value = '';
    successMessage.value = '';
    selectedPatientType.value = 'REGULAR';
  }
}
