import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a staff user OR patient account in the system.
/// role == 'patient' identifies patient accounts; all other roles are staff.
class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final String? departmentId;
  final String? roomId;
  final String? specialty;
  final bool active;
  final DateTime createdAt;
  /// Phase 2: links a patient-role user back to their PatientModel document.
  final String? patientId;

  const UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.departmentId,
    this.roomId,
    this.specialty,
    required this.active,
    required this.createdAt,
    this.patientId,
  });

  // ── Role Checks ────────────────────────────────────────────────
  bool get isSuperAdmin => role == 'super_admin';
  bool get isHospitalAdmin => role == 'hospital_admin';
  bool get isAdmin => isSuperAdmin || isHospitalAdmin;
  bool get isGateOfficer => role == 'gate_officer';
  bool get isRegistrationOfficer => role == 'registration_officer';
  bool get isDoctor => role == 'doctor';
  bool get isNurse => role == 'nurse';

  // ── Phase 2 Role Checks ────────────────────────────────────────
  bool get isPatient => role == 'patient';
  bool get isDiagnosticStaff =>
      role == 'diagnostic_staff' ||
      role == 'lab_technician' ||
      role == 'radiology_staff';
  bool get isAccountOfficer => role == 'account_officer';
  bool get isPharmacist => role == 'pharmacist';
  bool get isAdmissionOfficer => role == 'admission_officer';

  bool get isStaff =>
      isAdmin ||
      isGateOfficer ||
      isRegistrationOfficer ||
      isDoctor ||
      isNurse ||
      isDiagnosticStaff ||
      isAccountOfficer ||
      isPharmacist ||
      isAdmissionOfficer;

  bool canAccess(String feature) {
    switch (feature) {
      case 'admin_dashboard':
        return isAdmin;
      case 'gate_dashboard':
        return isAdmin || isGateOfficer;
      case 'registration_dashboard':
        return isAdmin || isRegistrationOfficer;
      case 'doctor_dashboard':
        return isAdmin || isDoctor;
      case 'patient_write':
        return isAdmin || isGateOfficer || isRegistrationOfficer;
      // Phase 2
      case 'diagnostic_dashboard':
        return isAdmin || isDiagnosticStaff;
      case 'account_dashboard':
        return isAdmin || isAccountOfficer;
      case 'pharmacy_dashboard':
        return isAdmin || isPharmacist;
      case 'admission_dashboard':
        return isAdmin || isAdmissionOfficer;
      case 'patient_portal':
        return isPatient;
      default:
        return false;
    }
  }

  // ── Firestore ──────────────────────────────────────────────────
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: data['uid'] as String? ?? doc.id,
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      role: data['role'] as String? ?? '',
      departmentId: data['departmentId'] as String?,
      roomId: data['roomId'] as String?,
      specialty: data['specialty'] as String?,
      active: data['active'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      patientId: data['patientId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'uid': uid,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'role': role,
        'departmentId': departmentId,
        'roomId': roomId,
        'specialty': specialty,
        'active': active,
        'createdAt': Timestamp.fromDate(createdAt),
        'patientId': patientId,
      };

  UserModel copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? phone,
    String? role,
    String? departmentId,
    String? roomId,
    String? specialty,
    bool? active,
    DateTime? createdAt,
    String? patientId,
  }) =>
      UserModel(
        uid: uid ?? this.uid,
        fullName: fullName ?? this.fullName,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        role: role ?? this.role,
        departmentId: departmentId ?? this.departmentId,
        roomId: roomId ?? this.roomId,
        specialty: specialty ?? this.specialty,
        active: active ?? this.active,
        createdAt: createdAt ?? this.createdAt,
        patientId: patientId ?? this.patientId,
      );

  @override
  String toString() => 'UserModel($uid, $fullName, $role)';
}
