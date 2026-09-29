import '../../models/department_model.dart';
import '../../models/room_model.dart';
import '../../models/user_model.dart';
import '../../models/admission_models.dart';
import '../../models/medication_model.dart';
import '../../core/constants/firestore_constants.dart';
import 'department_firestore_service.dart';
import 'firestore_service.dart';

/// Provides optional development seed data.
/// Call [seedAll] once from the admin console to populate Firestore.
/// NOT called automatically on app start.
class SeedService {
  SeedService(this._fs, this._deptService);
  final FirestoreService _fs;
  final DepartmentFirestoreService _deptService;

  Future<void> seedAll() async {
    await seedDepartments();
    await seedRooms();
    await seedWardsAndBeds();
    await seedMedications();
  }

  Future<void> seedDepartments() async {
    final departments = [
      _dept('GATE', 'Gate', 'Entry gate and arrival', 1),
      _dept('REG', 'Registration', 'Patient registration', 2),
      _dept('GEN', 'General Medicine', 'General outpatient medicine', 3),
      _dept('PED', 'Pediatrics', 'Children health services', 4),
      _dept('SUR', 'Surgery', 'Surgical consultations', 5),
      _dept('LAB', 'Laboratory', 'Blood tests and analysis', 6),
      _dept('XR', 'X-Ray', 'Radiography services', 7),
      _dept('SCAN', 'Scan', 'Ultrasound and imaging', 8),
      _dept('ACC', 'Account', 'Billing and accounts', 9),
      _dept('PHM', 'Pharmacy', 'Drug dispensing', 10),
      _dept('ADM', 'Admission', 'In-patient admission', 11),
      _dept('DIS', 'Discharge', 'Patient discharge', 12),
    ];
    for (final dept in departments) {
      final existing = await _deptService.getDepartmentByCode(dept.code);
      if (existing == null) {
        await _deptService.saveDepartment(dept);
      }
    }
  }

  DepartmentModel _dept(
      String code, String name, String desc, int order) {
    final id = _deptService.generateDeptId();
    return DepartmentModel(
      departmentId: id,
      name: name,
      code: code,
      description: desc,
      active: true,
      order: order,
      createdAt: DateTime.now(),
    );
  }

  Future<void> seedRooms() async {
    final depts = await _deptService.getDepartments();
    final deptMap = {for (final d in depts) d.code: d.departmentId};

    final rooms = <RoomModel>[
      if (deptMap['GEN'] != null) ...[
        _room('Consultation Room 101', '101', deptMap['GEN']!, 'consultation'),
        _room('Consultation Room 102', '102', deptMap['GEN']!, 'consultation'),
      ],
      if (deptMap['PED'] != null)
        _room('Paediatrics Room', 'PED-01', deptMap['PED']!, 'consultation'),
      if (deptMap['SUR'] != null)
        _room('Surgery Consultation', 'SUR-01', deptMap['SUR']!, 'consultation'),
      if (deptMap['LAB'] != null)
        _room('Laboratory 1', 'LAB-01', deptMap['LAB']!, 'lab'),
      if (deptMap['XR'] != null)
        _room('X-Ray Room', 'XR-01', deptMap['XR']!, 'xray'),
      if (deptMap['SCAN'] != null)
        _room('Scan Room', 'SCAN-01', deptMap['SCAN']!, 'scan'),
      if (deptMap['PHM'] != null)
        _room('Pharmacy Counter', 'PHM-01', deptMap['PHM']!, 'pharmacy'),
      if (deptMap['ACC'] != null)
        _room('Account Office', 'ACC-01', deptMap['ACC']!, 'office'),
      if (deptMap['REG'] != null)
        _room('Registration Desk', 'REG-01', deptMap['REG']!, 'desk'),
    ];

    for (final room in rooms) {
      await _deptService.saveRoom(room);
    }
  }

  RoomModel _room(
      String name, String number, String deptId, String type) {
    final id = _deptService.generateRoomId();
    return RoomModel(
      roomId: id,
      roomName: name,
      roomNumber: number,
      departmentId: deptId,
      type: type,
      active: true,
      createdAt: DateTime.now(),
    );
  }

  /// Seeds hospital wards and their associated beds for Phase 2 admissions.
  Future<void> seedWardsAndBeds() async {
    final wardsData = [
      {'name': 'Male Medical Ward', 'type': 'General', 'beds': 6, 'prefix': 'M'},
      {'name': 'Female Medical Ward', 'type': 'General', 'beds': 6, 'prefix': 'F'},
      {'name': 'Paediatric Ward', 'type': 'Paediatric', 'beds': 4, 'prefix': 'PED'},
      {'name': 'Intensive Care Unit', 'type': 'ICU', 'beds': 2, 'prefix': 'ICU'},
    ];

    for (final w in wardsData) {
      final wardId = 'ward_${(w['name'] as String).toLowerCase().replaceAll(' ', '_')}';
      final ward = WardModel(
        wardId: wardId,
        name: w['name'] as String,
        type: w['type'] as String,
        capacity: w['beds'] as int,
        active: true,
        createdAt: DateTime.now(),
      );
      await _fs.setDoc(FirestoreConstants.wardsCollection, wardId, ward.toFirestore());

      final bedCount = w['beds'] as int;
      final prefix = w['prefix'] as String;
      for (int b = 1; b <= bedCount; b++) {
        final bedNum = '$prefix-${b.toString().padLeft(2, '0')}';
        final bedId = 'bed_${wardId}_$b';
        final bed = BedModel(
          bedId: bedId,
          wardId: wardId,
          wardName: w['name'] as String,
          bedNumber: bedNum,
          status: 'AVAILABLE',
        );
        await _fs.setDoc(FirestoreConstants.bedsCollection, bedId, bed.toFirestore());
      }
    }
  }

  /// Seeds sample pharmacy drug inventory for dispensing validation and stock alerts.
  Future<void> seedMedications() async {
    final drugs = [
      {
        'id': 'med_paracetamol',
        'name': 'Paracetamol 500mg',
        'generic': 'Acetaminophen',
        'category': 'Analgesics',
        'qty': 250,
        'price': 5.0,
        'batch': 'BAT-PC-01',
      },
      {
        'id': 'med_amoxicillin',
        'name': 'Amoxicillin 500mg',
        'generic': 'Amoxicillin Trihydrate',
        'category': 'Antibiotics',
        'qty': 150,
        'price': 15.0,
        'batch': 'BAT-AMX-02',
      },
      {
        'id': 'med_ibuprofen',
        'name': 'Ibuprofen 400mg',
        'generic': 'Ibuprofen',
        'category': 'Anti-inflammatory',
        'qty': 120,
        'price': 8.5,
        'batch': 'BAT-IBU-03',
      },
      {
        'id': 'med_omeprazole',
        'name': 'Omeprazole 20mg',
        'generic': 'Omeprazole',
        'category': 'Gastrointestinal',
        'qty': 90,
        'price': 12.0,
        'batch': 'BAT-OMP-04',
      },
      {
        'id': 'med_metformin',
        'name': 'Metformin 500mg',
        'generic': 'Metformin Hydrochloride',
        'category': 'Antidiabetic',
        'qty': 110,
        'price': 9.0,
        'batch': 'BAT-MET-05',
      },
      {
        'id': 'med_amlodipine',
        'name': 'Amlodipine 5mg',
        'generic': 'Amlodipine Besylate',
        'category': 'Antihypertensive',
        'qty': 80,
        'price': 14.0,
        'batch': 'BAT-AML-06',
      },
      {
        'id': 'med_cetirizine',
        'name': 'Cetirizine 10mg',
        'generic': 'Cetirizine Dihydrochloride',
        'category': 'Antihistamines',
        'qty': 18, // Low stock demo!
        'price': 6.0,
        'batch': 'BAT-CET-07',
      },
    ];

    for (final d in drugs) {
      final med = MedicationModel(
        medicationId: d['id'] as String,
        drugName: d['name'] as String,
        genericName: d['generic'] as String,
        category: d['category'] as String,
        batchNumber: d['batch'] as String,
        quantity: d['qty'] as int,
        unitPrice: (d['price'] as num).toDouble(),
        expiryDate: DateTime.now().add(const Duration(days: 365)),
        minimumStockLevel: 25,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _fs.setDoc(FirestoreConstants.medicationsCollection, med.medicationId, med.toFirestore());
    }
  }

  /// Creates a demo staff user document (after Firebase Auth account exists).
  Future<void> seedStaffUser({
    required String uid,
    required String fullName,
    required String email,
    required String phone,
    required String role,
    String? departmentId,
  }) async {
    final user = UserModel(
      uid: uid,
      fullName: fullName,
      email: email,
      phone: phone,
      role: role,
      departmentId: departmentId,
      active: true,
      createdAt: DateTime.now(),
    );
    await _fs.setDoc('users', uid, user.toFirestore());
  }
}
