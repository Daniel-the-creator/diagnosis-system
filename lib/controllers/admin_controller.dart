import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/queue_item_model.dart';
import '../models/visit_model.dart';
import '../models/invoice_model.dart';
import '../models/diagnostic_request_model.dart';
import '../models/prescription_model.dart';
import '../models/medication_model.dart';
import '../models/admission_models.dart';
import '../models/staff_schedule_model.dart';
import '../models/audit_log_model.dart';
import '../models/system_settings_model.dart';

import '../repositories/auth_repository.dart';
import '../repositories/audit_repository.dart';
import '../repositories/staff_schedule_repository.dart';
import '../repositories/system_settings_repository.dart';
import '../services/analytics/analytics_service.dart';
import '../services/reports/report_export_service.dart';

/// Comprehensive controller managing hospital-wide real-time operations,
/// queue KPIs, department monitoring, analytics, staff scheduling, audit trails, and settings.
class AdminController extends GetxController {
  AdminController(
    this._db, {
    AuthRepository? authRepo,
    AuditRepository? auditRepo,
    StaffScheduleRepository? scheduleRepo,
    SystemSettingsRepository? settingsRepo,
    AnalyticsService? analyticsService,
    ReportExportService? reportService,
  })  : _authRepo = authRepo ?? (Get.isRegistered<AuthRepository>() ? Get.find<AuthRepository>() : null),
        _auditRepo = auditRepo ?? (Get.isRegistered<AuditRepository>() ? Get.find<AuditRepository>() : null),
        _scheduleRepo = scheduleRepo ?? (Get.isRegistered<StaffScheduleRepository>() ? Get.find<StaffScheduleRepository>() : null),
        _settingsRepo = settingsRepo ?? (Get.isRegistered<SystemSettingsRepository>() ? Get.find<SystemSettingsRepository>() : null),
        _analytics = analyticsService ?? AnalyticsService(),
        _reports = reportService ?? ReportExportService();

  final FirebaseFirestore _db;
  final AuthRepository? _authRepo;
  final AuditRepository? _auditRepo;
  final StaffScheduleRepository? _scheduleRepo;
  final SystemSettingsRepository? _settingsRepo;
  final AnalyticsService _analytics;
  final ReportExportService _reports;

  // ── Tab Navigation ─────────────────────────────────────────────
  final RxInt selectedTab = 0.obs;

  // ── 1. Real-time Operations Overview KPIs ──────────────────────
  final RxInt totalPatientsToday = 0.obs;
  final RxInt regularPatients = 0.obs;
  final RxInt emergencyPatients = 0.obs;
  final RxInt waitingPatients = 0.obs;
  final RxInt inProgressPatients = 0.obs;
  final RxInt completedVisits = 0.obs;
  final RxInt activeAdmissions = 0.obs;
  final RxInt dischargesToday = 0.obs;
  final RxInt pendingDiagnostics = 0.obs;
  final RxInt pendingPayments = 0.obs;
  final RxInt pharmacyQueue = 0.obs;
  final RxInt availableBeds = 0.obs;

  // ── 2. Department Queue Monitoring ─────────────────────────────
  final RxMap<String, DepartmentQueueStats> departmentStats =
      <String, DepartmentQueueStats>{}.obs;

  // ── 3. Analytics Filters & Datasets ────────────────────────────
  final RxString selectedDateFilter = 'Today'.obs;
  DateTimeRange? customRange;

  final Rx<WaitingTimeBreakdown?> waitingBreakdown = Rx(null);
  final Rx<VolumeAnalyticsData?> volumeData = Rx(null);
  final Rx<DiagnosticAnalyticsData?> diagnosticData = Rx(null);
  final Rx<PharmacyAnalyticsData?> pharmacyData = Rx(null);
  final Rx<FinancialAnalyticsData?> financialData = Rx(null);
  final Rx<AdmissionAnalyticsData?> admissionData = Rx(null);

  // ── 4. Staff Management ────────────────────────────────────────
  final RxList<UserModel> allStaff = <UserModel>[].obs;
  final RxList<UserModel> pendingStaff = <UserModel>[].obs;

  // ── 5. Staff Scheduling ────────────────────────────────────────
  final RxList<StaffScheduleModel> schedules = <StaffScheduleModel>[].obs;

  // ── 6. Audit Logs ──────────────────────────────────────────────
  final RxString selectedAuditModule = 'ALL'.obs;
  final RxList<AuditLogModel> auditLogs = <AuditLogModel>[].obs;

  // ── 7. System Settings ─────────────────────────────────────────
  final Rx<SystemSettingsModel> systemSettings =
      Rx<SystemSettingsModel>(SystemSettingsModel.defaultSettings());

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final List<dynamic> _subs = [];

  // Cached collections for analytics computation
  List<VisitModel> _cachedVisits = [];
  List<QueueItemModel> _cachedQueueItems = [];
  List<DiagnosticRequestModel> _cachedDiagRequests = [];
  List<PrescriptionModel> _cachedPrescriptions = [];
  List<MedicationModel> _cachedMedications = [];
  List<InvoiceModel> _cachedInvoices = [];
  List<AdmissionRequestModel> _cachedAdmissions = [];
  List<BedModel> _cachedBeds = [];
  List<WardModel> _cachedWards = [];

  @override
  void onInit() {
    super.onInit();
    _streamRealtimeOperations();
    _streamStaff();
    _streamSchedules();
    _streamAuditLogs();
    _streamSettings();
  }

  @override
  void onClose() {
    for (final s in _subs) {
      try {
        s.cancel();
      } catch (_) {}
    }
    _subs.clear();
    super.onClose();
  }

  // ── Real-time KPI and Department Queue Listeners ───────────────
  void _streamRealtimeOperations() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    // 1. Visits Today
    _subs.add(
      _db
          .collection('visits')
          .where('visitDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .snapshots()
          .listen((snap) {
        _cachedVisits = snap.docs.map(VisitModel.fromFirestore).toList();
        totalPatientsToday.value = _cachedVisits.length;
        regularPatients.value =
            _cachedVisits.where((v) => v.patientType == 'REGULAR').length;
        emergencyPatients.value = _cachedVisits
            .where((v) =>
                v.priority.level == 'EMERGENCY' ||
                v.priority.level == 'CRITICAL_EMERGENCY')
            .length;
        completedVisits.value = _cachedVisits.where((v) => v.completed).length;
        _recomputeAnalytics();
      }),
    );

    // 2. Queue Items
    _subs.add(
      _db
          .collection('queue_items')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .snapshots()
          .listen((snap) {
        _cachedQueueItems =
            snap.docs.map(QueueItemModel.fromFirestore).toList();
        waitingPatients.value = _cachedQueueItems
            .where((i) => i.status == QueueStatus.waiting)
            .length;
        inProgressPatients.value = _cachedQueueItems
            .where((i) =>
                i.status == QueueStatus.inProgress ||
                i.status == QueueStatus.called)
            .length;

        // Department Queue Monitoring Breakdown for all 9 departments
        _updateDepartmentQueueMetrics();
        _recomputeAnalytics();
      }),
    );

    // 3. Diagnostic Requests
    _subs.add(
      _db.collection('diagnostic_requests').snapshots().listen((snap) {
        _cachedDiagRequests =
            snap.docs.map(DiagnosticRequestModel.fromFirestore).toList();
        pendingDiagnostics.value = _cachedDiagRequests
            .where((r) =>
                r.status == 'REQUESTED' ||
                r.status == 'WAITING' ||
                r.status == 'IN_PROGRESS')
            .length;
        _recomputeAnalytics();
      }),
    );

    // 4. Invoices & Billing
    _subs.add(
      _db.collection('invoices').snapshots().listen((snap) {
        _cachedInvoices = snap.docs.map(InvoiceModel.fromFirestore).toList();
        pendingPayments.value = _cachedInvoices
            .where((inv) =>
                inv.status == 'PENDING' || inv.status == 'PARTIALLY_PAID')
            .length;
        _recomputeAnalytics();
      }),
    );

    // 5. Prescriptions
    _subs.add(
      _db.collection('prescriptions').snapshots().listen((snap) {
        _cachedPrescriptions =
            snap.docs.map(PrescriptionModel.fromFirestore).toList();
        pharmacyQueue.value = _cachedPrescriptions
            .where((p) =>
                p.status == 'PENDING' || p.status == 'PARTIALLY_DISPENSED')
            .length;
        _recomputeAnalytics();
      }),
    );

    // 6. Medications (Inventory)
    _subs.add(
      _db.collection('medications').snapshots().listen((snap) {
        _cachedMedications =
            snap.docs.map(MedicationModel.fromFirestore).toList();
        _recomputeAnalytics();
      }),
    );

    // 7. Admissions
    _subs.add(
      _db.collection('admissions').snapshots().listen((snap) {
        _cachedAdmissions =
            snap.docs.map(AdmissionRequestModel.fromFirestore).toList();
        activeAdmissions.value = _cachedAdmissions
            .where((a) => a.status == 'ADMITTED')
            .length;
        dischargesToday.value = _cachedAdmissions
            .where((a) =>
                a.status == 'DISCHARGED' &&
                a.dischargedAt != null &&
                a.dischargedAt!.isAfter(startOfDay))
            .length;
        _recomputeAnalytics();
      }),
    );

    // 8. Beds & Wards
    _subs.add(
      _db.collection('beds').snapshots().listen((snap) {
        _cachedBeds = snap.docs.map(BedModel.fromFirestore).toList();
        availableBeds.value =
            _cachedBeds.where((b) => b.status == 'AVAILABLE').length;
        _recomputeAnalytics();
      }),
    );

    _subs.add(
      _db.collection('wards').snapshots().listen((snap) {
        _cachedWards = snap.docs.map(WardModel.fromFirestore).toList();
        _recomputeAnalytics();
      }),
    );
  }

  void _updateDepartmentQueueMetrics() {
    final depts = [
      ('REG', 'Registration'),
      ('DOC', 'Doctors OPD'),
      ('LAB', 'Laboratory'),
      ('XR', 'X-Ray'),
      ('SCAN', 'Ultrasound & Scan'),
      ('ACC', 'Billing & Cashier'),
      ('PHM', 'Pharmacy'),
      ('ADM', 'Admissions'),
      ('DIS', 'Discharge Unit'),
    ];

    final updated = <String, DepartmentQueueStats>{};
    for (final (code, name) in depts) {
      updated[code] = _analytics.computeDepartmentStats(
        deptCode: code,
        deptName: name,
        items: _cachedQueueItems,
      );
    }
    departmentStats.assignAll(updated);
  }

  void _recomputeAnalytics() {
    waitingBreakdown.value = _analytics.computeWaitingTimeBreakdown(
      allQueueItems: _cachedQueueItems,
      completedVisits: _cachedVisits,
    );

    volumeData.value = _analytics.computeVolumeAnalytics(
      visits: _cachedVisits,
      diagnosticCount: _cachedDiagRequests.length,
      admissionCount: activeAdmissions.value,
      dischargeCount: dischargesToday.value,
    );

    diagnosticData.value =
        _analytics.computeDiagnosticAnalytics(_cachedDiagRequests);

    double pharmacyRev = 0;
    for (final inv in _cachedInvoices) {
      for (final it in inv.items) {
        if (it.category.toUpperCase() == 'MEDICATION') {
          pharmacyRev += it.total;
        }
      }
    }

    pharmacyData.value = _analytics.computePharmacyAnalytics(
      prescriptions: _cachedPrescriptions,
      medications: _cachedMedications,
      pharmacyRevenue: pharmacyRev,
    );

    financialData.value =
        _analytics.computeFinancialAnalytics(_cachedInvoices);

    admissionData.value = _analytics.computeAdmissionAnalytics(
      admissions: _cachedAdmissions,
      beds: _cachedBeds,
      wards: _cachedWards,
    );
  }

  // ── Staff Management ───────────────────────────────────────────
  void _streamStaff() {
    if (_authRepo == null) return;
    _subs.add(
      _authRepo.streamAllStaff().listen((staffList) {
        allStaff.assignAll(staffList);
      }),
    );
    _subs.add(
      _authRepo.streamPendingUsers().listen((pendingList) {
        pendingStaff.assignAll(pendingList);
      }),
    );
  }

  Future<void> approveStaff(String uid) async {
    try {
      await _authRepo?.activateUser(uid);
      _logAudit(
        action: 'STAFF_ACTIVATED',
        module: 'STAFF',
        recordId: uid,
        details: 'Staff member account activated',
      );
      Get.snackbar('Approved', 'Staff member account activated successfully.',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      errorMessage.value = 'Failed to activate staff member.';
    }
  }

  Future<void> rejectStaff(String uid) async {
    try {
      await _authRepo?.rejectUser(uid);
      _logAudit(
        action: 'STAFF_REJECTED',
        module: 'STAFF',
        recordId: uid,
        details: 'Staff registration request rejected',
      );
      Get.snackbar('Rejected', 'Staff request was dismissed.',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      errorMessage.value = 'Failed to reject staff member.';
    }
  }

  Future<void> toggleStaffStatus(UserModel staff) async {
    try {
      if (staff.active) {
        await _authRepo?.deactivateUser(staff.uid);
      } else {
        await _authRepo?.activateUser(staff.uid);
      }
      _logAudit(
        action: staff.active ? 'STAFF_DEACTIVATED' : 'STAFF_ACTIVATED',
        module: 'STAFF',
        recordId: staff.uid,
        details: 'Staff ${staff.fullName} status toggled',
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to update staff status.');
    }
  }

  Future<void> updateStaffProfile({
    required String uid,
    required String fullName,
    required String role,
    String? departmentId,
    String? roomId,
    String? specialty,
  }) async {
    try {
      await _authRepo?.updateUser(uid, {
        'fullName': fullName,
        'role': role,
        'departmentId': departmentId,
        'roomId': roomId,
        'specialty': specialty,
      });
      _logAudit(
        action: 'STAFF_UPDATED',
        module: 'STAFF',
        recordId: uid,
        details: 'Staff profile updated ($role, Dept: $departmentId)',
      );
      Get.snackbar('Success', 'Staff member profile updated.');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update staff profile.');
    }
  }

  // ── Staff Scheduling ───────────────────────────────────────────
  void _streamSchedules() {
    if (_scheduleRepo == null) return;
    _subs.add(
      _scheduleRepo.streamUpcomingSchedules().listen((s) {
        schedules.assignAll(s);
      }),
    );
  }

  Future<bool> createSchedule({
    required UserModel staff,
    required DateTime date,
    required String startTime,
    required String endTime,
    String? roomId,
    String? roomName,
  }) async {
    if (_scheduleRepo == null) return false;
    try {
      final id = _scheduleRepo.generateScheduleId();
      final schedule = StaffScheduleModel(
        scheduleId: id,
        staffId: staff.uid,
        staffName: staff.fullName,
        role: staff.role,
        departmentCode: staff.departmentId ?? 'GEN',
        departmentName: staff.departmentId ?? 'General',
        date: date,
        startTime: startTime,
        endTime: endTime,
        roomId: roomId,
        roomName: roomName,
        status: 'ACTIVE',
        createdAt: DateTime.now(),
      );

      await _scheduleRepo.createSchedule(schedule);

      _logAudit(
        action: 'STAFF_SCHEDULED',
        module: 'STAFF',
        recordId: id,
        details:
            'Shift assigned to ${staff.fullName} on ${date.toIso8601String().substring(0, 10)} ($startTime - $endTime)',
      );

      Get.snackbar('Schedule Created', 'Duty roster updated successfully.',
          snackPosition: SnackPosition.BOTTOM);
      return true;
    } catch (e) {
      Get.dialog(
        AlertDialog(
          title: const Text('Scheduling Conflict',
              style: TextStyle(color: Colors.red)),
          content: Text(e.toString().replaceAll('Exception: ', '')),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return false;
    }
  }

  Future<void> cancelSchedule(String scheduleId) async {
    try {
      await _scheduleRepo?.cancelSchedule(scheduleId);
      _logAudit(
        action: 'SCHEDULE_CANCELLED',
        module: 'STAFF',
        recordId: scheduleId,
        details: 'Duty schedule cancelled',
      );
    } catch (_) {}
  }

  // ── Audit Logs ─────────────────────────────────────────────────
  void _streamAuditLogs() {
    if (_auditRepo == null) return;
    _subs.add(
      _auditRepo
          .streamLogs(module: selectedAuditModule.value)
          .listen((logs) {
        auditLogs.assignAll(logs);
      }),
    );
  }

  void filterAuditLogs(String module) {
    selectedAuditModule.value = module;
    _streamAuditLogs();
  }

  void _logAudit({
    required String action,
    required String module,
    required String recordId,
    String? details,
  }) {
    final currentUid = _authRepo?.isSignedIn == true ? 'admin-user' : 'system';
    _auditRepo?.log(
      userId: currentUid,
      userName: 'Administrator',
      role: 'hospital_admin',
      action: action,
      module: module,
      recordId: recordId,
      details: details,
    );
  }

  // ── System Settings ────────────────────────────────────────────
  void _streamSettings() {
    if (_settingsRepo == null) return;
    _subs.add(
      _settingsRepo.streamSettings().listen((settings) {
        systemSettings.value = settings;
      }),
    );
  }

  Future<void> updateSettings(SystemSettingsModel updated) async {
    try {
      await _settingsRepo?.updateSettings(updated);
      _logAudit(
        action: 'SETTINGS_UPDATED',
        module: 'SETTINGS',
        recordId: 'general',
        details: 'Hospital administrative settings updated',
      );
      Get.snackbar('Settings Saved', 'System preferences updated successfully.',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update system settings.');
    }
  }

  // ── Report Generation & Export ─────────────────────────────────
  String exportReport(ReportType type) {
    switch (type) {
      case ReportType.dailyPatients:
        return _reports.generateDailyPatientReport(
          visits: _cachedVisits,
          startDate: DateTime.now().subtract(const Duration(days: 1)),
          endDate: DateTime.now(),
        );
      case ReportType.departmentPerformance:
        final metrics = <String, Map<String, dynamic>>{};
        for (final entry in departmentStats.entries) {
          metrics[entry.key] = {
            'name': entry.value.departmentName,
            'completed': entry.value.completedCount,
            'waiting': entry.value.waitingCount,
            'inService': entry.value.inServiceCount,
            'avgWait': entry.value.avgWaitingMinutes.toString(),
            'avgService': entry.value.avgServiceMinutes.toString(),
          };
        }
        return _reports.generateDepartmentPerformanceReport(deptMetrics: metrics);
      case ReportType.queuePerformance:
        return _reports.generateQueuePerformanceReport(items: _cachedQueueItems);
      case ReportType.diagnostics:
        return _reports.generateDiagnosticReport(requests: _cachedDiagRequests);
      case ReportType.pharmacy:
        return _reports.generatePharmacyReport(prescriptions: _cachedPrescriptions);
      case ReportType.admissions:
        return _reports.generateAdmissionReport(admissions: _cachedAdmissions);
      case ReportType.discharges:
        return _reports.generateDischargeReport(dischargedList: _cachedAdmissions);
      case ReportType.revenue:
        return _reports.generateRevenueReport(invoices: _cachedInvoices);
      case ReportType.staffPerformance:
        return _reports.generateStaffPerformanceReport(
          staffList: allStaff,
          queueItems: _cachedQueueItems,
        );
    }
  }
}
