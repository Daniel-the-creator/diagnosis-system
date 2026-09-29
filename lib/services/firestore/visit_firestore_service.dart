import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firestore_constants.dart';
import '../../models/visit_model.dart';
import 'firestore_service.dart';

/// Firestore operations for the [visits] collection.
class VisitFirestoreService {
  VisitFirestoreService(this._fs);
  final FirestoreService _fs;

  static const String _col = FirestoreConstants.visitsCollection;

  String generateId() => _fs.generateId(_col);

  Future<void> saveVisit(VisitModel visit) =>
      _fs.setDoc(_col, visit.visitId, visit.toFirestore());

  Future<VisitModel?> getVisitById(String visitId) async {
    final doc = await _fs.getDoc(_col, visitId);
    if (!doc.exists) return null;
    return VisitModel.fromFirestore(doc);
  }

  Future<void> updateVisit(String visitId, Map<String, dynamic> data) =>
      _fs.updateDoc(_col, visitId, {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  /// Get today's active visits for a patient.
  Future<VisitModel?> getTodaysVisitForPatient(String patientId) async {
    final snap = await _fs.db
        .collection(_col)
        .where('patientId', isEqualTo: patientId)
        .get();
    if (snap.docs.isEmpty) return null;

    final today = DateTime.now();
    for (final doc in snap.docs) {
      final v = VisitModel.fromFirestore(doc);
      if (!v.completed &&
          v.visitDate.year == today.year &&
          v.visitDate.month == today.month &&
          v.visitDate.day == today.day) {
        return v;
      }
    }
    return null;
  }

  /// Stream all active visits today.
  Stream<List<VisitModel>> streamTodaysVisits() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return _fs.db
        .collection(_col)
        .where('visitDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('visitDate', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('visitDate', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map(VisitModel.fromFirestore).toList());
  }

  Stream<List<VisitModel>> streamPatientVisits(String patientId) =>
      _fs.db
          .collection(_col)
          .where('patientId', isEqualTo: patientId)
          .snapshots()
          .map((snap) {
            final list = snap.docs.map(VisitModel.fromFirestore).toList();
            list.sort((a, b) => b.visitDate.compareTo(a.visitDate));
            return list;
          });

  Future<int> countTodaysVisits() async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));
    final snap = await _fs.db
        .collection(_col)
        .where('visitDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('visitDate', isLessThan: Timestamp.fromDate(end))
        .count()
        .get();
    return snap.count ?? 0;
  }
}
