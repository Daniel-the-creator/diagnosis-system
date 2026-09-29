import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firestore_constants.dart';
import '../../models/staff_schedule_model.dart';
import 'firestore_service.dart';

/// Firestore persistence and conflict-checking service for staff schedules.
class StaffScheduleFirestoreService {
  StaffScheduleFirestoreService(this._fs);
  final FirestoreService _fs;

  static const String _col = FirestoreConstants.staffSchedulesCollection;

  String generateScheduleId() => _fs.generateId(_col);

  /// Validates and saves a new staff duty schedule.
  /// Prevents:
  /// 1. Double-booking the same staff member for overlapping hours.
  /// 2. Double-booking the same room for overlapping hours.
  Future<void> createSchedule(StaffScheduleModel schedule) async {
    final startOfDay = DateTime(schedule.date.year, schedule.date.month, schedule.date.day);
    final endOfDay = DateTime(schedule.date.year, schedule.date.month, schedule.date.day, 23, 59, 59);

    // Fetch existing active schedules on the target date
    final snap = await _fs.db
        .collection(_col)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .where('status', isEqualTo: 'ACTIVE')
        .get();

    final existing = snap.docs.map(StaffScheduleModel.fromFirestore).toList();

    for (final s in existing) {
      if (s.overlapsWith(
        otherDate: schedule.date,
        otherStart: schedule.startTime,
        otherEnd: schedule.endTime,
      )) {
        if (s.staffId == schedule.staffId) {
          throw Exception(
              'Scheduling Conflict: ${schedule.staffName} is already scheduled for ${s.startTime} - ${s.endTime} in ${s.departmentName}.');
        }
        if (schedule.roomId != null &&
            schedule.roomId!.isNotEmpty &&
            s.roomId == schedule.roomId) {
          throw Exception(
              'Room Conflict: Room ${schedule.roomName ?? schedule.roomId} is already booked by ${s.staffName} from ${s.startTime} to ${s.endTime}.');
        }
      }
    }

    await _fs.setDoc(_col, schedule.scheduleId, schedule.toFirestore());
  }

  /// Cancels an active schedule
  Future<void> cancelSchedule(String scheduleId) =>
      _fs.updateDoc(_col, scheduleId, {'status': 'CANCELLED'});

  /// Streams active schedules for a specific date
  Stream<List<StaffScheduleModel>> streamSchedulesForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _fs.db
        .collection(_col)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snap) =>
            snap.docs.map(StaffScheduleModel.fromFirestore).toList());
  }

  /// Streams all upcoming and today schedules
  Stream<List<StaffScheduleModel>> streamUpcomingSchedules() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    return _fs.db
        .collection(_col)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(StaffScheduleModel.fromFirestore).toList();
      list.sort((a, b) => a.date.compareTo(b.date));
      return list;
    });
  }

  /// Streams schedules for a specific staff member
  Stream<List<StaffScheduleModel>> streamStaffSchedules(String staffId) =>
      _fs.db
          .collection(_col)
          .where('staffId', isEqualTo: staffId)
          .snapshots()
          .map((snap) {
        final list = snap.docs.map(StaffScheduleModel.fromFirestore).toList();
        list.sort((a, b) => b.date.compareTo(a.date));
        return list;
      });

  /// Check whether a staff member has an active scheduled shift right now
  Future<bool> isStaffAvailableNow(String staffId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final snap = await _fs.db
        .collection(_col)
        .where('staffId', isEqualTo: staffId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .where('status', isEqualTo: 'ACTIVE')
        .get();

    if (snap.docs.isEmpty) return true; // If no explicit scheduling restrictions, default available

    final currentMinutes = now.hour * 60 + now.minute;

    for (final doc in snap.docs) {
      final s = StaffScheduleModel.fromFirestore(doc);
      final partsS = s.startTime.split(':');
      final partsE = s.endTime.split(':');
      final startMin = (int.tryParse(partsS[0]) ?? 0) * 60 + (int.tryParse(partsS[1]) ?? 0);
      final endMin = (int.tryParse(partsE[0]) ?? 0) * 60 + (int.tryParse(partsE[1]) ?? 0);

      if (currentMinutes >= startMin && currentMinutes <= endMin) {
        return true;
      }
    }

    return false;
  }
}
