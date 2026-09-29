import '../models/department_model.dart';
import '../models/room_model.dart';
import '../services/firestore/department_firestore_service.dart';

/// Business logic for department and room access.
class DepartmentRepository {
  DepartmentRepository(this._deptService);
  final DepartmentFirestoreService _deptService;

  Future<List<DepartmentModel>> getDepartments() =>
      _deptService.getDepartments();

  Stream<List<DepartmentModel>> streamDepartments() =>
      _deptService.streamDepartments();

  Future<DepartmentModel?> getDepartmentByCode(String code) =>
      _deptService.getDepartmentByCode(code);

  Future<List<RoomModel>> getRooms({String? departmentId}) =>
      _deptService.getRooms(departmentId: departmentId);

  Future<List<RoomModel>> getRoomsForDepartment(String departmentId) =>
      _deptService.getRooms(departmentId: departmentId);
}
