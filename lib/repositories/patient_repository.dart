import 'package:uuid/uuid.dart';
import '../models/patient_model.dart';
import '../services/firestore/patient_firestore_service.dart';
import '../core/errors/app_exception.dart';
import '../core/utils/hospital_number_generator.dart';

/// Business logic for patient records.
class PatientRepository {
  PatientRepository(this._patientService);
  final PatientFirestoreService _patientService;
  final _uuid = const Uuid();

  /// Registers a new patient. Generates a unique hospital number.
  Future<PatientModel> registerPatient({
    required String fullName,
    required String gender,
    required String phone,
    DateTime? dateOfBirth,
    String? email,
    String? address,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? bloodGroup,
    String? genotype,
    List<String>? allergies,
    String? medicalHistory,
    String? insuranceProvider,
    String? insuranceNumber,
  }) async {
    // Check for potential duplicate by phone
    final existing = await _patientService.searchPatients(phone);
    final duplicate = existing.where(
        (p) => p.phone == phone && p.fullName.toLowerCase() == fullName.toLowerCase());
    if (duplicate.isNotEmpty) {
      throw DuplicateException(
        message:
            'A patient with this name and phone number already exists (${duplicate.first.hospitalNumber}). '
            'Please search for the existing record.',
      );
    }

    // Generate unique hospital number
    String hospitalNumber;
    int attempts = 0;
    do {
      hospitalNumber = HospitalNumberGenerator.generate();
      attempts++;
      if (attempts > 10) {
        throw const DatabaseException(
            message: 'Could not generate a unique hospital number. '
                'Please try again.');
      }
    } while (await _patientService.hospitalNumberExists(hospitalNumber));

    final now = DateTime.now();
    final patientId = _uuid.v4();
    final patient = PatientModel(
      patientId: patientId,
      hospitalNumber: hospitalNumber,
      fullName: fullName,
      dateOfBirth: dateOfBirth,
      gender: gender,
      phone: phone,
      email: email,
      address: address,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
      bloodGroup: bloodGroup,
      genotype: genotype,
      allergies: allergies ?? [],
      medicalHistory: medicalHistory,
      insuranceProvider: insuranceProvider,
      insuranceNumber: insuranceNumber,
      createdAt: now,
      updatedAt: now,
    );

    await _patientService.savePatient(patient).timeout(const Duration(seconds: 15));
    return patient;
  }

  Future<PatientModel?> getPatientById(String patientId) =>
      _patientService.getPatientById(patientId);

  Future<PatientModel?> getPatientByHospitalNumber(String number) =>
      _patientService.getPatientByHospitalNumber(number);

  Future<List<PatientModel>> searchPatients(String query) =>
      _patientService.searchPatients(query);

  Future<void> updatePatient(
          String patientId, Map<String, dynamic> data) =>
      _patientService.updatePatient(patientId, data);

  Stream<PatientModel?> streamPatient(String patientId) =>
      _patientService.streamPatient(patientId);

  Future<List<PatientModel>> getRecentPatients() =>
      _patientService.getRecentPatients();
}
