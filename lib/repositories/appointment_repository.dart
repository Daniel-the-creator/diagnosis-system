import '../models/appointment_model.dart';
import '../services/firestore/appointment_firestore_service.dart';

class AppointmentRepository {
  AppointmentRepository(this._service);
  final AppointmentFirestoreService _service;

  String generateAppointmentId() => _service.generateAppointmentId();

  Future<void> saveAppointment(AppointmentModel appointment) =>
      _service.saveAppointment(appointment);

  Future<AppointmentModel?> getAppointmentById(String id) =>
      _service.getAppointmentById(id);

  Future<void> updateAppointment(String id, Map<String, dynamic> data) =>
      _service.updateAppointment(id, data);

  Future<void> cancelAppointment(String id, {String? reason}) =>
      _service.cancelAppointment(id, reason: reason);

  Stream<List<AppointmentModel>> streamPatientAppointments(String patientId) =>
      _service.streamPatientAppointments(patientId);

  Stream<List<AppointmentModel>> streamDoctorAppointments(
    String doctorId, {
    DateTime? date,
  }) =>
      _service.streamDoctorAppointments(doctorId, date: date);

  Stream<List<AppointmentModel>> streamAllAppointments({DateTime? date}) =>
      _service.streamAllAppointments(date: date);
}
