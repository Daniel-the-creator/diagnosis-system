import 'dart:async';
import 'package:get/get.dart';
import '../models/diagnostic_request_model.dart';
import '../models/diagnostic_result_model.dart';
import '../repositories/diagnostic_repository.dart';
import '../repositories/visit_repository.dart';
import '../repositories/notification_repository.dart';
import '../core/errors/firebase_error_handler.dart';

/// Controller for the Diagnostic Staff dashboard (Laboratory, X-Ray, Ultrasound/Scan).
class DiagnosticController extends GetxController {
  DiagnosticController(
    this._diagnosticRepo,
    this._visitRepo, {
    NotificationRepository? notificationRepo,
  }) : _notificationRepo = notificationRepo ??
            (Get.isRegistered<NotificationRepository>()
                ? Get.find<NotificationRepository>()
                : null);

  final DiagnosticRepository _diagnosticRepo;
  final VisitRepository _visitRepo;
  final NotificationRepository? _notificationRepo;

  final RxString selectedType = 'ALL'.obs; // 'ALL' | 'LAB' | 'XR' | 'SCAN'
  final RxList<DiagnosticRequestModel> activeRequests = <DiagnosticRequestModel>[].obs;
  final Rx<DiagnosticRequestModel?> currentRequest = Rx<DiagnosticRequestModel?>(null);

  // Result entry form state
  final RxString findings = ''.obs;
  final RxString interpretation = ''.obs;
  final RxString notes = ''.obs;
  final RxList<String> attachments = <String>[].obs;
  final RxBool releaseToPatient = true.obs;

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  StreamSubscription? _reqSub;

  @override
  void onInit() {
    super.onInit();
    _setupStream();
  }

  @override
  void onClose() {
    _reqSub?.cancel();
    super.onClose();
  }

  void setDiagnosticType(String type) {
    selectedType.value = type;
    _setupStream();
  }

  void _setupStream() {
    _reqSub?.cancel();
    _reqSub = _diagnosticRepo.streamActiveRequestsByType(selectedType.value).listen((reqs) {
      activeRequests.assignAll(reqs);
    });
  }

  void startProcessing(DiagnosticRequestModel req) {
    currentRequest.value = req;
    findings.value = '';
    interpretation.value = '';
    notes.value = '';
    attachments.clear();
    releaseToPatient.value = true;

    _diagnosticRepo.updateRequest(req.diagnosticRequestId, {
      'status': 'IN_PROGRESS',
      'startedAt': DateTime.now(),
    });
  }

  void addAttachment(String url) {
    if (url.trim().isNotEmpty) {
      attachments.add(url.trim());
    }
  }

  void removeAttachment(int index) {
    if (index >= 0 && index < attachments.length) {
      attachments.removeAt(index);
    }
  }

  Future<bool> submitResult({
    required String staffId,
    required String staffName,
  }) async {
    final req = currentRequest.value;
    if (req == null) return false;

    if (findings.value.trim().isEmpty) {
      errorMessage.value = 'Please enter test findings before submitting.';
      return false;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final resultId = _diagnosticRepo.generateResultId();
      final result = DiagnosticResultModel(
        resultId: resultId,
        diagnosticRequestId: req.diagnosticRequestId,
        patientId: req.patientId,
        patientName: req.patientName,
        visitId: req.visitId,
        testName: req.testName,
        diagnosticType: req.diagnosticType,
        performedBy: staffId,
        performedByName: staffName,
        findings: findings.value.trim(),
        interpretation: interpretation.value.trim(),
        notes: notes.value.trim(),
        attachments: List<String>.from(attachments),
        isReleasedToPatient: releaseToPatient.value,
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
      );

      await _diagnosticRepo.completeRequestWithResult(
        result: result,
        requestId: req.diagnosticRequestId,
      );

      // Update visit careStage to AWAITING_REVIEW for doctor follow-up
      await _visitRepo.updateVisit(req.visitId, {
        'careStage': 'AWAITING_REVIEW',
        'status': 'AWAITING_REVIEW',
      });

      // Send notifications
      if (_notificationRepo != null) {
        if (releaseToPatient.value && req.patientId.isNotEmpty) {
          await _notificationRepo!.notify(
            recipientId: req.patientId,
            recipientType: 'patient',
            title: 'Diagnostic Results Ready',
            body: 'Your test results for "${req.testName}" are now available in your portal.',
            type: 'RESULT_READY',
            relatedId: resultId,
          );
        }
        if (req.doctorId.isNotEmpty) {
          await _notificationRepo!.notify(
            recipientId: req.doctorId,
            recipientType: 'staff',
            title: 'Test Results Available',
            body: 'Results for ${req.patientName} (${req.testName}) are ready for review.',
            type: 'RESULT_READY',
            relatedId: req.visitId,
          );
        }
      }

      currentRequest.value = null;
      Get.snackbar(
        'Result Submitted',
        '${req.testName} results recorded successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void clearCurrent() {
    currentRequest.value = null;
  }
}
