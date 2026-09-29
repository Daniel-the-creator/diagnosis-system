import '../models/admission_models.dart';
import '../services/firestore/admission_firestore_service.dart';

class AdmissionRepository {
  AdmissionRepository(this._service);
  final AdmissionFirestoreService _service;

  String generateAdmissionId() => _service.generateAdmissionId();
  String generateWardId() => _service.generateWardId();
  String generateBedId() => _service.generateBedId();

  Future<void> saveAdmissionRequest(AdmissionRequestModel request) =>
      _service.saveAdmissionRequest(request);

  Future<AdmissionRequestModel?> getAdmissionRequestById(String id) =>
      _service.getAdmissionRequestById(id);

  Future<void> updateAdmissionRequest(String id, Map<String, dynamic> data) =>
      _service.updateAdmissionRequest(id, data);

  Stream<List<AdmissionRequestModel>> streamAllAdmissionRequests() =>
      _service.streamAllAdmissionRequests();

  Stream<List<AdmissionRequestModel>> streamActiveAdmissionRequests() =>
      _service.streamActiveAdmissionRequests();

  Stream<List<AdmissionRequestModel>> streamPatientAdmissions(String patientId) =>
      _service.streamPatientAdmissions(patientId);

  Future<void> saveWard(WardModel ward) => _service.saveWard(ward);

  Stream<List<WardModel>> streamWards() => _service.streamWards();

  Future<List<WardModel>> getAllWards() => _service.getAllWards();

  Future<void> saveBed(BedModel bed) => _service.saveBed(bed);

  Stream<List<BedModel>> streamBeds({String? wardId}) =>
      _service.streamBeds(wardId: wardId);

  Stream<List<BedModel>> streamAvailableBeds() =>
      _service.streamAvailableBeds();

  Future<void> assignBed({
    required String bedId,
    required String admissionRequestId,
    required String patientId,
    required String patientName,
    required String visitId,
    required String wardId,
    required String wardName,
    required String bedNumber,
  }) =>
      _service.assignBed(
        bedId: bedId,
        admissionRequestId: admissionRequestId,
        patientId: patientId,
        patientName: patientName,
        visitId: visitId,
        wardId: wardId,
        wardName: wardName,
        bedNumber: bedNumber,
      );

  Future<void> releaseBed(String bedId) => _service.releaseBed(bedId);
}
