import 'package:get/get.dart';
import '../models/visit_model.dart';
import '../models/queue_item_model.dart';
import '../repositories/visit_repository.dart';
import '../core/errors/firebase_error_handler.dart';

/// Manages visit creation and workflow progression.
class VisitController extends GetxController {
  VisitController(this._visitRepo);
  final VisitRepository _visitRepo;

  final Rx<VisitModel?> currentVisit = Rx<VisitModel?>(null);
  final Rx<QueueItemModel?> currentQueueItem = Rx<QueueItemModel?>(null);
  final RxList<VisitModel> todaysVisits = <VisitModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _visitRepo
        .streamTodaysVisits()
        .listen((visits) => todaysVisits.assignAll(visits));
  }

  /// Creates a visit and enqueues patient in Registration.
  Future<bool> createVisitAndEnqueue({
    required String patientId,
    required String patientType,
    required String staffId,
    required String registrationDeptCode,
    required String registrationDeptName,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final result = await _visitRepo.createVisitAndEnqueue(
        patientId: patientId,
        patientType: patientType,
        createdByStaffId: staffId,
        registrationDeptCode: registrationDeptCode,
        registrationDeptName: registrationDeptName,
      );
      currentVisit.value = result.visit;
      currentQueueItem.value = result.queueItem;
      return true;
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Registration officer completes registration and sends to Doctor.
  Future<bool> completeRegistration({
    required String visitId,
    required String patientId,
    required String registrationQueueId,
    required String staffId,
    required String doctorDeptCode,
    required String doctorDeptName,
    String? assignedDoctorId,
    String? assignedRoomId,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final queueItem = await _visitRepo.completeRegistrationAndEnqueueDoctor(
        visitId: visitId,
        patientId: patientId,
        registrationQueueId: registrationQueueId,
        staffId: staffId,
        doctorDeptCode: doctorDeptCode,
        doctorDeptName: doctorDeptName,
        assignedDoctorId: assignedDoctorId,
        assignedRoomId: assignedRoomId,
      );
      currentQueueItem.value = queueItem;
      return true;
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Doctor completes consultation.
  Future<bool> completeDoctorConsultation({
    required String visitId,
    required String doctorQueueId,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await _visitRepo.completeDoctorConsultation(
        visitId: visitId,
        doctorQueueId: doctorQueueId,
      );
      return true;
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadVisit(String visitId) async {
    isLoading.value = true;
    try {
      currentVisit.value = await _visitRepo.getVisitById(visitId);
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  void clearError() => errorMessage.value = '';
}
