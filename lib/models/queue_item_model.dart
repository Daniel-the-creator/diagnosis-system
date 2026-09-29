import 'package:cloud_firestore/cloud_firestore.dart';

/// Statuses a queue item can be in.
enum QueueStatus {
  waiting,
  called,
  inProgress,
  completed,
  skipped,
  cancelled,
  noShow,
  transferred;

  static QueueStatus fromString(String s) {
    switch (s.toUpperCase()) {
      case 'WAITING':
        return QueueStatus.waiting;
      case 'CALLED':
        return QueueStatus.called;
      case 'IN_PROGRESS':
        return QueueStatus.inProgress;
      case 'COMPLETED':
        return QueueStatus.completed;
      case 'SKIPPED':
        return QueueStatus.skipped;
      case 'CANCELLED':
        return QueueStatus.cancelled;
      case 'NO_SHOW':
        return QueueStatus.noShow;
      case 'TRANSFERRED':
        return QueueStatus.transferred;
      default:
        return QueueStatus.waiting;
    }
  }

  String toStatusString() {
    switch (this) {
      case QueueStatus.waiting:
        return 'WAITING';
      case QueueStatus.called:
        return 'CALLED';
      case QueueStatus.inProgress:
        return 'IN_PROGRESS';
      case QueueStatus.completed:
        return 'COMPLETED';
      case QueueStatus.skipped:
        return 'SKIPPED';
      case QueueStatus.cancelled:
        return 'CANCELLED';
      case QueueStatus.noShow:
        return 'NO_SHOW';
      case QueueStatus.transferred:
        return 'TRANSFERRED';
    }
  }

  String get displayLabel {
    switch (this) {
      case QueueStatus.waiting:
        return 'Waiting';
      case QueueStatus.called:
        return 'Called';
      case QueueStatus.inProgress:
        return 'In Progress';
      case QueueStatus.completed:
        return 'Completed';
      case QueueStatus.skipped:
        return 'Skipped';
      case QueueStatus.cancelled:
        return 'Cancelled';
      case QueueStatus.noShow:
        return 'No Show';
      case QueueStatus.transferred:
        return 'Transferred';
    }
  }

  /// Returns true if the item is still considered active/open.
  bool get isActive =>
      this == QueueStatus.waiting ||
      this == QueueStatus.called ||
      this == QueueStatus.inProgress;

  /// Returns true if the item is in a terminal state.
  bool get isTerminal =>
      this == QueueStatus.completed ||
      this == QueueStatus.cancelled ||
      this == QueueStatus.noShow;
}

/// One entry in a department queue.
/// State machine: WAITING → CALLED → IN_PROGRESS → COMPLETED
class QueueItemModel {
  final String queueId;
  final String queueNumber;    // e.g. 'REG-001'
  final String patientId;
  final String visitId;
  final String departmentId;   // department code e.g. 'REG'
  final String departmentName;
  final Map<String, dynamic> priority; // {level, label, weight}
  final QueueStatus status;
  final DateTime createdAt;
  final DateTime? calledAt;
  final DateTime? serviceStartedAt;
  final DateTime? completedAt;
  final String? assignedStaffId;
  final String? assignedRoomId;

  const QueueItemModel({
    required this.queueId,
    required this.queueNumber,
    required this.patientId,
    required this.visitId,
    required this.departmentId,
    required this.departmentName,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.calledAt,
    this.serviceStartedAt,
    this.completedAt,
    this.assignedStaffId,
    this.assignedRoomId,
  });

  String get priorityLevel => priority['level'] as String? ?? 'REGULAR';
  String get priorityLabel => priority['label'] as String? ?? 'Regular';

  bool get isCriticalEmergency => priorityLevel == 'CRITICAL_EMERGENCY';
  bool get isEmergency =>
      priorityLevel == 'EMERGENCY' || priorityLevel == 'CRITICAL_EMERGENCY';
  bool get isUrgent => priorityLevel == 'URGENT';
  bool get isRegular => priorityLevel == 'REGULAR';

  int get priorityWeight => priority['weight'] as int? ?? 1;

  String get displayQueueNumber => queueNumber;
  String get departmentCode => departmentId;
  String? get assignedRoomNumber => assignedRoomId;
  String? get assignedRoomName =>
      assignedRoomId != null ? 'Room $assignedRoomId' : null;

  factory QueueItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QueueItemModel(
      queueId: data['queueId'] as String? ?? doc.id,
      queueNumber: data['queueNumber'] as String? ?? '',
      patientId: data['patientId'] as String? ?? '',
      visitId: data['visitId'] as String? ?? '',
      departmentId: data['departmentId'] as String? ?? '',
      departmentName: data['departmentName'] as String? ?? '',
      priority:
          Map<String, dynamic>.from(data['priority'] as Map? ?? {}),
      status: QueueStatus.fromString(data['status'] as String? ?? 'WAITING'),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      calledAt: (data['calledAt'] as Timestamp?)?.toDate(),
      serviceStartedAt: (data['serviceStartedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      assignedStaffId: data['assignedStaffId'] as String?,
      assignedRoomId: data['assignedRoomId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'queueId': queueId,
        'queueNumber': queueNumber,
        'patientId': patientId,
        'visitId': visitId,
        'departmentId': departmentId,
        'departmentName': departmentName,
        'priority': priority,
        'status': status.toStatusString(),
        'createdAt': Timestamp.fromDate(createdAt),
        'calledAt': calledAt != null ? Timestamp.fromDate(calledAt!) : null,
        'serviceStartedAt': serviceStartedAt != null
            ? Timestamp.fromDate(serviceStartedAt!)
            : null,
        'completedAt':
            completedAt != null ? Timestamp.fromDate(completedAt!) : null,
        'assignedStaffId': assignedStaffId,
        'assignedRoomId': assignedRoomId,
      };

  QueueItemModel copyWith({
    String? queueId,
    String? queueNumber,
    String? patientId,
    String? visitId,
    String? departmentId,
    String? departmentName,
    Map<String, dynamic>? priority,
    QueueStatus? status,
    DateTime? createdAt,
    DateTime? calledAt,
    DateTime? serviceStartedAt,
    DateTime? completedAt,
    String? assignedStaffId,
    String? assignedRoomId,
  }) =>
      QueueItemModel(
        queueId: queueId ?? this.queueId,
        queueNumber: queueNumber ?? this.queueNumber,
        patientId: patientId ?? this.patientId,
        visitId: visitId ?? this.visitId,
        departmentId: departmentId ?? this.departmentId,
        departmentName: departmentName ?? this.departmentName,
        priority: priority ?? this.priority,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        calledAt: calledAt ?? this.calledAt,
        serviceStartedAt: serviceStartedAt ?? this.serviceStartedAt,
        completedAt: completedAt ?? this.completedAt,
        assignedStaffId: assignedStaffId ?? this.assignedStaffId,
        assignedRoomId: assignedRoomId ?? this.assignedRoomId,
      );

  @override
  String toString() =>
      'QueueItemModel($queueNumber, $departmentId, ${status.displayLabel})';
}
