import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firestore_constants.dart';
import '../../models/prescription_model.dart';
import '../../models/medication_model.dart';
import '../../core/errors/app_exception.dart';
import 'firestore_service.dart';

/// Firestore operations for prescriptions and medications (inventory) collections.
class PharmacyFirestoreService {
  PharmacyFirestoreService(this._fs);
  final FirestoreService _fs;

  static const String _rxCol = FirestoreConstants.prescriptionsCollection;
  static const String _medCol = FirestoreConstants.medicationsCollection;

  String generatePrescriptionId() => _fs.generateId(_rxCol);
  String generateMedicationId() => _fs.generateId(_medCol);

  // ── Prescriptions ──────────────────────────────────────────────

  Future<void> savePrescription(PrescriptionModel rx) =>
      _fs.setDoc(_rxCol, rx.prescriptionId, rx.toFirestore());

  Future<PrescriptionModel?> getPrescriptionById(String prescriptionId) async {
    final doc = await _fs.getDoc(_rxCol, prescriptionId);
    if (!doc.exists) return null;
    return PrescriptionModel.fromFirestore(doc);
  }

  Future<void> updatePrescription(
          String prescriptionId, Map<String, dynamic> data) =>
      _fs.updateDoc(_rxCol, prescriptionId, data);

  /// Stream pending prescriptions for a visit.
  Stream<List<PrescriptionModel>> streamVisitPrescriptions(String visitId) =>
      _fs.db
          .collection(_rxCol)
          .where('visitId', isEqualTo: visitId)
          .orderBy('createdAt')
          .snapshots()
          .map((snap) =>
              snap.docs.map(PrescriptionModel.fromFirestore).toList());

  /// Stream all pending/partial prescriptions for the pharmacy queue.
  Stream<List<PrescriptionModel>> streamPendingPrescriptions() =>
      _fs.db
          .collection(_rxCol)
          .where('status', whereIn: ['PENDING', 'PARTIALLY_DISPENSED'])
          .orderBy('createdAt')
          .snapshots()
          .map((snap) =>
              snap.docs.map(PrescriptionModel.fromFirestore).toList());

  /// Stream all prescriptions across the hospital (all statuses).
  Stream<List<PrescriptionModel>> streamAllPrescriptions() =>
      _fs.db
          .collection(_rxCol)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) =>
              snap.docs.map(PrescriptionModel.fromFirestore).toList());

  /// Stream all prescriptions for a patient.
  Stream<List<PrescriptionModel>> streamPatientPrescriptions(String patientId) =>
      _fs.db
          .collection(_rxCol)
          .where('patientId', isEqualTo: patientId)
          .snapshots()
          .map((snap) {
            final list = snap.docs.map(PrescriptionModel.fromFirestore).toList();
            list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return list;
          });

  // ── Dispensing (atomic — checks stock before dispensing) ───────

  /// Dispenses medication atomically.
  /// Throws [ValidationException] if stock is insufficient.
  Future<void> dispenseMedication({
    required String prescriptionId,
    required String medicationId,
    required int quantityToDispense,
    required String dispensedBy,
    required String dispensedByName,
  }) async {
    final rxRef = _fs.db.collection(_rxCol).doc(prescriptionId);
    final medRef = _fs.db.collection(_medCol).doc(medicationId);

    await _fs.runTransaction<void>((txn) async {
      final rxSnap = await txn.get(rxRef);
      final medSnap = await txn.get(medRef);

      if (!rxSnap.exists || !medSnap.exists) {
        throw const ValidationException(
            message: 'Prescription or medication record not found.');
      }

      final currentStock = medSnap.data()!['quantity'] as int? ?? 0;
      if (currentStock < quantityToDispense) {
        throw ValidationException(
          message:
              'Insufficient stock. Available: $currentStock, Requested: $quantityToDispense.',
        );
      }

      final currentDispensed =
          rxSnap.data()!['dispensedQuantity'] as int? ?? 0;
      final totalRequired = rxSnap.data()!['quantity'] as int? ?? 0;
      final newDispensed = currentDispensed + quantityToDispense;
      final newStatus =
          newDispensed >= totalRequired ? 'DISPENSED' : 'PARTIALLY_DISPENSED';

      txn.update(medRef, {
        'quantity': currentStock - quantityToDispense,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      txn.update(rxRef, {
        'dispensedQuantity': newDispensed,
        'status': newStatus,
        'dispensedBy': dispensedBy,
        'dispensedByName': dispensedByName,
        'dispensedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ── Medications / Inventory ────────────────────────────────────

  Future<void> saveMedication(MedicationModel med) =>
      _fs.setDoc(_medCol, med.medicationId, med.toFirestore());

  Future<MedicationModel?> getMedicationById(String medicationId) async {
    final doc = await _fs.getDoc(_medCol, medicationId);
    if (!doc.exists) return null;
    return MedicationModel.fromFirestore(doc);
  }

  Future<void> updateMedication(
          String medicationId, Map<String, dynamic> data) =>
      _fs.updateDoc(_medCol, medicationId, {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> addStock(String medicationId, int addedQuantity) =>
      _fs.db.collection(_medCol).doc(medicationId).update({
        'quantity': FieldValue.increment(addedQuantity),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Stream<List<MedicationModel>> streamAllMedications() =>
      _fs.db
          .collection(_medCol)
          .orderBy('drugName')
          .snapshots()
          .map((snap) =>
              snap.docs.map(MedicationModel.fromFirestore).toList());

  /// Stream medications with quantity at or below their minimum stock level.
  Stream<List<MedicationModel>> streamLowStockMedications() =>
      _fs.db
          .collection(_medCol)
          .snapshots()
          .map((snap) {
            return snap.docs
                .map(MedicationModel.fromFirestore)
                .where((m) => m.isLowStock || m.isExpired || m.isNearExpiry)
                .toList();
          });
}
