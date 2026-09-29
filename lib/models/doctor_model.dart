import 'package:cloud_firestore/cloud_firestore.dart';

/// Professional doctor/consultant profile.
/// Separate from the UserModel auth record to support multiple specialties.
class DoctorModel {
  final String doctorId;
  final String userId;      // Links to users/{uid}
  final String name;
  final String specialty;
  final String departmentId;
  final String? roomId;
  final bool active;
  final DateTime createdAt;

  const DoctorModel({
    required this.doctorId,
    required this.userId,
    required this.name,
    required this.specialty,
    required this.departmentId,
    this.roomId,
    required this.active,
    required this.createdAt,
  });

  factory DoctorModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DoctorModel(
      doctorId: data['doctorId'] as String? ?? doc.id,
      userId: data['userId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      specialty: data['specialty'] as String? ?? '',
      departmentId: data['departmentId'] as String? ?? '',
      roomId: data['roomId'] as String?,
      active: data['active'] as bool? ?? true,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'doctorId': doctorId,
        'userId': userId,
        'name': name,
        'specialty': specialty,
        'departmentId': departmentId,
        'roomId': roomId,
        'active': active,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  DoctorModel copyWith({
    String? doctorId,
    String? userId,
    String? name,
    String? specialty,
    String? departmentId,
    String? roomId,
    bool? active,
    DateTime? createdAt,
  }) =>
      DoctorModel(
        doctorId: doctorId ?? this.doctorId,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        specialty: specialty ?? this.specialty,
        departmentId: departmentId ?? this.departmentId,
        roomId: roomId ?? this.roomId,
        active: active ?? this.active,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  String toString() => 'DoctorModel($doctorId, $name, $specialty)';
}
