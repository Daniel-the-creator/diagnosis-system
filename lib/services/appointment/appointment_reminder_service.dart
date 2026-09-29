import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firestore_constants.dart';
import '../../models/appointment_model.dart';
import '../../models/notification_model.dart';
import '../firestore/notification_firestore_service.dart';

/// Service that evaluates upcoming appointments and dispatches idempotent 24-hour and 1-hour reminders.
class AppointmentReminderService {
  AppointmentReminderService(this._db, this._notifService);
  final FirebaseFirestore _db;
  final NotificationFirestoreService _notifService;

  static const String _apptCol = FirestoreConstants.appointmentsCollection;

  /// Scans appointments and dispatches due reminders without sending duplicates.
  Future<int> processAppointmentReminders() async {
    final now = DateTime.now();
    final in26Hours = now.add(const Duration(hours: 26));

    final snap = await _db
        .collection(_apptCol)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(in26Hours))
        .where('status', whereIn: ['SCHEDULED', 'CONFIRMED'])
        .get();

    int sentCount = 0;

    for (final doc in snap.docs) {
      final appt = AppointmentModel.fromFirestore(doc);
      final diff = appt.date.difference(now);

      // 24-hour reminder window: between 21 and 26 hours away
      if (diff.inHours >= 21 && diff.inHours <= 26 && !appt.reminder24hSent) {
        await _send24hReminder(appt);
        await doc.reference.update({'reminder24hSent': true});
        sentCount++;
      }

      // 1-hour reminder window: between 0 and 90 minutes away
      if (diff.inMinutes >= 0 && diff.inMinutes <= 90 && !appt.reminder1hSent) {
        await _send1hReminder(appt);
        await doc.reference.update({'reminder1hSent': true});
        sentCount++;
      }
    }

    return sentCount;
  }

  Future<void> _send24hReminder(AppointmentModel appt) async {
    final notifId = _notifService.generateNotificationId();
    final notif = NotificationModel(
      notificationId: notifId,
      recipientId: appt.patientId,
      recipientType: 'patient',
      title: 'Appointment Tomorrow: Dr. ${appt.doctorName}',
      body:
          'Your appointment at ${appt.departmentName} is scheduled for tomorrow at ${appt.timeSlot}. Please arrive 15 minutes early.',
      type: 'APPOINTMENT_REMINDER',
      relatedId: appt.appointmentId,
      createdAt: DateTime.now(),
    );
    await _notifService.sendNotification(notif);
  }

  Future<void> _send1hReminder(AppointmentModel appt) async {
    final notifId = _notifService.generateNotificationId();
    final notif = NotificationModel(
      notificationId: notifId,
      recipientId: appt.patientId,
      recipientType: 'patient',
      title: 'Upcoming Appointment in 1 Hour',
      body:
          'Your consultation with Dr. ${appt.doctorName} begins soon (${appt.timeSlot}). Please proceed to ${appt.departmentName}.',
      type: 'APPOINTMENT_REMINDER',
      relatedId: appt.appointmentId,
      createdAt: DateTime.now(),
    );
    await _notifService.sendNotification(notif);
  }
}
