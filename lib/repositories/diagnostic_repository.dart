import '../models/diagnostic_request_model.dart';
import '../models/diagnostic_result_model.dart';
import '../services/firestore/diagnostic_firestore_service.dart';

class DiagnosticRepository {
  DiagnosticRepository(this._service);
  final DiagnosticFirestoreService _service;

  String generateRequestId() => _service.generateRequestId();
  String generateResultId() => _service.generateResultId();

  Future<void> saveRequest(DiagnosticRequestModel request) =>
      _service.saveRequest(request);

  Future<DiagnosticRequestModel?> getRequestById(String id) =>
      _service.getRequestById(id);

  Future<void> updateRequest(String id, Map<String, dynamic> data) =>
      _service.updateRequest(id, data);

  Stream<List<DiagnosticRequestModel>> streamVisitRequests(String visitId) =>
      _service.streamVisitRequests(visitId);

  Stream<List<DiagnosticRequestModel>> streamActiveRequestsByType(String type) =>
      _service.streamActiveRequestsByType(type);

  Stream<List<DiagnosticRequestModel>> streamPatientRequests(String patientId) =>
      _service.streamPatientRequests(patientId);

  Future<void> saveResult(DiagnosticResultModel result) =>
      _service.saveResult(result);

  Future<DiagnosticResultModel?> getResultByRequestId(String requestId) =>
      _service.getResultByRequestId(requestId);

  Future<void> updateResult(String resultId, Map<String, dynamic> data) =>
      _service.updateResult(resultId, data);

  Stream<List<DiagnosticResultModel>> streamVisitResults(String visitId) =>
      _service.streamVisitResults(visitId);

  Stream<List<DiagnosticResultModel>> streamPatientReleasedResults(String patientId) =>
      _service.streamPatientReleasedResults(patientId);

  Future<void> releaseResultToPatient(String resultId) =>
      _service.releaseResultToPatient(resultId);

  /// Helper to record result and mark the request as COMPLETED
  Future<void> completeRequestWithResult({
    required DiagnosticResultModel result,
    required String requestId,
  }) async {
    await _service.saveResult(result);
    await _service.updateRequest(requestId, {
      'status': 'COMPLETED',
      'completedAt': DateTime.now(),
    });
  }
}
