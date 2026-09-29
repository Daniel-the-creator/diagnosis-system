import 'package:cloud_firestore/cloud_firestore.dart';

/// A physical room or station within the hospital.
class RoomModel {
  final String roomId;
  final String roomName;
  final String roomNumber;
  final String departmentId;
  final String type;     // e.g. 'consultation', 'lab', 'pharmacy', 'office'
  final bool active;
  final DateTime createdAt;

  const RoomModel({
    required this.roomId,
    required this.roomName,
    required this.roomNumber,
    required this.departmentId,
    required this.type,
    required this.active,
    required this.createdAt,
  });

  factory RoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoomModel(
      roomId: data['roomId'] as String? ?? doc.id,
      roomName: data['roomName'] as String? ?? '',
      roomNumber: data['roomNumber'] as String? ?? '',
      departmentId: data['departmentId'] as String? ?? '',
      type: data['type'] as String? ?? 'general',
      active: data['active'] as bool? ?? true,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'roomId': roomId,
        'roomName': roomName,
        'roomNumber': roomNumber,
        'departmentId': departmentId,
        'type': type,
        'active': active,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  @override
  String toString() => 'RoomModel($roomNumber, $roomName)';
}
