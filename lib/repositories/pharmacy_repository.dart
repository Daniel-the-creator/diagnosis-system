import '../models/prescription_model.dart';
import '../models/medication_model.dart';
import '../services/firestore/pharmacy_firestore_service.dart';

class PharmacyRepository {
  PharmacyRepository(this._service);
  final PharmacyFirestoreService _service;

  String generatePrescriptionId() => _service.generatePrescriptionId();
  String generateMedicationId() => _service.generateMedicationId();

  Future<void> savePrescription(PrescriptionModel rx) =>
      _service.savePrescription(rx);

  Future<PrescriptionModel?> getPrescriptionById(String id) =>
      _service.getPrescriptionById(id);

  Future<void> updatePrescription(String id, Map<String, dynamic> data) =>
      _service.updatePrescription(id, data);

  Stream<List<PrescriptionModel>> streamVisitPrescriptions(String visitId) =>
      _service.streamVisitPrescriptions(visitId);

  Stream<List<PrescriptionModel>> streamPendingPrescriptions() =>
      _service.streamPendingPrescriptions();

  Stream<List<PrescriptionModel>> streamAllPrescriptions() =>
      _service.streamAllPrescriptions();

  Stream<List<PrescriptionModel>> streamPatientPrescriptions(String patientId) =>
      _service.streamPatientPrescriptions(patientId);

  Future<void> dispenseMedication({
    required String prescriptionId,
    required String medicationId,
    required int quantityToDispense,
    required String dispensedBy,
    required String dispensedByName,
  }) =>
      _service.dispenseMedication(
        prescriptionId: prescriptionId,
        medicationId: medicationId,
        quantityToDispense: quantityToDispense,
        dispensedBy: dispensedBy,
        dispensedByName: dispensedByName,
      );

  Future<void> saveMedication(MedicationModel med) =>
      _service.saveMedication(med);

  Future<MedicationModel?> getMedicationById(String id) =>
      _service.getMedicationById(id);

  Future<void> updateMedication(String id, Map<String, dynamic> data) =>
      _service.updateMedication(id, data);

  Future<void> addStock(String medicationId, int quantity) =>
      _service.addStock(medicationId, quantity);

  Stream<List<MedicationModel>> streamAllMedications() =>
      _service.streamAllMedications();

  Stream<List<MedicationModel>> streamLowStockMedications() =>
      _service.streamLowStockMedications();
}
