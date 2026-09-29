import 'package:get/get.dart';
import '../models/patient_model.dart';
import '../models/queue_item_model.dart';
import '../repositories/patient_repository.dart';
import '../repositories/queue_repository.dart';
import '../repositories/visit_repository.dart';
import '../repositories/department_repository.dart';
import '../core/errors/firebase_error_handler.dart';

/// Controller for the Registration Officer dashboard.
class RegistrationController extends GetxController {
  RegistrationController(
    this._patientRepo,
    this._queueRepo,
    this._visitRepo,
    this._deptRepo,
  );
  final PatientRepository _patientRepo;
  final QueueRepository _queueRepo;
  final VisitRepository _visitRepo;
  final DepartmentRepository _deptRepo;

  final RxList<QueueItemModel> regQueue = <QueueItemModel>[].obs;
  final Rx<QueueItemModel?> currentlyServing = Rx<QueueItemModel?>(null);
  final Rx<PatientModel?> currentPatient = Rx<PatientModel?>(null);

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxString errorMessage = ''.obs;

  String _doctorDeptCode = 'DOC';
  String _doctorDeptName = 'General Medicine';

  static const String _regCode = 'REG';

  @override
  void onInit() {
    super.onInit();
    _loadDoctorDept();
    _queueRepo.streamActiveQueue(_regCode).listen((items) {
      regQueue.assignAll(items);
      currentlyServing.value =
          items.where((i) => i.status == QueueStatus.inProgress).firstOrNull;
    });
  }

  Future<void> _loadDoctorDept() async {
    try {
      // Use 'GEN' as the default doctor department
      final dept = await _deptRepo.getDepartmentByCode('GEN');
      if (dept != null) {
        _doctorDeptCode = dept.code;
        _doctorDeptName = dept.name;
      }
    } catch (_) {}
  }

  Future<void> callPatient(String queueId, String staffId) async {
    isLoading.value = true;
    try {
      await _queueRepo.callPatient(queueId, staffId);
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> startService(String queueId) async {
    isLoading.value = true;
    try {
      await _queueRepo.startService(queueId);
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadCurrentPatient(String patientId) async {
    isLoading.value = true;
    try {
      currentPatient.value = await _patientRepo.getPatientById(patientId);
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updatePatientInfo(
      String patientId, Map<String, dynamic> data) async {
    isSaving.value = true;
    errorMessage.value = '';
    try {
      await _patientRepo.updatePatient(patientId, data);
      currentPatient.value = await _patientRepo.getPatientById(patientId);
      return true;
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// Completes registration and advances patient to Doctor queue.
  Future<bool> completeRegistration({
    required QueueItemModel queueItem,
    required String staffId,
    String? doctorDeptCode,
  }) async {
    isSaving.value = true;
    errorMessage.value = '';
    try {
      await _visitRepo.completeRegistrationAndEnqueueDoctor(
        visitId: queueItem.visitId,
        patientId: queueItem.patientId,
        registrationQueueId: queueItem.queueId,
        staffId: staffId,
        doctorDeptCode: doctorDeptCode ?? _doctorDeptCode,
        doctorDeptName: _doctorDeptName,
      );
      currentlyServing.value = null;
      currentPatient.value = null;
      return true;
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> callNextPatient(String staffId) async {
    isLoading.value = true;
    try {
      QueueItemModel? itemToCall;
      if (waitingItems.isNotEmpty) {
        itemToCall = waitingItems.first;
        await _queueRepo.callPatient(itemToCall.queueId, staffId);
      } else {
        itemToCall = await _queueRepo.callNext(_regCode, staffId);
      }

      if (itemToCall != null) {
        Get.snackbar(
          'Patient Called',
          'Called patient ${itemToCall.queueNumber}',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Queue Empty',
          'No patients are currently waiting in the registration queue.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
      Get.snackbar(
        'Error',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> skipPatient(String queueId) async {
    try {
      await _queueRepo.skipPatient(queueId);
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
    }
  }

  Future<void> markNoShow(String queueId) async {
    try {
      await _queueRepo.markNoShow(queueId);
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
    }
  }

  List<QueueItemModel> get waitingItems =>
      regQueue.where((i) => i.status == QueueStatus.waiting).toList();

  void clearError() => errorMessage.value = '';
}
