import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firestore_constants.dart';
import '../../core/utils/queue_number_generator.dart';
import '../../models/queue_item_model.dart';
import 'firestore_service.dart';

/// Firestore operations for queue_items and queue_counters collections.
class QueueFirestoreService {
  QueueFirestoreService(this._fs);
  final FirestoreService _fs;

  static const String _col = FirestoreConstants.queueItemsCollection;
  static const String _countersCol = FirestoreConstants.queueCountersCollection;

  String generateId() => _fs.generateId(_col);

  // ── Queue Number Generation (Atomic via Transaction) ───────────

  /// Atomically increments the daily counter for a department and returns
  /// the formatted queue number (e.g. 'REG-003').
  Future<String> generateQueueNumber(String departmentCode) async {
    final counterId = QueueNumberGenerator.counterId(departmentCode);
    final prefix = QueueNumberGenerator.getPrefix(departmentCode);
    final counterRef = _fs.db.collection(_countersCol).doc(counterId);

    return await _fs.runTransaction<String>((txn) async {
      final snap = await txn.get(counterRef);
      int next;
      if (!snap.exists) {
        next = 1;
        txn.set(counterRef, {
          'departmentId': departmentCode,
          'prefix': prefix,
          'date': QueueNumberGenerator.todayDate(),
          'counter': 1,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        next = ((snap.data()!['counter'] as int?) ?? 0) + 1;
        txn.update(counterRef, {'counter': next});
      }
      return QueueNumberGenerator.format(prefix, next);
    });
  }

  // ── CRUD ───────────────────────────────────────────────────────

  Future<void> saveQueueItem(QueueItemModel item) =>
      _fs.setDoc(_col, item.queueId, item.toFirestore());

  Future<QueueItemModel?> getQueueItemById(String queueId) async {
    final doc = await _fs.getDoc(_col, queueId);
    if (!doc.exists) return null;
    return QueueItemModel.fromFirestore(doc);
  }

  Future<void> updateQueueItem(
      String queueId, Map<String, dynamic> data) =>
      _fs.updateDoc(_col, queueId, data);

  // ── Queue Queries ──────────────────────────────────────────────

  /// Stream all items for a department (or all departments if 'ALL') with WAITING/CALLED/IN_PROGRESS status,
  /// ordered by priority (desc weight) then createdAt (asc).
  Stream<List<QueueItemModel>> streamActiveQueue(String departmentCode) {
    Query query = _fs.db.collection(_col);
    if (departmentCode.isNotEmpty && departmentCode != 'ALL') {
      query = query.where('departmentId', isEqualTo: departmentCode);
    }
    return query
        .where('status', whereIn: ['WAITING', 'CALLED', 'IN_PROGRESS'])
        .orderBy('createdAt')
        .snapshots()
        .map((snap) {
          final items =
              snap.docs.map(QueueItemModel.fromFirestore).toList();
          // Client-side sort: higher priority weight first, then FIFO
          items.sort((a, b) {
            final pw = b.priorityWeight.compareTo(a.priorityWeight);
            if (pw != 0) return pw;
            return a.createdAt.compareTo(b.createdAt);
          });
          return items;
        });
  }

  /// Stream today's completed items for a department (or all departments if 'ALL').
  Stream<List<QueueItemModel>> streamCompletedToday(String departmentCode) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    Query query = _fs.db.collection(_col);
    if (departmentCode.isNotEmpty && departmentCode != 'ALL') {
      query = query.where('departmentId', isEqualTo: departmentCode);
    }
    return query
        .where('status', isEqualTo: 'COMPLETED')
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map(QueueItemModel.fromFirestore).toList());
  }

  /// Stream all queue items for a specific visit.
  Stream<List<QueueItemModel>> streamVisitQueueItems(String visitId) =>
      _fs.db
          .collection(_col)
          .where('visitId', isEqualTo: visitId)
          .orderBy('createdAt')
          .snapshots()
          .map((snap) =>
              snap.docs.map(QueueItemModel.fromFirestore).toList());

  /// Get the current IN_PROGRESS item for a department (at most 1).
  Future<QueueItemModel?> getCurrentlyServing(
      String departmentCode) async {
    final snap = await _fs.db
        .collection(_col)
        .where('departmentId', isEqualTo: departmentCode)
        .where('status', isEqualTo: 'IN_PROGRESS')
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return QueueItemModel.fromFirestore(snap.docs.first);
  }

  // ── Status Transitions ─────────────────────────────────────────

  Future<void> callPatient(String queueId, String staffId) =>
      updateQueueItem(queueId, {
        'status': 'CALLED',
        'calledAt': FieldValue.serverTimestamp(),
        'assignedStaffId': staffId,
      });

  Future<void> startService(String queueId) =>
      updateQueueItem(queueId, {
        'status': 'IN_PROGRESS',
        'serviceStartedAt': FieldValue.serverTimestamp(),
      });

  Future<void> completeService(String queueId) =>
      updateQueueItem(queueId, {
        'status': 'COMPLETED',
        'completedAt': FieldValue.serverTimestamp(),
      });

  Future<void> skipPatient(String queueId) =>
      updateQueueItem(queueId, {'status': 'SKIPPED'});

  Future<void> markNoShow(String queueId) =>
      updateQueueItem(queueId, {'status': 'NO_SHOW'});

  Future<void> cancelQueueItem(String queueId) =>
      updateQueueItem(queueId, {'status': 'CANCELLED'});

  Future<void> recallPatient(String queueId, String staffId) =>
      updateQueueItem(queueId, {
        'status': 'CALLED',
        'calledAt': FieldValue.serverTimestamp(),
        'assignedStaffId': staffId,
      });

  // ── Counts ─────────────────────────────────────────────────────

  Future<int> countWaiting(String departmentCode) async {
    final snap = await _fs.db
        .collection(_col)
        .where('departmentId', isEqualTo: departmentCode)
        .where('status', isEqualTo: 'WAITING')
        .count()
        .get();
    return snap.count ?? 0;
  }

  Stream<int> streamWaitingCount(String departmentCode) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    return _fs.db
        .collection(_col)
        .where('departmentId', isEqualTo: departmentCode)
        .where('status', isEqualTo: 'WAITING')
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .snapshots()
        .map((snap) => snap.docs.length);
  }
}
