import 'package:cloud_firestore/cloud_firestore.dart';

/// Discharge record created when a patient is formally discharged.
/// Discharge is only permitted when billing is cleared and all
/// clinical orders have been completed.
class DischargeModel {
  final String dischargeId;
  final String patientId;
  final String patientName;
  final String visitId;

  /// Null for out-patients who were not admitted.
  final String? admissionId;

  final String doctorId;
  final String doctorName;
  final String dischargeSummary;

  /// Medications to continue at home.
  final List<String> medications;

  final String followUpInstructions;
  final DateTime dischargedAt;
  final String dischargedBy;     // Staff uid
  final String dischargedByName; // Display name

  const DischargeModel({
    required this.dischargeId,
    required this.patientId,
    this.patientName = '',
    required this.visitId,
    this.admissionId,
    required this.doctorId,
    this.doctorName = '',
    this.dischargeSummary = '',
    this.medications = const [],
    this.followUpInstructions = '',
    required this.dischargedAt,
    required this.dischargedBy,
    this.dischargedByName = '',
  });

  factory DischargeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DischargeModel(
      dischargeId: data['dischargeId'] as String? ?? doc.id,
      patientId: data['patientId'] as String? ?? '',
      patientName: data['patientName'] as String? ?? '',
      visitId: data['visitId'] as String? ?? '',
      admissionId: data['admissionId'] as String?,
      doctorId: data['doctorId'] as String? ?? '',
      doctorName: data['doctorName'] as String? ?? '',
      dischargeSummary: data['dischargeSummary'] as String? ?? '',
      medications: List<String>.from(data['medications'] as List? ?? []),
      followUpInstructions: data['followUpInstructions'] as String? ?? '',
      dischargedAt:
          (data['dischargedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dischargedBy: data['dischargedBy'] as String? ?? '',
      dischargedByName: data['dischargedByName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'dischargeId': dischargeId,
        'patientId': patientId,
        'patientName': patientName,
        'visitId': visitId,
        'admissionId': admissionId,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'dischargeSummary': dischargeSummary,
        'medications': medications,
        'followUpInstructions': followUpInstructions,
        'dischargedAt': Timestamp.fromDate(dischargedAt),
        'dischargedBy': dischargedBy,
        'dischargedByName': dischargedByName,
      };

  @override
  String toString() =>
      'DischargeModel($dischargeId, patient=$patientId, visit=$visitId)';
}
