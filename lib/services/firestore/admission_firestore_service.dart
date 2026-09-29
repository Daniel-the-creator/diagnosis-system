import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firestore_constants.dart';
import '../../models/admission_models.dart';
import 'firestore_service.dart';

/// Firestore operations for admissions, wards, and beds collections.
class AdmissionFirestoreService {
  AdmissionFirestoreService(this._fs);
  final FirestoreService _fs;

  static const String _admCol = FirestoreConstants.admissionsCollection;
  static const String _wardCol = FirestoreConstants.wardsCollection;
  static const String _bedCol = FirestoreConstants.bedsCollection;

  String generateAdmissionId() => _fs.generateId(_admCol);
  String generateWardId() => _fs.generateId(_wardCol);
  String generateBedId() => _fs.generateId(_bedCol);

  // ── Admission Requests ──────────────────────────────────────────

  Future<void> saveAdmissionRequest(AdmissionRequestModel request) =>
      _fs.setDoc(_admCol, request.admissionRequestId, request.toFirestore());

  Future<AdmissionRequestModel?> getAdmissionRequestById(String id) async {
    final doc = await _fs.getDoc(_admCol, id);
    if (!doc.exists) return null;
    return AdmissionRequestModel.fromFirestore(doc);
  }

  Future<void> updateAdmissionRequest(String id, Map<String, dynamic> data) =>
      _fs.updateDoc(_admCol, id, data);

  Stream<List<AdmissionRequestModel>> streamAllAdmissionRequests() => _fs.db
      .collection(_admCol)
      .orderBy('requestedAt', descending: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map(AdmissionRequestModel.fromFirestore).toList());

  Stream<List<AdmissionRequestModel>> streamActiveAdmissionRequests() => _fs.db
      .collection(_admCol)
      .where('status', whereIn: ['REQUESTED', 'APPROVED', 'WAITING_FOR_BED', 'ADMITTED'])
      .orderBy('requestedAt', descending: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map(AdmissionRequestModel.fromFirestore).toList());

  Stream<List<AdmissionRequestModel>> streamPatientAdmissions(String patientId) =>
      _fs.db
          .collection(_admCol)
          .where('patientId', isEqualTo: patientId)
          .snapshots()
          .map((snap) {
            final list = snap.docs.map(AdmissionRequestModel.fromFirestore).toList();
            list.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
            return list;
          });

  // ── Wards ───────────────────────────────────────────────────────

  Future<void> saveWard(WardModel ward) =>
      _fs.setDoc(_wardCol, ward.wardId, ward.toFirestore());

  Stream<List<WardModel>> streamWards() => _fs.db
      .collection(_wardCol)
      .where('active', isEqualTo: true)
      .snapshots()
      .map((snap) => snap.docs.map(WardModel.fromFirestore).toList());

  Future<List<WardModel>> getAllWards() async {
    final snap = await _fs.db.collection(_wardCol).get();
    return snap.docs.map(WardModel.fromFirestore).toList();
  }

  // ── Beds ────────────────────────────────────────────────────────

  Future<void> saveBed(BedModel bed) =>
      _fs.setDoc(_bedCol, bed.bedId, bed.toFirestore());

  Stream<List<BedModel>> streamBeds({String? wardId}) {
    Query query = _fs.db.collection(_bedCol);
    if (wardId != null && wardId.isNotEmpty) {
      query = query.where('wardId', isEqualTo: wardId);
    }
    return query.snapshots().map(
        (snap) => snap.docs.map((d) => BedModel.fromFirestore(d)).toList());
  }

  Stream<List<BedModel>> streamAvailableBeds() => _fs.db
      .collection(_bedCol)
      .where('status', isEqualTo: 'AVAILABLE')
      .snapshots()
      .map((snap) => snap.docs.map(BedModel.fromFirestore).toList());

  /// Atomically assign a patient to a bed and update admission request.
  Future<void> assignBed({
    required String bedId,
    required String admissionRequestId,
    required String patientId,
    required String patientName,
    required String visitId,
    required String wardId,
    required String wardName,
    required String bedNumber,
  }) async {
    final bedRef = _fs.db.collection(_bedCol).doc(bedId);
    final admRef = _fs.db.collection(_admCol).doc(admissionRequestId);
    final visitRef = _fs.db.collection(FirestoreConstants.visitsCollection).doc(visitId);

    await _fs.db.runTransaction((tx) async {
      final bedSnap = await tx.get(bedRef);
      if (!bedSnap.exists) {
        throw Exception('Bed does not exist');
      }
      final currentStatus = bedSnap.data()?['status'];
      if (currentStatus != 'AVAILABLE') {
        throw Exception('Bed is not available (Status: $currentStatus)');
      }

      final now = FieldValue.serverTimestamp();

      tx.update(bedRef, {
        'status': 'OCCUPIED',
        'currentPatientId': patientId,
        'currentPatientName': patientName,
        'currentVisitId': visitId,
        'currentAdmissionId': admissionRequestId,
        'assignedAt': now,
      });

      tx.update(admRef, {
        'status': 'ADMITTED',
        'assignedWardId': wardId,
        'assignedWardName': wardName,
        'assignedBedId': bedId,
        'assignedBedNumber': bedNumber,
        'admittedAt': now,
      });

      tx.update(visitRef, {
        'status': 'ADMITTED',
        'careStage': 'ADMITTED',
        'updatedAt': now,
      });
    });
  }

  /// Release a bed atomically upon discharge or transfer.
  Future<void> releaseBed(String bedId) async {
    final bedRef = _fs.db.collection(_bedCol).doc(bedId);
    await bedRef.update({
      'status': 'AVAILABLE',
      'currentPatientId': null,
      'currentPatientName': null,
      'currentVisitId': null,
      'currentAdmissionId': null,
      'assignedAt': null,
    });
  }
}
