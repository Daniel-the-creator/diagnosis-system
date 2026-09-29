import 'package:cloud_firestore/cloud_firestore.dart';

/// Priority stored as a structured object.
class Priority {
  final String level;   // e.g. 'EMERGENCY', 'REGULAR'
  final String label;   // Display label
  final int weight;     // Higher = served first

  const Priority({
    required this.level,
    required this.label,
    required this.weight,
  });

  static const Priority criticalEmergency = Priority(
    level: 'CRITICAL_EMERGENCY',
    label: 'Critical Emergency',
    weight: 100,
  );

  static const Priority emergency = Priority(
    level: 'EMERGENCY',
    label: 'Emergency',
    weight: 50,
  );

  static const Priority urgent = Priority(
    level: 'URGENT',
    label: 'Urgent',
    weight: 20,
  );

  static const Priority regular = Priority(
    level: 'REGULAR',
    label: 'Regular',
    weight: 1,
  );

  static Priority fromLevel(String level) {
    switch (level.toUpperCase()) {
      case 'CRITICAL_EMERGENCY':
        return criticalEmergency;
      case 'EMERGENCY':
        return emergency;
      case 'URGENT':
        return urgent;
      case 'REGULAR':
      default:
        return regular;
    }
  }

  factory Priority.fromMap(Map<String, dynamic> map) {
    final lvl = (map['level'] as String? ?? 'REGULAR').toUpperCase();
    final defaultPriority = fromLevel(lvl);
    return Priority(
      level: lvl,
      label: map['label'] as String? ?? defaultPriority.label,
      weight: map['weight'] as int? ?? defaultPriority.weight,
    );
  }

  Map<String, dynamic> toMap() => {
        'level': level,
        'label': label,
        'weight': weight,
      };

  bool get isCriticalEmergency => level == 'CRITICAL_EMERGENCY';
  bool get isEmergency => level == 'EMERGENCY' || level == 'CRITICAL_EMERGENCY';
  bool get isUrgent => level == 'URGENT';
  bool get isRegular => level == 'REGULAR';

  @override
  String toString() => 'Priority($level, weight=$weight)';
}

/// A single hospital visit. Separate from the permanent patient profile.
/// Extended in Phase 2 with care stage tracking and relationship IDs
/// to consultations, diagnostics, billing, admission, and discharge records.
class VisitModel {
  final String visitId;
  final String patientId;
  final DateTime visitDate;
  final DateTime arrivalTime;
  final String patientType;       // 'REGULAR' | 'EMERGENCY'
  final Priority priority;
  final String currentDepartment; // current dept code
  final String currentStatus;     // 'ACTIVE' | 'COMPLETED' | 'CANCELLED'
  final bool completed;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ── Phase 1 assignment fields ──────────────────────────────────
  final String? assignedDoctorId;
  final String? assignedDoctorName;
  final String? assignedRoomId;

  // ── Phase 2 — Dynamic care stage & relationships ───────────────
  /// Fine-grained care stage for dynamic workflow tracking.
  /// e.g. 'ARRIVED', 'IN_CONSULTATION', 'AWAITING_PAYMENT', etc.
  final String? careStage;

  /// ID of the latest consultation record for this visit.
  final String? consultationId;

  /// IDs of all diagnostic requests raised for this visit.
  final List<String> diagnosticRequestIds;

  /// IDs of all prescriptions raised for this visit.
  final List<String> prescriptionIds;

  /// ID of the admission request for this visit (if any).
  final String? admissionRequestId;

  /// ID of the billing invoice for this visit.
  final String? invoiceId;

  /// ID of the discharge record for this visit.
  final String? dischargeId;

  /// Triage / clinical vitals recorded during registration or consultation.
  final Map<String, dynamic>? vitals;

  const VisitModel({
    required this.visitId,
    required this.patientId,
    required this.visitDate,
    required this.arrivalTime,
    required this.patientType,
    required this.priority,
    required this.currentDepartment,
    required this.currentStatus,
    this.assignedDoctorId,
    this.assignedDoctorName,
    this.assignedRoomId,
    required this.completed,
    required this.createdAt,
    required this.updatedAt,
    this.careStage,
    this.consultationId,
    this.diagnosticRequestIds = const [],
    this.prescriptionIds = const [],
    this.admissionRequestId,
    this.invoiceId,
    this.dischargeId,
    this.vitals,
  });

  bool get isEmergency => patientType == 'EMERGENCY';
  bool get isActive => currentStatus == 'ACTIVE';
  bool get hasDiagnostics => diagnosticRequestIds.isNotEmpty;
  bool get hasPrescriptions => prescriptionIds.isNotEmpty;
  bool get hasAdmission => admissionRequestId != null;
  bool get hasInvoice => invoiceId != null;
  bool get isDischarged => currentStatus == 'COMPLETED' || careStage == 'DISCHARGED';

  /// Dynamic workflow convenience getters
  String get status => careStage ?? currentStatus;
  DateTime get registrationTime => createdAt;

  factory VisitModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VisitModel(
      visitId: data['visitId'] as String? ?? doc.id,
      patientId: data['patientId'] as String? ?? '',
      visitDate: (data['visitDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      arrivalTime:
          (data['arrivalTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      patientType: data['patientType'] as String? ?? 'REGULAR',
      priority: Priority.fromMap(
          (data['priority'] as Map<String, dynamic>?) ?? {}),
      currentDepartment: data['currentDepartment'] as String? ?? 'GATE',
      currentStatus: data['currentStatus'] as String? ?? 'ACTIVE',
      assignedDoctorId: data['assignedDoctorId'] as String?,
      assignedDoctorName: data['assignedDoctorName'] as String?,
      assignedRoomId: data['assignedRoomId'] as String?,
      completed: data['completed'] as bool? ?? false,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      careStage: data['careStage'] as String?,
      consultationId: data['consultationId'] as String?,
      diagnosticRequestIds:
          List<String>.from(data['diagnosticRequestIds'] as List? ?? []),
      prescriptionIds:
          List<String>.from(data['prescriptionIds'] as List? ?? []),
      admissionRequestId: data['admissionRequestId'] as String?,
      invoiceId: data['invoiceId'] as String?,
      dischargeId: data['dischargeId'] as String?,
      vitals: data['vitals'] != null
          ? Map<String, dynamic>.from(data['vitals'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'visitId': visitId,
        'patientId': patientId,
        'visitDate': Timestamp.fromDate(visitDate),
        'arrivalTime': Timestamp.fromDate(arrivalTime),
        'patientType': patientType,
        'priority': priority.toMap(),
        'currentDepartment': currentDepartment,
        'currentStatus': currentStatus,
        'assignedDoctorId': assignedDoctorId,
        'assignedDoctorName': assignedDoctorName,
        'assignedRoomId': assignedRoomId,
        'completed': completed,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'careStage': careStage,
        'consultationId': consultationId,
        'diagnosticRequestIds': diagnosticRequestIds,
        'prescriptionIds': prescriptionIds,
        'admissionRequestId': admissionRequestId,
        'invoiceId': invoiceId,
        'dischargeId': dischargeId,
        'vitals': vitals,
      };

  VisitModel copyWith({
    String? visitId,
    String? patientId,
    DateTime? visitDate,
    DateTime? arrivalTime,
    String? patientType,
    Priority? priority,
    String? currentDepartment,
    String? currentStatus,
    String? assignedDoctorId,
    String? assignedDoctorName,
    String? assignedRoomId,
    bool? completed,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? careStage,
    String? consultationId,
    List<String>? diagnosticRequestIds,
    List<String>? prescriptionIds,
    String? admissionRequestId,
    String? invoiceId,
    String? dischargeId,
    Map<String, dynamic>? vitals,
  }) =>
      VisitModel(
        visitId: visitId ?? this.visitId,
        patientId: patientId ?? this.patientId,
        visitDate: visitDate ?? this.visitDate,
        arrivalTime: arrivalTime ?? this.arrivalTime,
        patientType: patientType ?? this.patientType,
        priority: priority ?? this.priority,
        currentDepartment: currentDepartment ?? this.currentDepartment,
        currentStatus: currentStatus ?? this.currentStatus,
        assignedDoctorId: assignedDoctorId ?? this.assignedDoctorId,
        assignedDoctorName: assignedDoctorName ?? this.assignedDoctorName,
        assignedRoomId: assignedRoomId ?? this.assignedRoomId,
        completed: completed ?? this.completed,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        careStage: careStage ?? this.careStage,
        consultationId: consultationId ?? this.consultationId,
        diagnosticRequestIds:
            diagnosticRequestIds ?? this.diagnosticRequestIds,
        prescriptionIds: prescriptionIds ?? this.prescriptionIds,
        admissionRequestId: admissionRequestId ?? this.admissionRequestId,
        invoiceId: invoiceId ?? this.invoiceId,
        dischargeId: dischargeId ?? this.dischargeId,
        vitals: vitals ?? this.vitals,
      );

  @override
  String toString() =>
      'VisitModel($visitId, patient=$patientId, dept=$currentDepartment, stage=$careStage)';
}
