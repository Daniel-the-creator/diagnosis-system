import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a secure, immutable audit trail event across hospital operations.
class AuditLogModel {
  final String logId;
  final String userId;
  final String userName;
  final String role;
  final String action;
  final String module;
  final String recordId;
  final String? previousValue;
  final String? newValue;
  final DateTime timestamp;
  final String? details;

  const AuditLogModel({
    required this.logId,
    required this.userId,
    required this.userName,
    required this.role,
    required this.action,
    required this.module,
    required this.recordId,
    this.previousValue,
    this.newValue,
    required this.timestamp,
    this.details,
  });

  factory AuditLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AuditLogModel(
      logId: data['logId'] as String? ?? doc.id,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? 'System',
      role: data['role'] as String? ?? 'staff',
      action: data['action'] as String? ?? '',
      module: data['module'] as String? ?? 'SYSTEM',
      recordId: data['recordId'] as String? ?? '',
      previousValue: data['previousValue'] as String?,
      newValue: data['newValue'] as String?,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      details: data['details'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'logId': logId,
        'userId': userId,
        'userName': userName,
        'role': role,
        'action': action,
        'module': module,
        'recordId': recordId,
        'previousValue': previousValue,
        'newValue': newValue,
        'timestamp': Timestamp.fromDate(timestamp),
        'details': details,
      };

  @override
  String toString() =>
      'AuditLog($action by $userName ($role) on $module: $recordId)';
}
