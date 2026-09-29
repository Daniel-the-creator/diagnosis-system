import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firestore_constants.dart';
import '../../models/consultation_model.dart';
import 'firestore_service.dart';

/// Firestore operations for the consultations collection.
class ConsultationFirestoreService {
  ConsultationFirestoreService(this._fs);
  final FirestoreService _fs;

  static const String _col = FirestoreConstants.consultationsCollection;

  String generateId() => _fs.generateId(_col);

  Future<void> saveConsultation(ConsultationModel consultation) =>
      _fs.setDoc(_col, consultation.consultationId, consultation.toFirestore());

  Future<ConsultationModel?> getConsultationById(String consultationId) async {
    final doc = await _fs.getDoc(_col, consultationId);
    if (!doc.exists) return null;
    return ConsultationModel.fromFirestore(doc);
  }

  Future<void> updateConsultation(String consultationId, Map<String, dynamic> data) =>
      _fs.updateDoc(_col, consultationId, {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  /// Stream all consultations for a specific visit.
  Stream<List<ConsultationModel>> streamVisitConsultations(String visitId) =>
      _fs.db
          .collection(_col)
          .where('visitId', isEqualTo: visitId)
          .orderBy('createdAt')
          .snapshots()
          .map((snap) =>
              snap.docs.map(ConsultationModel.fromFirestore).toList());

  /// Stream all consultations for a specific patient (visit history).
  Stream<List<ConsultationModel>> streamPatientConsultations(String patientId) =>
      _fs.db
          .collection(_col)
          .where('patientId', isEqualTo: patientId)
          .snapshots()
          .map((snap) {
            final list = snap.docs.map(ConsultationModel.fromFirestore).toList();
            list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return list;
          });

  /// Get the latest consultation for a visit.
  Future<ConsultationModel?> getLatestVisitConsultation(String visitId) async {
    final snap = await _fs.db
        .collection(_col)
        .where('visitId', isEqualTo: visitId)
        .get();
    if (snap.docs.isEmpty) return null;
    final list = snap.docs.map(ConsultationModel.fromFirestore).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list.first;
  }
}
