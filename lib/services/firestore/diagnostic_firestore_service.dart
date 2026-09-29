import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firestore_constants.dart';
import '../../models/diagnostic_request_model.dart';
import '../../models/diagnostic_result_model.dart';
import 'firestore_service.dart';

/// Firestore operations for diagnostic_requests and diagnostic_results collections.
class DiagnosticFirestoreService {
  DiagnosticFirestoreService(this._fs);
  final FirestoreService _fs;

  static const String _reqCol = FirestoreConstants.diagnosticRequestsCollection;
  static const String _resCol = FirestoreConstants.diagnosticResultsCollection;

  // ── Request IDs ────────────────────────────────────────────────
  String generateRequestId() => _fs.generateId(_reqCol);
  String generateResultId() => _fs.generateId(_resCol);

  // ── Diagnostic Requests ────────────────────────────────────────

  Future<void> saveRequest(DiagnosticRequestModel request) =>
      _fs.setDoc(_reqCol, request.diagnosticRequestId, request.toFirestore());

  Future<DiagnosticRequestModel?> getRequestById(String requestId) async {
    final doc = await _fs.getDoc(_reqCol, requestId);
    if (!doc.exists) return null;
    return DiagnosticRequestModel.fromFirestore(doc);
  }

  Future<void> updateRequest(String requestId, Map<String, dynamic> data) =>
      _fs.updateDoc(_reqCol, requestId, data);

  /// Stream all diagnostic requests for a visit.
  Stream<List<DiagnosticRequestModel>> streamVisitRequests(String visitId) =>
      _fs.db
          .collection(_reqCol)
          .where('visitId', isEqualTo: visitId)
          .orderBy('requestedAt')
          .snapshots()
          .map((snap) =>
              snap.docs.map(DiagnosticRequestModel.fromFirestore).toList());

  /// Stream active (non-cancelled/completed) requests for a department type or ALL types.
  Stream<List<DiagnosticRequestModel>> streamActiveRequestsByType(
      String diagnosticType) {
    Query query = _fs.db
        .collection(_reqCol)
        .where('status', whereIn: ['PAID', 'WAITING', 'IN_PROGRESS']);

    if (diagnosticType != 'ALL') {
      query = query.where('diagnosticType', isEqualTo: diagnosticType);
    }

    return query
        .orderBy('requestedAt')
        .snapshots()
        .map((snap) =>
            snap.docs.map(DiagnosticRequestModel.fromFirestore).toList());
  }

  /// Stream all requests for a patient.
  Stream<List<DiagnosticRequestModel>> streamPatientRequests(String patientId) =>
      _fs.db
          .collection(_reqCol)
          .where('patientId', isEqualTo: patientId)
          .snapshots()
          .map((snap) {
            final list = snap.docs.map(DiagnosticRequestModel.fromFirestore).toList();
            list.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
            return list;
          });

  // ── Diagnostic Results ─────────────────────────────────────────

  Future<void> saveResult(DiagnosticResultModel result) =>
      _fs.setDoc(_resCol, result.resultId, result.toFirestore());

  Future<DiagnosticResultModel?> getResultByRequestId(
      String diagnosticRequestId) async {
    final snap = await _fs.db
        .collection(_resCol)
        .where('diagnosticRequestId', isEqualTo: diagnosticRequestId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return DiagnosticResultModel.fromFirestore(snap.docs.first);
  }

  Future<void> updateResult(String resultId, Map<String, dynamic> data) =>
      _fs.updateDoc(_resCol, resultId, data);

  /// Stream all results for a visit.
  Stream<List<DiagnosticResultModel>> streamVisitResults(String visitId) =>
      _fs.db
          .collection(_resCol)
          .where('visitId', isEqualTo: visitId)
          .snapshots()
          .map((snap) {
            final list = snap.docs.map(DiagnosticResultModel.fromFirestore).toList();
            list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            return list;
          });

  /// Stream results visible to a patient (isReleasedToPatient == true).
  Stream<List<DiagnosticResultModel>> streamPatientReleasedResults(
      String patientId) =>
      _fs.db
          .collection(_resCol)
          .where('patientId', isEqualTo: patientId)
          .where('isReleasedToPatient', isEqualTo: true)
          .snapshots()
          .map((snap) {
            final list = snap.docs.map(DiagnosticResultModel.fromFirestore).toList();
            list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return list;
          });

  /// Release a result to the patient portal.
  Future<void> releaseResultToPatient(String resultId) =>
      _fs.updateDoc(_resCol, resultId, {'isReleasedToPatient': true});
}
