import 'package:cloud_firestore/cloud_firestore.dart';

/// A doctor prescription for medication, written during a consultation.
/// Status flow: PENDING -> PARTIALLY_DISPENSED -> DISPENSED
///              Any -> CANCELLED
class PrescriptionModel {
  final String prescriptionId;
  final String patientId;
  final String patientName;
  final String visitId;
  final String consultationId;
  final String doctorId;
  final String doctorName;

  // ── Medication Details ─────────────────────────────────────────
  final String medicationName;
  final String dosage;       // e.g. '500mg'
  final String frequency;    // e.g. 'Twice daily'
  final String duration;     // e.g. '7 days'
  final int quantity;        // Total units to dispense
  final String instructions; // Special instructions

  // ── Status & Dispensing ────────────────────────────────────────
  /// PENDING | PARTIALLY_DISPENSED | DISPENSED | CANCELLED
  final String status;
  final int dispensedQuantity;
  final String? dispensedBy;
  final String? dispensedByName;
  final DateTime? dispensedAt;

  final DateTime createdAt;

  const PrescriptionModel({
    required this.prescriptionId,
    required this.patientId,
    this.patientName = '',
    required this.visitId,
    required this.consultationId,
    required this.doctorId,
    required this.doctorName,
    required this.medicationName,
    this.dosage = '',
    this.frequency = '',
    this.duration = '',
    required this.quantity,
    this.instructions = '',
    this.status = 'PENDING',
    this.dispensedQuantity = 0,
    this.dispensedBy,
    this.dispensedByName,
    this.dispensedAt,
    required this.createdAt,
  });

  bool get isDispensed => status == 'DISPENSED';
  bool get isCancelled => status == 'CANCELLED';
  int get remaining => quantity - dispensedQuantity;

  factory PrescriptionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PrescriptionModel(
      prescriptionId: data['prescriptionId'] as String? ?? doc.id,
      patientId: data['patientId'] as String? ?? '',
      patientName: data['patientName'] as String? ?? '',
      visitId: data['visitId'] as String? ?? '',
      consultationId: data['consultationId'] as String? ?? '',
      doctorId: data['doctorId'] as String? ?? '',
      doctorName: data['doctorName'] as String? ?? '',
      medicationName: data['medicationName'] as String? ?? '',
      dosage: data['dosage'] as String? ?? '',
      frequency: data['frequency'] as String? ?? '',
      duration: data['duration'] as String? ?? '',
      quantity: data['quantity'] as int? ?? 0,
      instructions: data['instructions'] as String? ?? '',
      status: data['status'] as String? ?? 'PENDING',
      dispensedQuantity: data['dispensedQuantity'] as int? ?? 0,
      dispensedBy: data['dispensedBy'] as String?,
      dispensedByName: data['dispensedByName'] as String?,
      dispensedAt: (data['dispensedAt'] as Timestamp?)?.toDate(),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'prescriptionId': prescriptionId,
        'patientId': patientId,
        'patientName': patientName,
        'visitId': visitId,
        'consultationId': consultationId,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'medicationName': medicationName,
        'dosage': dosage,
        'frequency': frequency,
        'duration': duration,
        'quantity': quantity,
        'instructions': instructions,
        'status': status,
        'dispensedQuantity': dispensedQuantity,
        'dispensedBy': dispensedBy,
        'dispensedByName': dispensedByName,
        'dispensedAt':
            dispensedAt != null ? Timestamp.fromDate(dispensedAt!) : null,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  PrescriptionModel copyWith({
    String? prescriptionId,
    String? patientId,
    String? patientName,
    String? visitId,
    String? consultationId,
    String? doctorId,
    String? doctorName,
    String? medicationName,
    String? dosage,
    String? frequency,
    String? duration,
    int? quantity,
    String? instructions,
    String? status,
    int? dispensedQuantity,
    String? dispensedBy,
    String? dispensedByName,
    DateTime? dispensedAt,
    DateTime? createdAt,
  }) =>
      PrescriptionModel(
        prescriptionId: prescriptionId ?? this.prescriptionId,
        patientId: patientId ?? this.patientId,
        patientName: patientName ?? this.patientName,
        visitId: visitId ?? this.visitId,
        consultationId: consultationId ?? this.consultationId,
        doctorId: doctorId ?? this.doctorId,
        doctorName: doctorName ?? this.doctorName,
        medicationName: medicationName ?? this.medicationName,
        dosage: dosage ?? this.dosage,
        frequency: frequency ?? this.frequency,
        duration: duration ?? this.duration,
        quantity: quantity ?? this.quantity,
        instructions: instructions ?? this.instructions,
        status: status ?? this.status,
        dispensedQuantity: dispensedQuantity ?? this.dispensedQuantity,
        dispensedBy: dispensedBy ?? this.dispensedBy,
        dispensedByName: dispensedByName ?? this.dispensedByName,
        dispensedAt: dispensedAt ?? this.dispensedAt,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  String toString() =>
      'PrescriptionModel($prescriptionId, $medicationName x$quantity, $status)';
}
