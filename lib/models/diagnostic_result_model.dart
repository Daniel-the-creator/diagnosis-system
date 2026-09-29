import 'package:cloud_firestore/cloud_firestore.dart';

/// The results/report for a single diagnostic test request.
/// Patients can only see results where isReleasedToPatient == true.
class DiagnosticResultModel {
  final String resultId;
  final String diagnosticRequestId;
  final String patientId;
  final String patientName;
  final String visitId;
  final String testName;
  final String diagnosticType;
  final String performedBy;     // Staff uid
  final String performedByName; // Display name

  // ── Result Content ─────────────────────────────────────────────
  final String findings;
  final String interpretation;
  final String notes;

  /// List of Storage download URLs for attached files/images.
  final List<String> attachments;

  /// Controls patient portal visibility. Only when true can the patient see this result.
  final bool isReleasedToPatient;

  final DateTime createdAt;
  final DateTime? completedAt;

  const DiagnosticResultModel({
    required this.resultId,
    required this.diagnosticRequestId,
    required this.patientId,
    this.patientName = '',
    required this.visitId,
    this.testName = '',
    this.diagnosticType = 'LAB',
    required this.performedBy,
    this.performedByName = '',
    this.findings = '',
    this.interpretation = '',
    this.notes = '',
    this.attachments = const [],
    this.isReleasedToPatient = false,
    required this.createdAt,
    this.completedAt,
  });

  factory DiagnosticResultModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DiagnosticResultModel(
      resultId: data['resultId'] as String? ?? doc.id,
      diagnosticRequestId: data['diagnosticRequestId'] as String? ?? '',
      patientId: data['patientId'] as String? ?? '',
      patientName: data['patientName'] as String? ?? '',
      visitId: data['visitId'] as String? ?? '',
      testName: data['testName'] as String? ?? '',
      diagnosticType: data['diagnosticType'] as String? ?? 'LAB',
      performedBy: data['performedBy'] as String? ?? '',
      performedByName: data['performedByName'] as String? ?? '',
      findings: data['findings'] as String? ?? '',
      interpretation: data['interpretation'] as String? ?? '',
      notes: data['notes'] as String? ?? '',
      attachments: List<String>.from(data['attachments'] as List? ?? []),
      isReleasedToPatient: data['isReleasedToPatient'] as bool? ?? false,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'resultId': resultId,
        'diagnosticRequestId': diagnosticRequestId,
        'patientId': patientId,
        'patientName': patientName,
        'visitId': visitId,
        'testName': testName,
        'diagnosticType': diagnosticType,
        'performedBy': performedBy,
        'performedByName': performedByName,
        'findings': findings,
        'interpretation': interpretation,
        'notes': notes,
        'attachments': attachments,
        'isReleasedToPatient': isReleasedToPatient,
        'createdAt': Timestamp.fromDate(createdAt),
        'completedAt':
            completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      };

  DiagnosticResultModel copyWith({
    String? resultId,
    String? diagnosticRequestId,
    String? patientId,
    String? patientName,
    String? visitId,
    String? testName,
    String? diagnosticType,
    String? performedBy,
    String? performedByName,
    String? findings,
    String? interpretation,
    String? notes,
    List<String>? attachments,
    bool? isReleasedToPatient,
    DateTime? createdAt,
    DateTime? completedAt,
  }) =>
      DiagnosticResultModel(
        resultId: resultId ?? this.resultId,
        diagnosticRequestId:
            diagnosticRequestId ?? this.diagnosticRequestId,
        patientId: patientId ?? this.patientId,
        patientName: patientName ?? this.patientName,
        visitId: visitId ?? this.visitId,
        testName: testName ?? this.testName,
        diagnosticType: diagnosticType ?? this.diagnosticType,
        performedBy: performedBy ?? this.performedBy,
        performedByName: performedByName ?? this.performedByName,
        findings: findings ?? this.findings,
        interpretation: interpretation ?? this.interpretation,
        notes: notes ?? this.notes,
        attachments: attachments ?? this.attachments,
        isReleasedToPatient: isReleasedToPatient ?? this.isReleasedToPatient,
        createdAt: createdAt ?? this.createdAt,
        completedAt: completedAt ?? this.completedAt,
      );

  @override
  String toString() =>
      'DiagnosticResultModel($resultId, request=$diagnosticRequestId, released=$isReleasedToPatient)';
}
