import '../models/consultation_model.dart';
import '../services/firestore/consultation_firestore_service.dart';

class ConsultationRepository {
  ConsultationRepository(this._service);
  final ConsultationFirestoreService _service;

  String generateId() => _service.generateId();

  Future<void> saveConsultation(ConsultationModel consultation) =>
      _service.saveConsultation(consultation);

  Future<ConsultationModel?> getConsultationById(String id) =>
      _service.getConsultationById(id);

  Future<ConsultationModel?> getLatestVisitConsultation(String visitId) =>
      _service.getLatestVisitConsultation(visitId);

  Future<void> updateConsultation(String id, Map<String, dynamic> data) =>
      _service.updateConsultation(id, data);

  Stream<List<ConsultationModel>> streamVisitConsultations(String visitId) =>
      _service.streamVisitConsultations(visitId);

  Stream<List<ConsultationModel>> streamPatientConsultations(String patientId) =>
      _service.streamPatientConsultations(patientId);
}
