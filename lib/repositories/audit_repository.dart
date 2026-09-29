import '../models/audit_log_model.dart';
import '../services/firestore/audit_firestore_service.dart';

/// Repository for creating and reading hospital audit events.
class AuditRepository {
  AuditRepository(this._service);
  final AuditFirestoreService _service;

  Future<void> log({
    required String userId,
    required String userName,
    required String role,
    required String action,
    required String module,
    required String recordId,
    String? previousValue,
    String? newValue,
    String? details,
  }) =>
      _service.logAction(
        userId: userId,
        userName: userName,
        role: role,
        action: action,
        module: module,
        recordId: recordId,
        previousValue: previousValue,
        newValue: newValue,
        details: details,
      );

  Stream<List<AuditLogModel>> streamLogs({String? module, int limit = 100}) =>
      _service.streamAuditLogs(module: module, limit: limit);

  Future<List<AuditLogModel>> getLogsForRange({
    required DateTime start,
    required DateTime end,
    String? module,
  }) =>
      _service.getLogsForRange(start: start, end: end, module: module);
}
