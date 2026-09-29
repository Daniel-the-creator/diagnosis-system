import 'package:cloud_firestore/cloud_firestore.dart';

/// An in-patient admission request raised by a doctor.
/// Status flow: REQUESTED -> APPROVED -> WAITING_FOR_BED -> ADMITTED -> DISCHARGED
///              Any active state -> DECLINED | CANCELLED
class AdmissionRequestModel {
  final String admissionRequestId;
  final String patientId;
  final String patientName;
  final String visitId;
  final String doctorId;
  final String doctorName;
  final String reason;
  final String priority; // 'ROUTINE' | 'URGENT' | 'EMERGENCY'

  /// REQUESTED | APPROVED | WAITING_FOR_BED | ADMITTED | DECLINED | CANCELLED | DISCHARGED
  final String status;

  final String? assignedWardId;
  final String? assignedWardName;
  final String? assignedBedId;
  final String? assignedBedNumber;

  final DateTime requestedAt;
  final DateTime? approvedAt;
  final DateTime? admittedAt;
  final DateTime? dischargedAt;
  final DateTime? expectedDischargeDate;

  const AdmissionRequestModel({
    required this.admissionRequestId,
    required this.patientId,
    this.patientName = '',
    required this.visitId,
    required this.doctorId,
    this.doctorName = '',
    required this.reason,
    this.priority = 'ROUTINE',
    this.status = 'REQUESTED',
    this.assignedWardId,
    this.assignedWardName,
    this.assignedBedId,
    this.assignedBedNumber,
    required this.requestedAt,
    this.approvedAt,
    this.admittedAt,
    this.dischargedAt,
    this.expectedDischargeDate,
  });

  bool get isAdmitted => status == 'ADMITTED';
  bool get isWaitingForBed => status == 'WAITING_FOR_BED';
  bool get isRequested => status == 'REQUESTED';

  factory AdmissionRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdmissionRequestModel(
      admissionRequestId: data['admissionRequestId'] as String? ?? doc.id,
      patientId: data['patientId'] as String? ?? '',
      patientName: data['patientName'] as String? ?? '',
      visitId: data['visitId'] as String? ?? '',
      doctorId: data['doctorId'] as String? ?? '',
      doctorName: data['doctorName'] as String? ?? '',
      reason: data['reason'] as String? ?? '',
      priority: data['priority'] as String? ?? 'ROUTINE',
      status: data['status'] as String? ?? 'REQUESTED',
      assignedWardId: data['assignedWardId'] as String?,
      assignedWardName: data['assignedWardName'] as String?,
      assignedBedId: data['assignedBedId'] as String?,
      assignedBedNumber: data['assignedBedNumber'] as String?,
      requestedAt:
          (data['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      admittedAt: (data['admittedAt'] as Timestamp?)?.toDate(),
      dischargedAt: (data['dischargedAt'] as Timestamp?)?.toDate(),
      expectedDischargeDate:
          (data['expectedDischargeDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'admissionRequestId': admissionRequestId,
        'patientId': patientId,
        'patientName': patientName,
        'visitId': visitId,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'reason': reason,
        'priority': priority,
        'status': status,
        'assignedWardId': assignedWardId,
        'assignedWardName': assignedWardName,
        'assignedBedId': assignedBedId,
        'assignedBedNumber': assignedBedNumber,
        'requestedAt': Timestamp.fromDate(requestedAt),
        'approvedAt':
            approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
        'admittedAt':
            admittedAt != null ? Timestamp.fromDate(admittedAt!) : null,
        'dischargedAt':
            dischargedAt != null ? Timestamp.fromDate(dischargedAt!) : null,
        'expectedDischargeDate': expectedDischargeDate != null
            ? Timestamp.fromDate(expectedDischargeDate!)
            : null,
      };

  AdmissionRequestModel copyWith({
    String? admissionRequestId,
    String? patientId,
    String? patientName,
    String? visitId,
    String? doctorId,
    String? doctorName,
    String? reason,
    String? priority,
    String? status,
    String? assignedWardId,
    String? assignedWardName,
    String? assignedBedId,
    String? assignedBedNumber,
    DateTime? requestedAt,
    DateTime? approvedAt,
    DateTime? admittedAt,
    DateTime? dischargedAt,
    DateTime? expectedDischargeDate,
  }) =>
      AdmissionRequestModel(
        admissionRequestId:
            admissionRequestId ?? this.admissionRequestId,
        patientId: patientId ?? this.patientId,
        patientName: patientName ?? this.patientName,
        visitId: visitId ?? this.visitId,
        doctorId: doctorId ?? this.doctorId,
        doctorName: doctorName ?? this.doctorName,
        reason: reason ?? this.reason,
        priority: priority ?? this.priority,
        status: status ?? this.status,
        assignedWardId: assignedWardId ?? this.assignedWardId,
        assignedWardName: assignedWardName ?? this.assignedWardName,
        assignedBedId: assignedBedId ?? this.assignedBedId,
        assignedBedNumber: assignedBedNumber ?? this.assignedBedNumber,
        requestedAt: requestedAt ?? this.requestedAt,
        approvedAt: approvedAt ?? this.approvedAt,
        admittedAt: admittedAt ?? this.admittedAt,
        dischargedAt: dischargedAt ?? this.dischargedAt,
        expectedDischargeDate:
            expectedDischargeDate ?? this.expectedDischargeDate,
      );

  @override
  String toString() =>
      'AdmissionRequestModel($admissionRequestId, patient=$patientId, $status)';
}

// ──────────────────────────────────────────────────────────────────

/// A hospital ward.
class WardModel {
  final String wardId;
  final String name;
  final String type; // e.g. 'General', 'Surgical', 'Paediatric', 'ICU'
  final int capacity;
  final bool active;
  final DateTime createdAt;

  const WardModel({
    required this.wardId,
    required this.name,
    this.type = 'General',
    required this.capacity,
    this.active = true,
    required this.createdAt,
  });

  factory WardModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WardModel(
      wardId: data['wardId'] as String? ?? doc.id,
      name: data['name'] as String? ?? '',
      type: data['type'] as String? ?? 'General',
      capacity: data['capacity'] as int? ?? 0,
      active: data['active'] as bool? ?? true,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'wardId': wardId,
        'name': name,
        'type': type,
        'capacity': capacity,
        'active': active,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  @override
  String toString() => 'WardModel($wardId, $name, capacity=$capacity)';
}

// ──────────────────────────────────────────────────────────────────

/// A bed within a ward.
class BedModel {
  final String bedId;
  final String wardId;
  final String wardName;
  final String bedNumber;

  /// AVAILABLE | RESERVED | OCCUPIED | MAINTENANCE
  final String status;

  /// Set when a patient is assigned to this bed.
  final String? currentPatientId;
  final String? currentPatientName;
  final String? currentVisitId;
  final String? currentAdmissionId;
  final DateTime? assignedAt;

  const BedModel({
    required this.bedId,
    required this.wardId,
    this.wardName = '',
    required this.bedNumber,
    this.status = 'AVAILABLE',
    this.currentPatientId,
    this.currentPatientName,
    this.currentVisitId,
    this.currentAdmissionId,
    this.assignedAt,
  });

  bool get isAvailable => status == 'AVAILABLE';
  bool get isOccupied => status == 'OCCUPIED';

  factory BedModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BedModel(
      bedId: data['bedId'] as String? ?? doc.id,
      wardId: data['wardId'] as String? ?? '',
      wardName: data['wardName'] as String? ?? '',
      bedNumber: data['bedNumber'] as String? ?? '',
      status: data['status'] as String? ?? 'AVAILABLE',
      currentPatientId: data['currentPatientId'] as String?,
      currentPatientName: data['currentPatientName'] as String?,
      currentVisitId: data['currentVisitId'] as String?,
      currentAdmissionId: data['currentAdmissionId'] as String?,
      assignedAt: (data['assignedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'bedId': bedId,
        'wardId': wardId,
        'wardName': wardName,
        'bedNumber': bedNumber,
        'status': status,
        'currentPatientId': currentPatientId,
        'currentPatientName': currentPatientName,
        'currentVisitId': currentVisitId,
        'currentAdmissionId': currentAdmissionId,
        'assignedAt':
            assignedAt != null ? Timestamp.fromDate(assignedAt!) : null,
      };

  BedModel copyWith({
    String? bedId,
    String? wardId,
    String? wardName,
    String? bedNumber,
    String? status,
    String? currentPatientId,
    String? currentPatientName,
    String? currentVisitId,
    String? currentAdmissionId,
    DateTime? assignedAt,
  }) =>
      BedModel(
        bedId: bedId ?? this.bedId,
        wardId: wardId ?? this.wardId,
        wardName: wardName ?? this.wardName,
        bedNumber: bedNumber ?? this.bedNumber,
        status: status ?? this.status,
        currentPatientId: currentPatientId ?? this.currentPatientId,
        currentPatientName: currentPatientName ?? this.currentPatientName,
        currentVisitId: currentVisitId ?? this.currentVisitId,
        currentAdmissionId: currentAdmissionId ?? this.currentAdmissionId,
        assignedAt: assignedAt ?? this.assignedAt,
      );

  @override
  String toString() =>
      'BedModel($bedId, ward=$wardId, bed=$bedNumber, $status)';
}
