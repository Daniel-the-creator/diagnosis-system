import 'package:cloud_firestore/cloud_firestore.dart';

/// A hospital department stored in Firestore (not hard-coded).
class DepartmentModel {
  final String departmentId;
  final String name;
  final String code;          // Short code used in queue prefix (e.g. 'REG')
  final String? description;
  final bool active;
  final int order;            // Display order
  final DateTime createdAt;

  const DepartmentModel({
    required this.departmentId,
    required this.name,
    required this.code,
    this.description,
    required this.active,
    required this.order,
    required this.createdAt,
  });

  factory DepartmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DepartmentModel(
      departmentId: data['departmentId'] as String? ?? doc.id,
      name: data['name'] as String? ?? '',
      code: data['code'] as String? ?? '',
      description: data['description'] as String?,
      active: data['active'] as bool? ?? true,
      order: data['order'] as int? ?? 0,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'departmentId': departmentId,
        'name': name,
        'code': code,
        'description': description,
        'active': active,
        'order': order,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  DepartmentModel copyWith({
    String? departmentId,
    String? name,
    String? code,
    String? description,
    bool? active,
    int? order,
    DateTime? createdAt,
  }) =>
      DepartmentModel(
        departmentId: departmentId ?? this.departmentId,
        name: name ?? this.name,
        code: code ?? this.code,
        description: description ?? this.description,
        active: active ?? this.active,
        order: order ?? this.order,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  String toString() => 'DepartmentModel($code, $name)';
}
