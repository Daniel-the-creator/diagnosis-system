import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firestore_constants.dart';
import '../../models/patient_model.dart';
import 'firestore_service.dart';

/// Firestore operations for the [patients] collection.
class PatientFirestoreService {
  PatientFirestoreService(this._fs);
  final FirestoreService _fs;

  static const String _col = FirestoreConstants.patientsCollection;

  String generateId() => _fs.generateId(_col);

  Future<void> savePatient(PatientModel patient) =>
      _fs.setDoc(_col, patient.patientId, patient.toFirestore());

  Future<PatientModel?> getPatientById(String patientId) async {
    final doc = await _fs.getDoc(_col, patientId);
    if (!doc.exists) return null;
    return PatientModel.fromFirestore(doc);
  }

  Future<PatientModel?> getPatientByHospitalNumber(
      String hospitalNumber) async {
    final snap = await _fs.db
        .collection(_col)
        .where('hospitalNumber', isEqualTo: hospitalNumber)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return PatientModel.fromFirestore(snap.docs.first);
  }

  Future<bool> hospitalNumberExists(String hospitalNumber) async {
    try {
      final snap = await _fs.db
          .collection(_col)
          .where('hospitalNumber', isEqualTo: hospitalNumber)
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<List<PatientModel>> searchPatients(String query) async {
    final q = query.trim().toLowerCase();
    final Map<String, PatientModel> results = {};

    try {
      final byNumber = await _fs.db
          .collection(_col)
          .where('hospitalNumber', isEqualTo: query.trim().toUpperCase())
          .limit(10)
          .get();
      for (final doc in byNumber.docs) {
        results[doc.id] = PatientModel.fromFirestore(doc);
      }
    } catch (_) {}

    try {
      final byPhone = await _fs.db
          .collection(_col)
          .where('phone', isEqualTo: query.trim())
          .limit(10)
          .get();
      for (final doc in byPhone.docs) {
        results[doc.id] = PatientModel.fromFirestore(doc);
      }
    } catch (_) {}

    try {
      final byNameStart = await _fs.db
          .collection(_col)
          .orderBy('fullName')
          .startAt([q.isNotEmpty ? q[0].toUpperCase() + q.substring(1) : ''])
          .endAt(['${q.isNotEmpty ? q[0].toUpperCase() + q.substring(1) : ''}\uf8ff'])
          .limit(10)
          .get();
      for (final doc in byNameStart.docs) {
        results[doc.id] = PatientModel.fromFirestore(doc);
      }
    } catch (_) {}

    return results.values.toList();
  }

  Future<void> updatePatient(
      String patientId, Map<String, dynamic> data) async {
    await _fs.updateDoc(_col, patientId, {
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<PatientModel?> streamPatient(String patientId) =>
      _fs.streamDoc(_col, patientId).map((doc) {
        if (!doc.exists) return null;
        return PatientModel.fromFirestore(doc);
      });

  Future<List<PatientModel>> getRecentPatients({int limit = 20}) async {
    final snap = await _fs.db
        .collection(_col)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(PatientModel.fromFirestore).toList();
  }
}
