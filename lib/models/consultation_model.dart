import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a doctor consultation record for a patient visit.
/// Links to the visit, doctor, and may contain multiple diagnostic request IDs
/// and prescription IDs.
class ConsultationModel {
  final String consultationId;
  final String patientId;
  final String patientName;
  final String visitId;
  final String doctorId;
  final String doctorName;

  // ── Clinical Data ──────────────────────────────────────────────
  final String symptoms;
  final String observations;
  /// Vitals map: keys may include 'bloodPressure', 'pulse', 'temperature',
  /// 'weight', 'height', 'spo2', 'respiratoryRate'.
  final Map<String, dynamic> vitals;
  final String provisionalDiagnosis;
  final String? confirmedDiagnosis;
  final String notes;
  final String treatmentPlan;

  // ── Orders & Referrals ─────────────────────────────────────────
  final List<String> diagnosticRequestIds;
  final List<String> prescriptionIds;
  final bool admissionRequested;
  final bool dischargeRecommended;

  // ── Timestamps ─────────────────────────────────────────────────
  final DateTime createdAt;
  final DateTime? completedAt;

  ConsultationModel({
    required this.consultationId,
    required this.patientId,
    this.patientName = '',
    required this.visitId,
    required this.doctorId,
    required this.doctorName,
    this.symptoms = '',
    this.observations = '',
    this.vitals = const {},
    String provisionalDiagnosis = '',
    String? diagnosis,
    this.confirmedDiagnosis,
    String notes = '',
    String? clinicalNotes,
    this.treatmentPlan = '',
    this.diagnosticRequestIds = const [],
    this.prescriptionIds = const [],
    this.admissionRequested = false,
    this.dischargeRecommended = false,
    required this.createdAt,
    this.completedAt,
  })  : provisionalDiagnosis = (diagnosis != null && diagnosis.isNotEmpty)
            ? diagnosis
            : provisionalDiagnosis,
        notes = (clinicalNotes != null && clinicalNotes.isNotEmpty)
            ? clinicalNotes
            : notes;

  bool get isCompleted => completedAt != null;
  String get diagnosis => provisionalDiagnosis;
  String get clinicalNotes => notes;

  factory ConsultationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ConsultationModel(
      consultationId: data['consultationId'] as String? ?? doc.id,
      patientId: data['patientId'] as String? ?? '',
      patientName: data['patientName'] as String? ?? '',
      visitId: data['visitId'] as String? ?? '',
      doctorId: data['doctorId'] as String? ?? '',
      doctorName: data['doctorName'] as String? ?? '',
      symptoms: data['symptoms'] as String? ?? '',
      observations: data['observations'] as String? ?? '',
      vitals: Map<String, dynamic>.from(data['vitals'] as Map? ?? {}),
      provisionalDiagnosis: data['provisionalDiagnosis'] as String? ?? (data['diagnosis'] as String? ?? ''),
      confirmedDiagnosis: data['confirmedDiagnosis'] as String?,
      notes: data['notes'] as String? ?? (data['clinicalNotes'] as String? ?? ''),
      treatmentPlan: data['treatmentPlan'] as String? ?? '',
      diagnosticRequestIds:
          List<String>.from(data['diagnosticRequestIds'] as List? ?? []),
      prescriptionIds:
          List<String>.from(data['prescriptionIds'] as List? ?? []),
      admissionRequested: data['admissionRequested'] as bool? ?? false,
      dischargeRecommended: data['dischargeRecommended'] as bool? ?? false,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'consultationId': consultationId,
        'patientId': patientId,
        'patientName': patientName,
        'visitId': visitId,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'symptoms': symptoms,
        'observations': observations,
        'vitals': vitals,
        'provisionalDiagnosis': provisionalDiagnosis,
        'diagnosis': provisionalDiagnosis,
        'confirmedDiagnosis': confirmedDiagnosis,
        'notes': notes,
        'clinicalNotes': notes,
        'treatmentPlan': treatmentPlan,
        'diagnosticRequestIds': diagnosticRequestIds,
        'prescriptionIds': prescriptionIds,
        'admissionRequested': admissionRequested,
        'dischargeRecommended': dischargeRecommended,
        'createdAt': Timestamp.fromDate(createdAt),
        'completedAt':
            completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      };

  ConsultationModel copyWith({
    String? consultationId,
    String? patientId,
    String? patientName,
    String? visitId,
    String? doctorId,
    String? doctorName,
    String? symptoms,
    String? observations,
    Map<String, dynamic>? vitals,
    String? provisionalDiagnosis,
    String? confirmedDiagnosis,
    String? notes,
    String? treatmentPlan,
    List<String>? diagnosticRequestIds,
    List<String>? prescriptionIds,
    bool? admissionRequested,
    bool? dischargeRecommended,
    DateTime? createdAt,
    DateTime? completedAt,
  }) =>
      ConsultationModel(
        consultationId: consultationId ?? this.consultationId,
        patientId: patientId ?? this.patientId,
        patientName: patientName ?? this.patientName,
        visitId: visitId ?? this.visitId,
        doctorId: doctorId ?? this.doctorId,
        doctorName: doctorName ?? this.doctorName,
        symptoms: symptoms ?? this.symptoms,
        observations: observations ?? this.observations,
        vitals: vitals ?? this.vitals,
        provisionalDiagnosis:
            provisionalDiagnosis ?? this.provisionalDiagnosis,
        confirmedDiagnosis: confirmedDiagnosis ?? this.confirmedDiagnosis,
        notes: notes ?? this.notes,
        treatmentPlan: treatmentPlan ?? this.treatmentPlan,
        diagnosticRequestIds:
            diagnosticRequestIds ?? this.diagnosticRequestIds,
        prescriptionIds: prescriptionIds ?? this.prescriptionIds,
        admissionRequested: admissionRequested ?? this.admissionRequested,
        dischargeRecommended:
            dischargeRecommended ?? this.dischargeRecommended,
        createdAt: createdAt ?? this.createdAt,
        completedAt: completedAt ?? this.completedAt,
      );

  @override
  String toString() =>
      'ConsultationModel($consultationId, visit=$visitId, doctor=$doctorId)';
}
