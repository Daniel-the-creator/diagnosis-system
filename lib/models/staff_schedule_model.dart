import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a staff duty schedule assignment with conflict prevention.
class StaffScheduleModel {
  final String scheduleId;
  final String staffId;
  final String staffName;
  final String role;
  final String departmentCode;
  final String departmentName;
  final DateTime date;
  final String startTime; // "HH:mm" e.g. "08:00"
  final String endTime;   // "HH:mm" e.g. "16:00"
  final String? roomId;
  final String? roomName;
  final String status;    // 'ACTIVE' | 'CANCELLED' | 'COMPLETED'
  final DateTime createdAt;

  const StaffScheduleModel({
    required this.scheduleId,
    required this.staffId,
    required this.staffName,
    required this.role,
    required this.departmentCode,
    required this.departmentName,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.roomId,
    this.roomName,
    this.status = 'ACTIVE',
    required this.createdAt,
  });

  /// Parse "HH:mm" into minutes from start of day for comparison.
  int _toMinutes(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length != 2) return 0;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return h * 60 + m;
  }

  /// Returns true if this schedule overlaps with another schedule on the same date.
  bool overlapsWith({
    required DateTime otherDate,
    required String otherStart,
    required String otherEnd,
  }) {
    // Must be same date
    if (date.year != otherDate.year ||
        date.month != otherDate.month ||
        date.day != otherDate.day) {
      return false;
    }

    final start1 = _toMinutes(startTime);
    final end1 = _toMinutes(endTime);
    final start2 = _toMinutes(otherStart);
    final end2 = _toMinutes(otherEnd);

    // Overlap condition: start1 < end2 && start2 < end1
    return start1 < end2 && start2 < end1;
  }

  factory StaffScheduleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return StaffScheduleModel(
      scheduleId: data['scheduleId'] as String? ?? doc.id,
      staffId: data['staffId'] as String? ?? '',
      staffName: data['staffName'] as String? ?? '',
      role: data['role'] as String? ?? '',
      departmentCode: data['departmentCode'] as String? ?? '',
      departmentName: data['departmentName'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startTime: data['startTime'] as String? ?? '08:00',
      endTime: data['endTime'] as String? ?? '16:00',
      roomId: data['roomId'] as String?,
      roomName: data['roomName'] as String?,
      status: data['status'] as String? ?? 'ACTIVE',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'scheduleId': scheduleId,
        'staffId': staffId,
        'staffName': staffName,
        'role': role,
        'departmentCode': departmentCode,
        'departmentName': departmentName,
        'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
        'startTime': startTime,
        'endTime': endTime,
        'roomId': roomId,
        'roomName': roomName,
        'status': status,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  StaffScheduleModel copyWith({
    String? scheduleId,
    String? staffId,
    String? staffName,
    String? role,
    String? departmentCode,
    String? departmentName,
    DateTime? date,
    String? startTime,
    String? endTime,
    String? roomId,
    String? roomName,
    String? status,
    DateTime? createdAt,
  }) =>
      StaffScheduleModel(
        scheduleId: scheduleId ?? this.scheduleId,
        staffId: staffId ?? this.staffId,
        staffName: staffName ?? this.staffName,
        role: role ?? this.role,
        departmentCode: departmentCode ?? this.departmentCode,
        departmentName: departmentName ?? this.departmentName,
        date: date ?? this.date,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        roomId: roomId ?? this.roomId,
        roomName: roomName ?? this.roomName,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
      );
}
