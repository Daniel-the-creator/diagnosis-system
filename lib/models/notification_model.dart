import 'package:cloud_firestore/cloud_firestore.dart';

/// An in-app notification record stored in Firestore.
/// Firebase Cloud Messaging triggers are separate; this stores the
/// notification centre entries for patients and staff.
class NotificationModel {
  final String notificationId;
  final String recipientId;   // Firebase uid of the recipient
  final String recipientType; // 'patient' | 'staff'
  final String title;
  final String body;

  /// Notification event type — drives icon and colour in the UI.
  /// e.g. 'QUEUE_CALLED', 'RESULT_READY', 'PRESCRIPTION_READY', 'PAYMENT_DUE',
  ///      'ADMISSION_APPROVED', 'BED_ASSIGNED', 'DISCHARGE_READY',
  ///      'APPOINTMENT_REMINDER', 'QUEUE_APPROACHING'
  final String type;

  /// Notification category: QUEUE | MEDICAL | PAYMENT | APPOINTMENT | PHARMACY | ADMISSION | SYSTEM
  final String category;

  /// Whether notification is archived/hidden
  final bool isArchived;

  /// Optional ID of the related record (visitId, invoiceId, etc.).
  final String? relatedId;

  /// Whether the recipient has read this notification.
  final bool read;

  final DateTime createdAt;

  NotificationModel({
    required this.notificationId,
    required this.recipientId,
    required this.recipientType,
    required this.title,
    required this.body,
    this.type = 'GENERAL',
    String? category,
    this.isArchived = false,
    this.relatedId,
    this.read = false,
    required this.createdAt,
  }) : category = category ?? _deriveCategory(type);

  static String _deriveCategory(String typeStr) {
    final t = typeStr.toUpperCase();
    if (t.contains('QUEUE')) return 'QUEUE';
    if (t.contains('PAYMENT') || t.contains('INVOICE') || t.contains('BILL')) return 'PAYMENT';
    if (t.contains('PRESCRIPTION') || t.contains('MEDIC') || t.contains('PHARM')) return 'PHARMACY';
    if (t.contains('ADMISSION') || t.contains('BED') || t.contains('DISCHARGE')) return 'ADMISSION';
    if (t.contains('APPOINTMENT')) return 'APPOINTMENT';
    if (t.contains('RESULT') || t.contains('DIAG') || t.contains('CONSULT')) return 'MEDICAL';
    return 'SYSTEM';
  }

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final t = data['type'] as String? ?? 'GENERAL';
    return NotificationModel(
      notificationId: data['notificationId'] as String? ?? doc.id,
      recipientId: data['recipientId'] as String? ?? '',
      recipientType: data['recipientType'] as String? ?? 'patient',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      type: t,
      category: data['category'] as String? ?? _deriveCategory(t),
      isArchived: data['isArchived'] as bool? ?? false,
      relatedId: data['relatedId'] as String?,
      read: data['read'] as bool? ?? false,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'notificationId': notificationId,
        'recipientId': recipientId,
        'recipientType': recipientType,
        'title': title,
        'body': body,
        'type': type,
        'category': category,
        'isArchived': isArchived,
        'relatedId': relatedId,
        'read': read,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  NotificationModel copyWith({
    String? notificationId,
    String? recipientId,
    String? recipientType,
    String? title,
    String? body,
    String? type,
    String? category,
    bool? isArchived,
    String? relatedId,
    bool? read,
    DateTime? createdAt,
  }) =>
      NotificationModel(
        notificationId: notificationId ?? this.notificationId,
        recipientId: recipientId ?? this.recipientId,
        recipientType: recipientType ?? this.recipientType,
        title: title ?? this.title,
        body: body ?? this.body,
        type: type ?? this.type,
        category: category ?? this.category,
        isArchived: isArchived ?? this.isArchived,
        relatedId: relatedId ?? this.relatedId,
        read: read ?? this.read,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  String toString() =>
      'NotificationModel($notificationId, to=$recipientId, type=$type, read=$read)';
}
