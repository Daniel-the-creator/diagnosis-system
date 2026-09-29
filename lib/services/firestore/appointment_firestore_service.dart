import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firestore_constants.dart';
import '../../models/appointment_model.dart';
import 'firestore_service.dart';

/// Firestore operations for the appointments collection.
class AppointmentFirestoreService {
  AppointmentFirestoreService(this._fs);
  final FirestoreService _fs;

  static const String _aptCol = FirestoreConstants.appointmentsCollection;

  String generateAppointmentId() => _fs.generateId(_aptCol);

  Future<void> saveAppointment(AppointmentModel appointment) =>
      _fs.setDoc(_aptCol, appointment.appointmentId, appointment.toFirestore());

  Future<AppointmentModel?> getAppointmentById(String id) async {
    final doc = await _fs.getDoc(_aptCol, id);
    if (!doc.exists) return null;
    return AppointmentModel.fromFirestore(doc);
  }

  Future<void> updateAppointment(String id, Map<String, dynamic> data) =>
      _fs.updateDoc(_aptCol, id, {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> cancelAppointment(String id, {String? reason}) =>
      updateAppointment(id, {
        'status': 'CANCELLED',
        if (reason != null) 'notes': reason,
      });

  Stream<List<AppointmentModel>> streamPatientAppointments(String patientId) =>
      _fs.db
          .collection(_aptCol)
          .where('patientId', isEqualTo: patientId)
          .snapshots()
          .map((snap) {
            final list = snap.docs.map(AppointmentModel.fromFirestore).toList();
            list.sort((a, b) => b.date.compareTo(a.date));
            return list;
          });

  Stream<List<AppointmentModel>> streamDoctorAppointments(
    String doctorId, {
    DateTime? date,
  }) {
    Query query = _fs.db
        .collection(_aptCol)
        .where('doctorId', isEqualTo: doctorId);

    if (date != null) {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      query = query
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThan: Timestamp.fromDate(end));
    }

    // Sort in Dart — avoids requiring a composite Firestore index on doctorId+date
    return query.snapshots().map((snap) {
      final list = snap.docs.map(AppointmentModel.fromFirestore).toList();
      list.sort((a, b) => a.date.compareTo(b.date));
      return list;
    });
  }

  /// Stream all appointments across all doctors (for Super Admin overview).
  Stream<List<AppointmentModel>> streamAllAppointments({
    DateTime? date,
  }) {
    Query query = _fs.db.collection(_aptCol);

    if (date != null) {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      query = query
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThan: Timestamp.fromDate(end));
    }

    return query.snapshots().map((snap) {
      final list = snap.docs.map(AppointmentModel.fromFirestore).toList();
      list.sort((a, b) => a.date.compareTo(b.date));
      return list;
    });
  }
}
