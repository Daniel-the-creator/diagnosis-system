import 'package:get/get.dart';
import '../models/queue_item_model.dart';
import '../models/visit_model.dart';
import '../services/firestore/queue_firestore_service.dart';
import 'audit_repository.dart';

/// Business logic for queue management across all departments.
class QueueRepository {
  QueueRepository(this._queueService);
  final QueueFirestoreService _queueService;

  // ── Streams ────────────────────────────────────────────────────

  Stream<List<QueueItemModel>> streamActiveQueue(String departmentCode) =>
      _queueService.streamActiveQueue(departmentCode);

  Stream<List<QueueItemModel>> streamCompletedToday(String departmentCode) =>
      _queueService.streamCompletedToday(departmentCode);

  Stream<int> streamWaitingCount(String departmentCode) =>
      _queueService.streamWaitingCount(departmentCode);

  Stream<List<QueueItemModel>> streamQueueForVisit(String visitId) =>
      _queueService.streamVisitQueueItems(visitId);

  // ── Actions ────────────────────────────────────────────────────

  Future<QueueItemModel?> callNext(
      String departmentCode, String staffId) async {
    final active = await _getNextWaiting(departmentCode);
    if (active == null) return null;
    await _queueService.callPatient(active.queueId, staffId);
    return active;
  }

  Future<void> callPatient(String queueId, String staffId) =>
      _queueService.callPatient(queueId, staffId);

  Future<void> startService(String queueId) =>
      _queueService.startService(queueId);

  Future<void> completeService(String queueId) =>
      _queueService.completeService(queueId);

  Future<void> skipPatient(String queueId) =>
      _queueService.skipPatient(queueId);

  Future<void> markNoShow(String queueId) =>
      _queueService.markNoShow(queueId);

  Future<void> cancelQueueItem(String queueId) =>
      _queueService.cancelQueueItem(queueId);

  Future<void> recallPatient(String queueId, String staffId) =>
      _queueService.recallPatient(queueId, staffId);

  Future<QueueItemModel?> getCurrentlyServing(String departmentCode) =>
      _queueService.getCurrentlyServing(departmentCode);

  Future<void> saveQueueItem(QueueItemModel item) =>
      _queueService.saveQueueItem(item);

  Future<String> generateQueueNumber(String departmentCode) =>
      _queueService.generateQueueNumber(departmentCode);

  /// Allows authorized medical staff to dynamically alter a patient's queue priority,
  /// preserving FIFO within the new priority level and recording the change in audit logs.
  Future<void> updatePatientPriority({
    required String queueId,
    required String visitId,
    required Priority newPriority,
    required String staffId,
    required String staffName,
    required String staffRole,
    String? reason,
  }) async {
    final item = await _queueService.getQueueItemById(queueId);
    final previousLevel = item?.priorityLevel ?? 'REGULAR';

    await _queueService.updateQueueItem(queueId, {
      'priority': newPriority.toMap(),
    });

    if (visitId.isNotEmpty) {
      try {
        await _queueService.updateQueueItem(queueId, {'priority': newPriority.toMap()});
      } catch (_) {}
    }

    if (Get.isRegistered<AuditRepository>()) {
      try {
        await Get.find<AuditRepository>().log(
          userId: staffId,
          userName: staffName,
          role: staffRole,
          action: 'PRIORITY_CHANGED',
          module: 'QUEUE',
          recordId: queueId,
          previousValue: previousLevel,
          newValue: newPriority.level,
          details: reason ?? 'Priority changed from $previousLevel to ${newPriority.label}',
        );
      } catch (_) {}
    }
  }

  // ── Private helpers ────────────────────────────────────────────

  /// Gets the highest-priority WAITING item in the queue.
  Future<QueueItemModel?> _getNextWaiting(
      String departmentCode) async {
    // Stream gives us sorted list; take first WAITING
    final items = await _queueService
        .streamActiveQueue(departmentCode)
        .first;
    return items
        .where((i) => i.status == QueueStatus.waiting)
        .firstOrNull;
  }
}
