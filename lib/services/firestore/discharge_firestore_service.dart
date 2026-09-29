import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firestore_constants.dart';
import '../../models/discharge_model.dart';
import 'firestore_service.dart';

/// Firestore operations for the discharges collection.
class DischargeFirestoreService {
  DischargeFirestoreService(this._fs);
  final FirestoreService _fs;

  static const String _disCol = FirestoreConstants.dischargesCollection;

  String generateDischargeId() => _fs.generateId(_disCol);

  Future<void> saveDischarge(DischargeModel discharge) =>
      _fs.setDoc(_disCol, discharge.dischargeId, discharge.toFirestore());

  Future<DischargeModel?> getDischargeById(String id) async {
    final doc = await _fs.getDoc(_disCol, id);
    if (!doc.exists) return null;
    return DischargeModel.fromFirestore(doc);
  }

  Future<DischargeModel?> getDischargeByVisitId(String visitId) async {
    final snap = await _fs.db
        .collection(_disCol)
        .where('visitId', isEqualTo: visitId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return DischargeModel.fromFirestore(snap.docs.first);
  }

  Stream<List<DischargeModel>> streamPatientDischarges(String patientId) =>
      _fs.db
          .collection(_disCol)
          .where('patientId', isEqualTo: patientId)
          .orderBy('dischargedAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs.map(DischargeModel.fromFirestore).toList());

  /// Atomically process a discharge: record discharge doc, update visit, and release bed if admitted.
  Future<void> processDischarge({
    required DischargeModel discharge,
    String? admissionId,
    String? bedId,
  }) async {
    final now = FieldValue.serverTimestamp();
    final dischargeRef = _fs.db.collection(_disCol).doc(discharge.dischargeId);
    final visitRef = _fs.db
        .collection(FirestoreConstants.visitsCollection)
        .doc(discharge.visitId);

    await _fs.db.runTransaction((tx) async {
      // 1. Write discharge doc
      tx.set(dischargeRef, {
        ...discharge.toFirestore(),
        'dischargedAt': now,
      });

      // 2. Update visit status
      tx.update(visitRef, {
        'status': 'DISCHARGED',
        'careStage': 'DISCHARGED',
        'dischargeId': discharge.dischargeId,
        'updatedAt': now,
      });

      // 3. If admission exists, update admission
      if (admissionId != null && admissionId.isNotEmpty) {
        final admRef = _fs.db
            .collection(FirestoreConstants.admissionsCollection)
            .doc(admissionId);
        tx.update(admRef, {
          'status': 'DISCHARGED',
          'dischargedAt': now,
        });
      }

      // 4. If bed was assigned, release bed
      if (bedId != null && bedId.isNotEmpty) {
        final bedRef = _fs.db
            .collection(FirestoreConstants.bedsCollection)
            .doc(bedId);
        tx.update(bedRef, {
          'status': 'AVAILABLE',
          'currentPatientId': null,
          'currentPatientName': null,
          'currentVisitId': null,
          'currentAdmissionId': null,
          'assignedAt': null,
        });
      }
    });
  }
}
