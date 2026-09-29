import 'package:cloud_firestore/cloud_firestore.dart';

/// A single diagnostic test request raised by a doctor during a consultation.
/// Multiple DiagnosticRequestModels can exist per visit for different test types.
///
/// Status flow:
///   REQUESTED -> AWAITING_PAYMENT -> PAID -> WAITING -> IN_PROGRESS -> COMPLETED
///   Any state -> CANCELLED
class DiagnosticRequestModel {
  final String diagnosticRequestId;
  final String patientId;
  final String patientName;
  final String visitId;
  final String consultationId;
  final String doctorId;
  final String doctorName;

  /// 'LAB' | 'XR' | 'SCAN'
  final String diagnosticType;
  final String testName;
  final String priority; // 'ROUTINE' | 'URGENT' | 'STAT'
  final String instructions;

  /// REQUESTED | AWAITING_PAYMENT | PAID | WAITING | IN_PROGRESS | COMPLETED | CANCELLED
  final String status;

  /// Set when the diagnostic queue item is created (the queue_items document id).
  final String? queueId;
  final String? queueNumber;

  final DateTime requestedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  const DiagnosticRequestModel({
    required this.diagnosticRequestId,
    required this.patientId,
    this.patientName = '',
    required this.visitId,
    required this.consultationId,
    required this.doctorId,
    required this.doctorName,
    required this.diagnosticType,
    required this.testName,
    this.priority = 'ROUTINE',
    this.instructions = '',
    this.status = 'REQUESTED',
    this.queueId,
    this.queueNumber,
    required this.requestedAt,
    this.startedAt,
    this.completedAt,
  });

  bool get isCompleted => status == 'COMPLETED';
  bool get isCancelled => status == 'CANCELLED';
  bool get isPending => !isCompleted && !isCancelled;

  String get diagnosticTypeLabel {
    switch (diagnosticType) {
      case 'LAB':
        return 'Laboratory';
      case 'XR':
        return 'X-Ray';
      case 'SCAN':
        return 'Scan';
      default:
        return diagnosticType;
    }
  }

  factory DiagnosticRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DiagnosticRequestModel(
      diagnosticRequestId:
          data['diagnosticRequestId'] as String? ?? doc.id,
      patientId: data['patientId'] as String? ?? '',
      patientName: data['patientName'] as String? ?? '',
      visitId: data['visitId'] as String? ?? '',
      consultationId: data['consultationId'] as String? ?? '',
      doctorId: data['doctorId'] as String? ?? '',
      doctorName: data['doctorName'] as String? ?? '',
      diagnosticType: data['diagnosticType'] as String? ?? 'LAB',
      testName: data['testName'] as String? ?? '',
      priority: data['priority'] as String? ?? 'ROUTINE',
      instructions: data['instructions'] as String? ?? '',
      status: data['status'] as String? ?? 'REQUESTED',
      queueId: data['queueId'] as String?,
      queueNumber: data['queueNumber'] as String?,
      requestedAt:
          (data['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'diagnosticRequestId': diagnosticRequestId,
        'patientId': patientId,
        'patientName': patientName,
        'visitId': visitId,
        'consultationId': consultationId,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'diagnosticType': diagnosticType,
        'testName': testName,
        'priority': priority,
        'instructions': instructions,
        'status': status,
        'queueId': queueId,
        'queueNumber': queueNumber,
        'requestedAt': Timestamp.fromDate(requestedAt),
        'startedAt':
            startedAt != null ? Timestamp.fromDate(startedAt!) : null,
        'completedAt':
            completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      };

  DiagnosticRequestModel copyWith({
    String? diagnosticRequestId,
    String? patientId,
    String? patientName,
    String? visitId,
    String? consultationId,
    String? doctorId,
    String? doctorName,
    String? diagnosticType,
    String? testName,
    String? priority,
    String? instructions,
    String? status,
    String? queueId,
    String? queueNumber,
    DateTime? requestedAt,
    DateTime? startedAt,
    DateTime? completedAt,
  }) =>
      DiagnosticRequestModel(
        diagnosticRequestId:
            diagnosticRequestId ?? this.diagnosticRequestId,
        patientId: patientId ?? this.patientId,
        patientName: patientName ?? this.patientName,
        visitId: visitId ?? this.visitId,
        consultationId: consultationId ?? this.consultationId,
        doctorId: doctorId ?? this.doctorId,
        doctorName: doctorName ?? this.doctorName,
        diagnosticType: diagnosticType ?? this.diagnosticType,
        testName: testName ?? this.testName,
        priority: priority ?? this.priority,
        instructions: instructions ?? this.instructions,
        status: status ?? this.status,
        queueId: queueId ?? this.queueId,
        queueNumber: queueNumber ?? this.queueNumber,
        requestedAt: requestedAt ?? this.requestedAt,
        startedAt: startedAt ?? this.startedAt,
        completedAt: completedAt ?? this.completedAt,
      );

  @override
  String toString() =>
      'DiagnosticRequestModel($diagnosticRequestId, $diagnosticType - $testName, $status)';
}
