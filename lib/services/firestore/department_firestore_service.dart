import '../../core/constants/firestore_constants.dart';
import '../../models/department_model.dart';
import '../../models/room_model.dart';
import 'firestore_service.dart';

/// Firestore operations for [departments] and [rooms] collections.
class DepartmentFirestoreService {
  DepartmentFirestoreService(this._fs);
  final FirestoreService _fs;

  static const String _deptCol = FirestoreConstants.departmentsCollection;
  static const String _roomCol = FirestoreConstants.roomsCollection;

  // ── Departments ────────────────────────────────────────────────

  Future<void> saveDepartment(DepartmentModel dept) =>
      _fs.setDoc(_deptCol, dept.departmentId, dept.toFirestore());

  Future<List<DepartmentModel>> getDepartments({bool activeOnly = true}) async {
    var query = _fs.db.collection(_deptCol).orderBy('order');
    if (activeOnly) {
      query = query.where('active', isEqualTo: true) as dynamic;
    }
    final snap = await _fs.db
        .collection(_deptCol)
        .where('active', isEqualTo: activeOnly ? true : null)
        .orderBy('order')
        .get();
    return snap.docs.map(DepartmentModel.fromFirestore).toList();
  }

  Stream<List<DepartmentModel>> streamDepartments() =>
      _fs.db
          .collection(_deptCol)
          .where('active', isEqualTo: true)
          .orderBy('order')
          .snapshots()
          .map((s) => s.docs.map(DepartmentModel.fromFirestore).toList());

  Future<DepartmentModel?> getDepartmentByCode(String code) async {
    final snap = await _fs.db
        .collection(_deptCol)
        .where('code', isEqualTo: code)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return DepartmentModel.fromFirestore(snap.docs.first);
  }

  // ── Rooms ──────────────────────────────────────────────────────

  Future<void> saveRoom(RoomModel room) =>
      _fs.setDoc(_roomCol, room.roomId, room.toFirestore());

  Future<List<RoomModel>> getRooms({String? departmentId}) async {
    var query = _fs.db.collection(_roomCol).where('active', isEqualTo: true);
    if (departmentId != null) {
      query = query.where('departmentId', isEqualTo: departmentId);
    }
    final snap = await query.get();
    return snap.docs.map(RoomModel.fromFirestore).toList();
  }

  String generateDeptId() => _fs.generateId(_deptCol);
  String generateRoomId() => _fs.generateId(_roomCol);
}
