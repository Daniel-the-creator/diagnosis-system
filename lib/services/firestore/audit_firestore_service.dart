import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firestore_constants.dart';
import '../../models/audit_log_model.dart';
import 'firestore_service.dart';

/// Firestore persistence service for immutable audit logging.
class AuditFirestoreService {
  AuditFirestoreService(this._fs);
  final FirestoreService _fs;

  static const String _col = FirestoreConstants.auditLogsCollection;

  String generateLogId() => _fs.generateId(_col);

  /// Records an audit log event in Firestore.
  Future<void> logAction({
    required String userId,
    required String userName,
    required String role,
    required String action,
    required String module,
    required String recordId,
    String? previousValue,
    String? newValue,
    String? details,
  }) async {
    try {
      final logId = generateLogId();
      final log = AuditLogModel(
        logId: logId,
        userId: userId,
        userName: userName,
        role: role,
        action: action,
        module: module,
        recordId: recordId,
        previousValue: previousValue,
        newValue: newValue,
        timestamp: DateTime.now(),
        details: details,
      );
      await _fs.setDoc(_col, logId, log.toFirestore());
    } catch (_) {
      // Audit log failures should not block primary operations, but will be recorded if possible.
    }
  }

  /// Streams audit logs with optional module filter and pagination limit.
  Stream<List<AuditLogModel>> streamAuditLogs({
    String? module,
    int limit = 100,
  }) {
    Query query = _fs.db.collection(_col).orderBy('timestamp', descending: true);
    if (module != null && module.isNotEmpty && module != 'ALL') {
      query = query.where('module', isEqualTo: module);
    }
    return query.limit(limit).snapshots().map((snap) =>
        snap.docs.map(AuditLogModel.fromFirestore).toList());
  }

  /// Fetches audit logs within a date range for export and analytics.
  Future<List<AuditLogModel>> getLogsForRange({
    required DateTime start,
    required DateTime end,
    String? module,
  }) async {
    Query query = _fs.db
        .collection(_col)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('timestamp', descending: true);

    if (module != null && module.isNotEmpty && module != 'ALL') {
      query = query.where('module', isEqualTo: module);
    }

    final snap = await query.get();
    return snap.docs.map(AuditLogModel.fromFirestore).toList();
  }
}
