import '../../core/constants/firestore_constants.dart';
import '../../models/notification_model.dart';
import 'firestore_service.dart';

/// Firestore operations for the notifications collection.
class NotificationFirestoreService {
  NotificationFirestoreService(this._fs);
  final FirestoreService _fs;

  static const String _notifCol = FirestoreConstants.notificationsCollection;

  String generateNotificationId() => _fs.generateId(_notifCol);

  Future<void> sendNotification(NotificationModel notification) =>
      _fs.setDoc(_notifCol, notification.notificationId, notification.toFirestore());

  Future<void> markAsRead(String notificationId) =>
      _fs.updateDoc(_notifCol, notificationId, {'read': true});

  Future<void> markAllAsRead(String recipientId) async {
    final snap = await _fs.db
        .collection(_notifCol)
        .where('recipientId', isEqualTo: recipientId)
        .where('read', isEqualTo: false)
        .get();

    final batch = _fs.db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  Future<void> archiveNotification(String notificationId) =>
      _fs.updateDoc(_notifCol, notificationId, {'isArchived': true});

  Future<void> deleteNotification(String notificationId) =>
      _fs.deleteDoc(_notifCol, notificationId);

  Stream<List<NotificationModel>> streamUserNotifications(
    String recipientId, {
    String? category,
    bool includeArchived = false,
  }) =>
      _fs.db
          .collection(_notifCol)
          .where('recipientId', isEqualTo: recipientId)
          .snapshots()
          .map((snap) {
        var list = snap.docs.map(NotificationModel.fromFirestore).toList();
        if (!includeArchived) {
          list = list.where((n) => !n.isArchived).toList();
        }
        if (category != null && category.isNotEmpty && category != 'ALL') {
          list = list.where((n) => n.category.toUpperCase() == category.toUpperCase()).toList();
        }
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });

  Stream<int> streamUnreadCount(String recipientId) => _fs.db
      .collection(_notifCol)
      .where('recipientId', isEqualTo: recipientId)
      .where('read', isEqualTo: false)
      .snapshots()
      .map((snap) => snap.docs.length);
}
