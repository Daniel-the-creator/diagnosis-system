import '../models/discharge_model.dart';
import '../services/firestore/discharge_firestore_service.dart';

class DischargeRepository {
  DischargeRepository(this._service);
  final DischargeFirestoreService _service;

  String generateDischargeId() => _service.generateDischargeId();

  Future<void> saveDischarge(DischargeModel discharge) =>
      _service.saveDischarge(discharge);

  Future<DischargeModel?> getDischargeById(String id) =>
      _service.getDischargeById(id);

  Future<DischargeModel?> getDischargeByVisitId(String visitId) =>
      _service.getDischargeByVisitId(visitId);

  Stream<List<DischargeModel>> streamPatientDischarges(String patientId) =>
      _service.streamPatientDischarges(patientId);

  Future<void> processDischarge({
    required DischargeModel discharge,
    String? admissionId,
    String? bedId,
  }) =>
      _service.processDischarge(
        discharge: discharge,
        admissionId: admissionId,
        bedId: bedId,
      );
}
