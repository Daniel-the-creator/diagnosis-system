import '../models/staff_schedule_model.dart';
import '../services/firestore/staff_schedule_firestore_service.dart';

/// Repository for staff scheduling and duty assignments.
class StaffScheduleRepository {
  StaffScheduleRepository(this._service);
  final StaffScheduleFirestoreService _service;

  String generateScheduleId() => _service.generateScheduleId();

  Future<void> createSchedule(StaffScheduleModel schedule) =>
      _service.createSchedule(schedule);

  Future<void> cancelSchedule(String scheduleId) =>
      _service.cancelSchedule(scheduleId);

  Stream<List<StaffScheduleModel>> streamSchedulesForDate(DateTime date) =>
      _service.streamSchedulesForDate(date);

  Stream<List<StaffScheduleModel>> streamUpcomingSchedules() =>
      _service.streamUpcomingSchedules();

  Stream<List<StaffScheduleModel>> streamStaffSchedules(String staffId) =>
      _service.streamStaffSchedules(staffId);

  Future<bool> isStaffAvailableNow(String staffId) =>
      _service.isStaffAvailableNow(staffId);
}
