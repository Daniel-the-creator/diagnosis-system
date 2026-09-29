import 'package:uuid/uuid.dart';
import '../models/visit_model.dart';
import '../models/queue_item_model.dart';
import '../services/firestore/visit_firestore_service.dart';
import '../services/firestore/queue_firestore_service.dart';
import '../core/constants/app_constants.dart';
import '../core/errors/app_exception.dart';

/// Business logic for visits and the gate→registration→doctor workflow.
class VisitRepository {
  VisitRepository(this._visitService, this._queueService);
  final VisitFirestoreService _visitService;
  final QueueFirestoreService _queueService;
  final _uuid = const Uuid();

  /// Creates a new visit for a patient and enqueues them in Registration.
  Future<({VisitModel visit, QueueItemModel queueItem})> createVisitAndEnqueue({
    required String patientId,
    required String patientType,   // 'REGULAR' | 'EMERGENCY'
    required String createdByStaffId,
    required String registrationDeptCode,
    required String registrationDeptName,
  }) async {
    // Prevent duplicate active visit
    final existing =
        await _visitService.getTodaysVisitForPatient(patientId);
    if (existing != null) {
      throw DuplicateException(
        message:
            'This patient already has an active visit today (${existing.visitId}). '
            'Please search for the existing visit.',
      );
    }

    final priority = patientType == AppConstants.patientTypeEmergency
        ? Priority.emergency
        : Priority.regular;

    final now = DateTime.now();
    final visitId = _uuid.v4();
    final visit = VisitModel(
      visitId: visitId,
      patientId: patientId,
      visitDate: now,
      arrivalTime: now,
      patientType: patientType,
      priority: priority,
      currentDepartment: registrationDeptCode,
      currentStatus: AppConstants.visitStatusActive,
      completed: false,
      createdAt: now,
      updatedAt: now,
    );
    await _visitService.saveVisit(visit);

    // Generate queue number and enqueue into registration
    final queueNumber = await _queueService
        .generateQueueNumber(registrationDeptCode);
    final queueId = _uuid.v4();
    final queueItem = QueueItemModel(
      queueId: queueId,
      queueNumber: queueNumber,
      patientId: patientId,
      visitId: visitId,
      departmentId: registrationDeptCode,
      departmentName: registrationDeptName,
      priority: priority.toMap(),
      status: QueueStatus.waiting,
      createdAt: now,
      assignedStaffId: createdByStaffId,
    );
    await _queueService.saveQueueItem(queueItem);

    return (visit: visit, queueItem: queueItem);
  }

  /// Completes the registration step and sends patient to Doctor queue.
  Future<QueueItemModel> completeRegistrationAndEnqueueDoctor({
    required String visitId,
    required String patientId,
    required String registrationQueueId,
    required String staffId,
    required String doctorDeptCode,
    required String doctorDeptName,
    String? assignedDoctorId,
    String? assignedRoomId,
  }) async {
    // Complete registration queue item
    await _queueService.completeService(registrationQueueId);

    // Update visit to Doctor dept
    await _visitService.updateVisit(visitId, {
      'currentDepartment': doctorDeptCode,
      'assignedDoctorId': assignedDoctorId,
      'assignedRoomId': assignedRoomId,
    });

    // Fetch visit for priority info
    final visit = await _visitService.getVisitById(visitId);
    final priority = visit?.priority ?? Priority.regular;

    // Generate doctor queue number and enqueue
    final queueNumber =
        await _queueService.generateQueueNumber(doctorDeptCode);
    final queueId = _uuid.v4();
    final now = DateTime.now();
    final queueItem = QueueItemModel(
      queueId: queueId,
      queueNumber: queueNumber,
      patientId: patientId,
      visitId: visitId,
      departmentId: doctorDeptCode,
      departmentName: doctorDeptName,
      priority: priority.toMap(),
      status: QueueStatus.waiting,
      createdAt: now,
      assignedStaffId: staffId,
      assignedRoomId: assignedRoomId,
    );
    await _queueService.saveQueueItem(queueItem);
    return queueItem;
  }

  /// Completes the doctor consultation and marks the visit as done (Phase 1).
  Future<void> completeDoctorConsultation({
    required String visitId,
    required String doctorQueueId,
  }) async {
    await _queueService.completeService(doctorQueueId);
    await _visitService.updateVisit(visitId, {
      'currentStatus': AppConstants.visitStatusCompleted,
      'completed': true,
    });
  }

  // ── Delegates ──────────────────────────────────────────────────
  Future<VisitModel?> getVisitById(String visitId) =>
      _visitService.getVisitById(visitId);

  Future<VisitModel?> getTodaysVisitForPatient(String patientId) =>
      _visitService.getTodaysVisitForPatient(patientId);

  Future<void> saveVisit(VisitModel visit) =>
      _visitService.saveVisit(visit);

  Future<void> updateVisit(String visitId, Map<String, dynamic> data) =>
      _visitService.updateVisit(visitId, data);

  Stream<List<VisitModel>> streamTodaysVisits() =>
      _visitService.streamTodaysVisits();

  Stream<List<VisitModel>> streamPatientVisits(String patientId) =>
      _visitService.streamPatientVisits(patientId);
}
