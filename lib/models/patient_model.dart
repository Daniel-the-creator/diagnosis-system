import 'package:cloud_firestore/cloud_firestore.dart';

/// Permanent patient profile. Never deleted or replaced for returning patients.
class PatientModel {
  final String patientId;
  final String hospitalNumber;
  final String fullName;
  final DateTime? dateOfBirth;
  final String gender;
  final String phone;
  final String? email;
  final String? address;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? bloodGroup;
  final String? genotype;
  final List<String> allergies;
  final String? medicalHistory;
  final String? insuranceProvider;
  final String? insuranceNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PatientModel({
    required this.patientId,
    required this.hospitalNumber,
    required this.fullName,
    required this.gender,
    required this.phone,
    this.dateOfBirth,
    this.email,
    this.address,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.bloodGroup,
    this.genotype,
    this.allergies = const [],
    this.medicalHistory,
    this.insuranceProvider,
    this.insuranceNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayAge {
    if (dateOfBirth == null) return '—';
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return '$age yrs';
  }

  factory PatientModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PatientModel(
      patientId: data['patientId'] as String? ?? doc.id,
      hospitalNumber: data['hospitalNumber'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      dateOfBirth: (data['dateOfBirth'] as Timestamp?)?.toDate(),
      gender: data['gender'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      email: data['email'] as String?,
      address: data['address'] as String?,
      emergencyContactName: data['emergencyContactName'] as String?,
      emergencyContactPhone: data['emergencyContactPhone'] as String?,
      bloodGroup: data['bloodGroup'] as String?,
      genotype: data['genotype'] as String?,
      allergies: List<String>.from(data['allergies'] as List? ?? []),
      medicalHistory: data['medicalHistory'] as String?,
      insuranceProvider: data['insuranceProvider'] as String?,
      insuranceNumber: data['insuranceNumber'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'patientId': patientId,
        'hospitalNumber': hospitalNumber,
        'fullName': fullName,
        'dateOfBirth':
            dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
        'gender': gender,
        'phone': phone,
        'email': email,
        'address': address,
        'emergencyContactName': emergencyContactName,
        'emergencyContactPhone': emergencyContactPhone,
        'bloodGroup': bloodGroup,
        'genotype': genotype,
        'allergies': allergies,
        'medicalHistory': medicalHistory,
        'insuranceProvider': insuranceProvider,
        'insuranceNumber': insuranceNumber,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  PatientModel copyWith({
    String? patientId,
    String? hospitalNumber,
    String? fullName,
    DateTime? dateOfBirth,
    String? gender,
    String? phone,
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
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      PatientModel(
        patientId: patientId ?? this.patientId,
        hospitalNumber: hospitalNumber ?? this.hospitalNumber,
        fullName: fullName ?? this.fullName,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        gender: gender ?? this.gender,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        address: address ?? this.address,
        emergencyContactName:
            emergencyContactName ?? this.emergencyContactName,
        emergencyContactPhone:
            emergencyContactPhone ?? this.emergencyContactPhone,
        bloodGroup: bloodGroup ?? this.bloodGroup,
        genotype: genotype ?? this.genotype,
        allergies: allergies ?? this.allergies,
        medicalHistory: medicalHistory ?? this.medicalHistory,
        insuranceProvider: insuranceProvider ?? this.insuranceProvider,
        insuranceNumber: insuranceNumber ?? this.insuranceNumber,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  String toString() => 'PatientModel($patientId, $hospitalNumber, $fullName)';
}
