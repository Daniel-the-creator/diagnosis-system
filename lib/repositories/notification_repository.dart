import '../models/notification_model.dart';
import '../services/firestore/notification_firestore_service.dart';

class NotificationRepository {
  NotificationRepository(this._service);
  final NotificationFirestoreService _service;

  String generateNotificationId() => _service.generateNotificationId();

  Future<void> sendNotification(NotificationModel notification) =>
      _service.sendNotification(notification);

  Future<void> markAsRead(String notificationId) =>
      _service.markAsRead(notificationId);

  Future<void> markAllAsRead(String recipientId) =>
      _service.markAllAsRead(recipientId);

  Future<void> archiveNotification(String notificationId) =>
      _service.archiveNotification(notificationId);

  Future<void> deleteNotification(String notificationId) =>
      _service.deleteNotification(notificationId);

  Stream<List<NotificationModel>> streamUserNotifications(
    String recipientId, {
    String? category,
    bool includeArchived = false,
  }) =>
      _service.streamUserNotifications(
        recipientId,
        category: category,
        includeArchived: includeArchived,
      );

  Stream<int> streamUnreadCount(String recipientId) =>
      _service.streamUnreadCount(recipientId);

  /// Quick helper to dispatch a targeted alert to patient or staff.
  Future<void> notify({
    required String recipientId,
    required String recipientType,
    required String title,
    required String body,
    required String type,
    String? relatedId,
  }) async {
    final id = _service.generateNotificationId();
    await _service.sendNotification(
      NotificationModel(
        notificationId: id,
        recipientId: recipientId,
        recipientType: recipientType,
        title: title,
        body: body,
        type: type,
        relatedId: relatedId,
        read: false,
        createdAt: DateTime.now(),
      ),
    );
  }
}
