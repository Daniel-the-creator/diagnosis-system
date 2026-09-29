import 'package:cloud_firestore/cloud_firestore.dart';

/// An appointment record for a patient-doctor encounter.
/// Status flow: SCHEDULED -> CONFIRMED -> COMPLETED
///              Any -> CANCELLED | RESCHEDULED
///              SCHEDULED -> NO_SHOW
class AppointmentModel {
  final String appointmentId;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String departmentId;
  final String departmentName;

  final DateTime date;
  final String timeSlot; // e.g. '09:00 AM'
  final String reason;

  /// SCHEDULED | CONFIRMED | COMPLETED | CANCELLED | RESCHEDULED | NO_SHOW
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  final bool reminder24hSent;
  final bool reminder1hSent;

  const AppointmentModel({
    required this.appointmentId,
    required this.patientId,
    this.patientName = '',
    required this.doctorId,
    this.doctorName = '',
    required this.departmentId,
    this.departmentName = '',
    required this.date,
    required this.timeSlot,
    required this.reason,
    this.status = 'SCHEDULED',
    this.notes,
    this.reminder24hSent = false,
    this.reminder1hSent = false,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isUpcoming =>
      date.isAfter(DateTime.now()) &&
      (status == 'SCHEDULED' || status == 'CONFIRMED');

  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppointmentModel(
      appointmentId: data['appointmentId'] as String? ?? doc.id,
      patientId: data['patientId'] as String? ?? '',
      patientName: data['patientName'] as String? ?? '',
      doctorId: data['doctorId'] as String? ?? '',
      doctorName: data['doctorName'] as String? ?? '',
      departmentId: data['departmentId'] as String? ?? '',
      departmentName: data['departmentName'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timeSlot: data['timeSlot'] as String? ?? '',
      reason: data['reason'] as String? ?? '',
      status: data['status'] as String? ?? 'SCHEDULED',
      notes: data['notes'] as String?,
      reminder24hSent: data['reminder24hSent'] as bool? ?? false,
      reminder1hSent: data['reminder1hSent'] as bool? ?? false,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'appointmentId': appointmentId,
        'patientId': patientId,
        'patientName': patientName,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'departmentId': departmentId,
        'departmentName': departmentName,
        'date': Timestamp.fromDate(date),
        'timeSlot': timeSlot,
        'reason': reason,
        'status': status,
        'notes': notes,
        'reminder24hSent': reminder24hSent,
        'reminder1hSent': reminder1hSent,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt':
            updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  AppointmentModel copyWith({
    String? appointmentId,
    String? patientId,
    String? patientName,
    String? doctorId,
    String? doctorName,
    String? departmentId,
    String? departmentName,
    DateTime? date,
    String? timeSlot,
    String? reason,
    String? status,
    String? notes,
    bool? reminder24hSent,
    bool? reminder1hSent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      AppointmentModel(
        appointmentId: appointmentId ?? this.appointmentId,
        patientId: patientId ?? this.patientId,
        patientName: patientName ?? this.patientName,
        doctorId: doctorId ?? this.doctorId,
        doctorName: doctorName ?? this.doctorName,
        departmentId: departmentId ?? this.departmentId,
        departmentName: departmentName ?? this.departmentName,
        date: date ?? this.date,
        timeSlot: timeSlot ?? this.timeSlot,
        reason: reason ?? this.reason,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        reminder24hSent: reminder24hSent ?? this.reminder24hSent,
        reminder1hSent: reminder1hSent ?? this.reminder1hSent,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  String toString() =>
      'AppointmentModel($appointmentId, patient=$patientId, doctor=$doctorId, $status)';
}
