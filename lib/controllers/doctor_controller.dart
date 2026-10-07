import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/patient_model.dart';
import '../models/visit_model.dart';
import '../models/queue_item_model.dart';
import '../models/consultation_model.dart';
import '../models/diagnostic_request_model.dart';
import '../models/diagnostic_result_model.dart';
import '../models/prescription_model.dart';
import '../models/admission_models.dart';
import '../models/invoice_model.dart';
import '../models/appointment_model.dart';
import '../repositories/patient_repository.dart';
import '../repositories/queue_repository.dart';
import '../repositories/visit_repository.dart';
import '../repositories/consultation_repository.dart';
import '../repositories/diagnostic_repository.dart';
import '../repositories/pharmacy_repository.dart';
import '../repositories/admission_repository.dart';
import '../repositories/billing_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/appointment_repository.dart';
import '../controllers/auth_controller.dart';
import '../core/errors/firebase_error_handler.dart';
import '../services/audio/audio_announcement_service.dart';
import '../core/theme/app_colors.dart';

/// Temporary holder for a diagnostic test being ordered during consultation.
class PendingDiagnosticItem {
  final String diagnosticType; // 'LAB' | 'XR' | 'SCAN'
  final String testName;
  final String priority;
  final String instructions;
  final double fee;

  PendingDiagnosticItem({
    required this.diagnosticType,
    required this.testName,
    this.priority = 'ROUTINE',
    this.instructions = '',
    this.fee = 50.0,
  });
}

/// Temporary holder for a prescription item being written during consultation.
class PendingPrescriptionItem {
  final String medicationName;
  final String dosage;
  final String frequency;
  final String duration;
  final int quantity;
  final String instructions;
  final double estimatedFee;

  PendingPrescriptionItem({
    required this.medicationName,
    required this.dosage,
    required this.frequency,
    required this.duration,
    required this.quantity,
    this.instructions = '',
    this.estimatedFee = 15.0,
  });
}

/// Controller for the Doctor dashboard and in-depth clinical consultation.
class DoctorController extends GetxController {
  DoctorController(
    this._patientRepo,
    this._queueRepo,
    this._visitRepo, {
    ConsultationRepository? consultationRepo,
    DiagnosticRepository? diagnosticRepo,
    PharmacyRepository? pharmacyRepo,
    AdmissionRepository? admissionRepo,
    BillingRepository? billingRepo,
    NotificationRepository? notificationRepo,
    AppointmentRepository? appointmentRepo,
  })  : _consultationRepo = consultationRepo ??
            (Get.isRegistered<ConsultationRepository>()
                ? Get.find<ConsultationRepository>()
                : null),
        _diagnosticRepo = diagnosticRepo ??
            (Get.isRegistered<DiagnosticRepository>()
                ? Get.find<DiagnosticRepository>()
                : null),
        _pharmacyRepo = pharmacyRepo ??
            (Get.isRegistered<PharmacyRepository>()
                ? Get.find<PharmacyRepository>()
                : null),
        _admissionRepo = admissionRepo ??
            (Get.isRegistered<AdmissionRepository>()
                ? Get.find<AdmissionRepository>()
                : null),
        _billingRepo = billingRepo ??
            (Get.isRegistered<BillingRepository>()
                ? Get.find<BillingRepository>()
                : null),
        _notificationRepo = notificationRepo ??
            (Get.isRegistered<NotificationRepository>()
                ? Get.find<NotificationRepository>()
                : null),
        _aptRepo = appointmentRepo ??
            (Get.isRegistered<AppointmentRepository>()
                ? Get.find<AppointmentRepository>()
                : null);

  final PatientRepository _patientRepo;
  final QueueRepository _queueRepo;
  final VisitRepository _visitRepo;
  final ConsultationRepository? _consultationRepo;
  final DiagnosticRepository? _diagnosticRepo;
  final PharmacyRepository? _pharmacyRepo;
  final AdmissionRepository? _admissionRepo;
  final BillingRepository? _billingRepo;
  final NotificationRepository? _notificationRepo;
  final AppointmentRepository? _aptRepo;

  // Appointments for this doctor
  final RxList<AppointmentModel> todayAppointments = <AppointmentModel>[].obs;
  final RxList<AppointmentModel> allAppointments = <AppointmentModel>[].obs;
  String _doctorId = '';
  final List<StreamSubscription> _aptSubscriptions = [];

  final RxList<QueueItemModel> doctorQueue = <QueueItemModel>[].obs;
  final Rx<QueueItemModel?> currentlyServing = Rx<QueueItemModel?>(null);
  final Rx<PatientModel?> currentPatient = Rx<PatientModel?>(null);
  final Rx<VisitModel?> currentVisit = Rx<VisitModel?>(null);

  // Clinical Consultation State
  final RxString symptoms = ''.obs;
  final RxString observations = ''.obs;
  final RxMap<String, dynamic> vitals = <String, dynamic>{
    'bloodPressure': '',
    'pulseRate': '',
    'temperature': '',
    'weight': '',
    'oxygenSaturation': '',
  }.obs;
  final RxString diagnosis = ''.obs;
  final RxString clinicalNotes = ''.obs;
  final RxString treatmentPlan = ''.obs;

  // Order lists for active consultation
  final RxList<PendingDiagnosticItem> pendingDiagnostics =
      <PendingDiagnosticItem>[].obs;
  final RxList<PendingPrescriptionItem> pendingPrescriptions =
      <PendingPrescriptionItem>[].obs;
  final RxBool admissionRequested = false.obs;
  final RxString admissionReason = ''.obs;
  final RxString admissionPriority = 'ROUTINE'.obs;
  final RxBool dischargeRecommended = false.obs;
  final RxString dischargeSummary = ''.obs;

  // Patient past consultations & test results for review
  final RxList<ConsultationModel> patientConsultations =
      <ConsultationModel>[].obs;
  final RxList<DiagnosticResultModel> visitDiagnosticResults =
      <DiagnosticResultModel>[].obs;

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  final RxString currentDeptCode = 'GEN'.obs;
  StreamSubscription? _queueSub;

  void setDepartmentCode(String code) {
    currentDeptCode.value = code;
    _setupStreams();
  }

  final RxBool isAdmin = false.obs;
  final RxBool isAppointmentsLoading = false.obs;

  String get doctorId => _doctorId;

  /// Call this once the doctor's UID is known (from AuthController in the view).
  void setDoctorId(String doctorId,
      {bool isAdmin = false, bool force = false}) {
    final wasAdmin = this.isAdmin.value;
    this.isAdmin.value = isAdmin;
    if (this.isAdmin.value && !wasAdmin) {
      currentDeptCode.value = 'ALL';
      _setupStreams();
    }
    if (_doctorId == doctorId &&
        !this.isAdmin.value &&
        !force &&
        _aptSubscriptions.isNotEmpty) return;
    _doctorId = doctorId;
    _setupAppointmentStream();
    if (doctorQueue.isNotEmpty) {
      currentlyServing.value = doctorQueue
          .where((i) =>
              i.status == QueueStatus.inProgress &&
              (_doctorId.isEmpty ||
                  this.isAdmin.value ||
                  i.assignedStaffId == _doctorId))
          .firstOrNull;
    }
  }

  void _setupStreams() {
    _queueSub?.cancel();
    _queueSub =
        _queueRepo.streamActiveQueue(currentDeptCode.value).listen((items) {
      doctorQueue.assignAll(items);
      currentlyServing.value = items
          .where((i) =>
              i.status == QueueStatus.inProgress &&
              (_doctorId.isEmpty ||
                  isAdmin.value ||
                  i.assignedStaffId == _doctorId))
          .firstOrNull;
    });
  }

  void refreshAppointments() {
    if (errorMessage.value.contains('appointments')) {
      errorMessage.value = '';
    }
    _setupAppointmentStream();
  }

  void _setupAppointmentStream() {
    if (_aptRepo == null) return;
    for (final s in _aptSubscriptions) {
      s.cancel();
    }
    _aptSubscriptions.clear();
    isAppointmentsLoading.value = true;

    final Stream<List<AppointmentModel>> stream = isAdmin.value
        ? _aptRepo.streamAllAppointments()
        : (_doctorId.isNotEmpty
            ? _aptRepo.streamDoctorAppointments(_doctorId)
            : Stream.value([]));

    _aptSubscriptions.add(
      stream.listen(
        (apts) {
          isAppointmentsLoading.value = false;
          if (errorMessage.value.contains('appointments')) {
            errorMessage.value = '';
          }
          allAppointments.assignAll(apts);
          final today = DateTime.now();
          todayAppointments.assignAll(
            apts.where((a) {
              return a.date.year == today.year &&
                  a.date.month == today.month &&
                  a.date.day == today.day &&
                  a.status != 'CANCELLED';
            }).toList(),
          );
        },
        onError: (e) {
          isAppointmentsLoading.value = false;
          errorMessage.value =
              'Doctor appointments stream error: ${e.toString()}';
        },
      ),
    );
  }

  Future<void> confirmAppointment(String appointmentId) async {
    // Immediate optimistic update
    final allIdx =
        allAppointments.indexWhere((a) => a.appointmentId == appointmentId);
    if (allIdx != -1) {
      allAppointments[allIdx] =
          allAppointments[allIdx].copyWith(status: 'CONFIRMED');
      allAppointments.refresh();
    }
    final todayIdx =
        todayAppointments.indexWhere((a) => a.appointmentId == appointmentId);
    if (todayIdx != -1) {
      todayAppointments[todayIdx] =
          todayAppointments[todayIdx].copyWith(status: 'CONFIRMED');
      todayAppointments.refresh();
    }

    try {
      await _aptRepo?.updateAppointment(appointmentId, {'status': 'CONFIRMED'});
      Get.snackbar(
          'Appointment Confirmed', 'The appointment has been confirmed.',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
    }
  }

  Future<void> cancelAppointmentByDoctor(String appointmentId) async {
    // Immediate optimistic update
    final allIdx =
        allAppointments.indexWhere((a) => a.appointmentId == appointmentId);
    if (allIdx != -1) {
      allAppointments[allIdx] =
          allAppointments[allIdx].copyWith(status: 'CANCELLED');
      allAppointments.refresh();
    }
    todayAppointments.removeWhere((a) => a.appointmentId == appointmentId);
    todayAppointments.refresh();

    try {
      await _aptRepo?.cancelAppointment(appointmentId,
          reason: 'Cancelled by doctor');
      Get.snackbar(
          'Appointment Cancelled', 'The appointment has been cancelled.',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
    }
  }

  @override
  void onInit() {
    super.onInit();
    _setupStreams();
    // Auto-bind to logged-in user and detect admin role
    try {
      if (Get.isRegistered<AuthController>()) {
        final auth = Get.find<AuthController>();
        final user = auth.user;
        final isAdmin = auth.isAdmin || (user?.isAdmin ?? false);
        final uid = user?.uid ?? '';
        if (uid.isNotEmpty || isAdmin) {
          setDoctorId(uid, isAdmin: isAdmin);
        }
      }
    } catch (_) {}
  }

  @override
  void onClose() {
    _queueSub?.cancel();
    for (final s in _aptSubscriptions) {
      s.cancel();
    }
    _aptSubscriptions.clear();
    super.onClose();
  }

  Future<void> callNextPatient([String? staffId]) async {
    final effectiveStaffId = (staffId != null && staffId.isNotEmpty)
        ? staffId
        : (_doctorId.isNotEmpty ? _doctorId : 'doctor');

    if (currentlyServing.value != null) {
      Get.snackbar(
        'Cannot Call Next',
        'Please complete the current consultation first.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;
    try {
      QueueItemModel? itemToCall;

      // 1. Direct check from reactive waiting items (already sorted by priority and arrival time)
      if (waitingItems.isNotEmpty) {
        itemToCall = waitingItems.first;
        await _queueRepo.callPatient(itemToCall.queueId, effectiveStaffId);
      } else {
        // 2. Fallback to repository query if local queue has not streamed yet
        final targetDept =
            currentDeptCode.value == 'ALL' ? 'GEN' : currentDeptCode.value;
        itemToCall = await _queueRepo.callNext(targetDept, effectiveStaffId);
      }

      if (itemToCall != null) {
        // Play audio announcement if AudioAnnouncementService is active
        try {
          if (Get.isRegistered<AudioAnnouncementService>()) {
            Get.find<AudioAnnouncementService>().announcePatientCall(
              queueNumber: itemToCall.queueNumber,
              roomName: itemToCall.assignedRoomId ?? 'Consultation Room',
            );
          }
        } catch (_) {}

        Get.snackbar(
          'Patient Called',
          'Called patient ${itemToCall.queueNumber} for consultation.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          colorText: AppColors.primary,
        );
      } else {
        Get.snackbar(
          'Queue Empty',
          'No patients are currently waiting in this queue.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
      Get.snackbar(
        'Error Calling Patient',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade900,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> callPatient(String queueId, String staffId) async {
    isLoading.value = true;
    try {
      await _queueRepo.callPatient(queueId, staffId);
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> startConsultation(QueueItemModel item) async {
    isLoading.value = true;
    _resetConsultationForm();
    try {
      await _queueRepo.startService(item.queueId);
      currentPatient.value = await _patientRepo.getPatientById(item.patientId);
      currentVisit.value = await _visitRepo.getVisitById(item.visitId);

      // Pre-fill triage vitals if available on visit
      if (currentVisit.value?.vitals != null &&
          currentVisit.value!.vitals!.isNotEmpty) {
        vitals.addAll(currentVisit.value!.vitals!);
      }

      // Load past consultations and visit diagnostic results
      if (_consultationRepo != null && item.patientId.isNotEmpty) {
        _consultationRepo
            .streamPatientConsultations(item.patientId)
            .listen((list) {
          patientConsultations.assignAll(list);
        });
      }
      if (_diagnosticRepo != null && item.visitId.isNotEmpty) {
        _diagnosticRepo.streamVisitResults(item.visitId).listen((list) {
          visitDiagnosticResults.assignAll(list);
        });
      }
    } catch (e) {
      _handleFirestoreError(e, 'start consultation');
    } finally {
      isLoading.value = false;
    }
  }

  /// Start a clinical consultation directly from a patient appointment.
  Future<void> startAppointmentConsultation(
    AppointmentModel apt,
    String doctorStaffId,
  ) async {
    if (currentlyServing.value != null) {
      Get.snackbar(
        'Action Blocked',
        'Please finish or discharge ${currentPatient.value?.fullName.isNotEmpty == true ? currentPatient.value!.fullName : "current patient"} before starting a new consultation.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;
    _resetConsultationForm();

    try {
      final now = DateTime.now();
      // 1. Get or create today's visit for this patient
      VisitModel? visit =
          await _visitRepo.getTodaysVisitForPatient(apt.patientId);
      if (visit == null) {
        final visitId = const Uuid().v4();
        visit = VisitModel(
          visitId: visitId,
          patientId: apt.patientId,
          visitDate: now,
          arrivalTime: now,
          patientType: 'REGULAR',
          priority: Priority.regular,
          currentDepartment:
              apt.departmentId.isNotEmpty ? apt.departmentId : 'GEN',
          currentStatus: 'IN_CONSULTATION',
          completed: false,
          createdAt: now,
          updatedAt: now,
        );
        await _visitRepo.saveVisit(visit);
      }

      // 2. Create queue item representing this in-progress consultation
      final deptCode = apt.departmentId.isNotEmpty ? apt.departmentId : 'GEN';
      final queueNumber = await _queueRepo.generateQueueNumber(deptCode);
      final queueId = const Uuid().v4();

      final queueItem = QueueItemModel(
        queueId: queueId,
        queueNumber: queueNumber,
        patientId: apt.patientId,
        visitId: visit.visitId,
        departmentId: deptCode,
        departmentName: apt.departmentName.isNotEmpty
            ? apt.departmentName
            : 'General Medicine',
        priority: Priority.regular.toMap(),
        status: QueueStatus.inProgress,
        createdAt: now,
        assignedStaffId: doctorStaffId,
        serviceStartedAt: now,
      );
      await _queueRepo.saveQueueItem(queueItem);

      // 3. Mark appointment as CONFIRMED in database and locally
      await _aptRepo?.updateAppointment(apt.appointmentId, {
        'status': 'CONFIRMED',
        'updatedAt': Timestamp.fromDate(now),
      });
      final allIdx = allAppointments
          .indexWhere((a) => a.appointmentId == apt.appointmentId);
      if (allIdx != -1) {
        allAppointments[allIdx] =
            allAppointments[allIdx].copyWith(status: 'CONFIRMED');
        allAppointments.refresh();
      }
      final todayIdx = todayAppointments
          .indexWhere((a) => a.appointmentId == apt.appointmentId);
      if (todayIdx != -1) {
        todayAppointments[todayIdx] =
            todayAppointments[todayIdx].copyWith(status: 'CONFIRMED');
        todayAppointments.refresh();
      }

      // 4. Set currently serving and load patient data
      currentlyServing.value = queueItem;
      currentPatient.value = await _patientRepo.getPatientById(apt.patientId);
      currentVisit.value = visit;

      // 5. Pre-fill triage vitals if available
      if (visit.vitals != null && visit.vitals!.isNotEmpty) {
        vitals.addAll(visit.vitals!);
      }

      // 6. Load past consultations & diagnostic results
      if (_consultationRepo != null && apt.patientId.isNotEmpty) {
        _consultationRepo
            .streamPatientConsultations(apt.patientId)
            .listen((list) {
          patientConsultations.assignAll(list);
        });
      }
      if (_diagnosticRepo != null && visit.visitId.isNotEmpty) {
        _diagnosticRepo.streamVisitResults(visit.visitId).listen((list) {
          visitDiagnosticResults.assignAll(list);
        });
      }

      Get.snackbar(
        'Consultation Started',
        'Clinical consultation started for ${apt.patientName.isNotEmpty ? apt.patientName : "patient"}.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      _handleFirestoreError(e, 'start consultation');
    } finally {
      isLoading.value = false;
    }
  }

  void _handleFirestoreError(dynamic e, String actionName) {
    final msg = e.toString();
    errorMessage.value = FirebaseErrorHandler.toMessage(e);
    debugPrint('════════════ ERROR IN $actionName ════════════');
    debugPrint(msg);
    debugPrint('═════════════════════════════════════════════');

    final match = RegExp(r'https://console\.firebase\.google\.com[^\s\)]+')
        .firstMatch(msg);
    if (match != null) {
      final url = match.group(0)!;
      Clipboard.setData(ClipboardData(text: url));
      Get.dialog(
        AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.link, color: Colors.blue),
              SizedBox(width: 8),
              Text('Firestore Index Required'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Firestore requires an index to execute this query.\n\n'
                'The link has already been COPIED to your clipboard! You can also copy or select it below:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SelectableText(
                  url,
                  style: const TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: url));
                Get.snackbar('Copied', 'Index URL copied to clipboard!',
                    snackPosition: SnackPosition.BOTTOM);
              },
              child: const Text('Copy Link Again'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      Get.snackbar('Error', 'Failed to $actionName: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _resetConsultationForm() {
    symptoms.value = '';
    observations.value = '';
    vitals.assignAll({
      'bloodPressure': '',
      'pulseRate': '',
      'temperature': '',
      'weight': '',
      'oxygenSaturation': '',
    });
    diagnosis.value = '';
    clinicalNotes.value = '';
    treatmentPlan.value = '';
    pendingDiagnostics.clear();
    pendingPrescriptions.clear();
    admissionRequested.value = false;
    admissionReason.value = '';
    admissionPriority.value = 'ROUTINE';
    dischargeRecommended.value = false;
    dischargeSummary.value = '';
  }

  void addDiagnosticOrder({
    required String diagnosticType,
    required String testName,
    String priority = 'ROUTINE',
    String instructions = '',
    double fee = 50.0,
  }) {
    pendingDiagnostics.add(PendingDiagnosticItem(
      diagnosticType: diagnosticType,
      testName: testName,
      priority: priority,
      instructions: instructions,
      fee: fee,
    ));
  }

  void removeDiagnosticOrder(int index) {
    if (index >= 0 && index < pendingDiagnostics.length) {
      pendingDiagnostics.removeAt(index);
    }
  }

  void addPrescriptionOrder({
    required String medicationName,
    required String dosage,
    required String frequency,
    required String duration,
    required int quantity,
    String instructions = '',
    double fee = 15.0,
  }) {
    pendingPrescriptions.add(PendingPrescriptionItem(
      medicationName: medicationName,
      dosage: dosage,
      frequency: frequency,
      duration: duration,
      quantity: quantity,
      instructions: instructions,
      estimatedFee: fee,
    ));
  }

  void removePrescriptionOrder(int index) {
    if (index >= 0 && index < pendingPrescriptions.length) {
      pendingPrescriptions.removeAt(index);
    }
  }

  /// Completes consultation with all Phase 2 clinical records, diagnostics, prescriptions,
  /// admission request, itemized billing, and dynamic workflow transition.
  Future<bool> completeConsultation({
    required String queueId,
    required String visitId,
    String doctorId = '',
    String doctorName = '',
  }) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final patient = currentPatient.value;
      final visit = currentVisit.value;
      final patientId = patient?.patientId ?? visit?.patientId ?? '';
      final pName = patient?.fullName ?? '';

      final List<String> createdDiagnosticRequestIds = [];
      final List<String> createdPrescriptionIds = [];
      String? createdAdmissionId;
      final List<InvoiceItemModel> invoiceItems = [];

      // Always add consultation fee
      invoiceItems.add(const InvoiceItemModel(
        description: 'Doctor Consultation Fee',
        unitPrice: 30.0,
        quantity: 1,
        total: 30.0,
        category: 'CONSULTATION',
      ));

      // 1. Process Diagnostics
      if (_diagnosticRepo != null && pendingDiagnostics.isNotEmpty) {
        for (final diag in pendingDiagnostics) {
          final reqId = _diagnosticRepo.generateRequestId();
          createdDiagnosticRequestIds.add(reqId);

          final req = DiagnosticRequestModel(
            diagnosticRequestId: reqId,
            patientId: patientId,
            patientName: pName,
            visitId: visitId,
            consultationId: '',
            doctorId: doctorId,
            doctorName: doctorName,
            diagnosticType: diag.diagnosticType,
            testName: diag.testName,
            priority: diag.priority,
            instructions: diag.instructions,
            status: 'WAITING',
            requestedAt: DateTime.now(),
          );
          await _diagnosticRepo.saveRequest(req);

          // Add to bill
          invoiceItems.add(InvoiceItemModel(
            description: '${diag.diagnosticType}: ${diag.testName}',
            unitPrice: diag.fee,
            quantity: 1,
            total: diag.fee,
            category: diag.diagnosticType == 'LAB' ? 'LABORATORY' : 'SCAN',
          ));
        }
      }

      // 2. Process Prescriptions
      if (_pharmacyRepo != null && pendingPrescriptions.isNotEmpty) {
        for (final rx in pendingPrescriptions) {
          final rxId = _pharmacyRepo.generatePrescriptionId();
          createdPrescriptionIds.add(rxId);

          final rxModel = PrescriptionModel(
            prescriptionId: rxId,
            patientId: patientId,
            patientName: pName,
            visitId: visitId,
            consultationId: '',
            doctorId: doctorId,
            doctorName: doctorName,
            medicationName: rx.medicationName,
            dosage: rx.dosage,
            frequency: rx.frequency,
            duration: rx.duration,
            quantity: rx.quantity,
            instructions: rx.instructions,
            status: 'PENDING',
            createdAt: DateTime.now(),
          );
          await _pharmacyRepo.savePrescription(rxModel);

          // Add to bill
          final rxTotal = rx.estimatedFee * rx.quantity;
          invoiceItems.add(InvoiceItemModel(
            description: '${rx.medicationName} (${rx.dosage}) x${rx.quantity}',
            unitPrice: rx.estimatedFee,
            quantity: rx.quantity,
            total: rxTotal,
            category: 'MEDICATION',
          ));
        }
      }

      // 3. Process Admission Request
      if (_admissionRepo != null && admissionRequested.value) {
        final admId = _admissionRepo.generateAdmissionId();
        createdAdmissionId = admId;

        final admModel = AdmissionRequestModel(
          admissionRequestId: admId,
          patientId: patientId,
          patientName: pName,
          visitId: visitId,
          doctorId: doctorId,
          doctorName: doctorName,
          reason: admissionReason.value.isNotEmpty
              ? admissionReason.value
              : 'In-patient care recommended',
          priority: admissionPriority.value,
          status: 'REQUESTED',
          requestedAt: DateTime.now(),
        );
        await _admissionRepo.saveAdmissionRequest(admModel);

        invoiceItems.add(const InvoiceItemModel(
          description: 'In-Patient Admission Deposit',
          unitPrice: 100.0,
          quantity: 1,
          total: 100.0,
          category: 'ADMISSION',
        ));
      }

      // 4. Save Consultation Record
      String consultationId = '';
      if (_consultationRepo != null) {
        consultationId = _consultationRepo.generateId();
        final consultation = ConsultationModel(
          consultationId: consultationId,
          patientId: patientId,
          patientName: pName,
          visitId: visitId,
          doctorId: doctorId,
          doctorName: doctorName,
          symptoms: symptoms.value,
          observations: observations.value,
          vitals: Map<String, dynamic>.from(vitals),
          diagnosis: diagnosis.value,
          clinicalNotes: clinicalNotes.value,
          treatmentPlan: treatmentPlan.value,
          diagnosticRequestIds: createdDiagnosticRequestIds,
          prescriptionIds: createdPrescriptionIds,
          admissionRequested: admissionRequested.value,
          dischargeRecommended: dischargeRecommended.value,
          createdAt: DateTime.now(),
        );
        await _consultationRepo.saveConsultation(consultation);
      }

      // 5. Generate / Update Itemized Invoice
      String? invoiceId;
      if (_billingRepo != null && invoiceItems.isNotEmpty) {
        invoiceId = _billingRepo.generateInvoiceId();
        final double subtotal =
            invoiceItems.fold(0.0, (acc, item) => acc + item.total);
        final invoice = InvoiceModel(
          invoiceId: invoiceId,
          patientId: patientId,
          patientName: pName,
          visitId: visitId,
          items: invoiceItems,
          subtotal: subtotal,
          discount: 0.0,
          total: subtotal,
          amountPaid: 0.0,
          balance: subtotal,
          status: 'PENDING',
          createdAt: DateTime.now(),
        );
        await _billingRepo.saveInvoice(invoice);
      }

      // 6. Dynamic Visit Status Progression
      String nextStatus;
      String nextCareStage;
      if (admissionRequested.value) {
        nextStatus = 'ADMISSION_REQUESTED';
        nextCareStage = 'ADMISSION_REQUESTED';
      } else if (createdDiagnosticRequestIds.isNotEmpty) {
        nextStatus = 'WAITING_FOR_DIAGNOSTIC';
        nextCareStage = 'WAITING_FOR_DIAGNOSTIC';
      } else if (createdPrescriptionIds.isNotEmpty) {
        nextStatus = 'WAITING_FOR_PHARMACY';
        nextCareStage = 'WAITING_FOR_PHARMACY';
      } else if (dischargeRecommended.value) {
        nextStatus = 'READY_FOR_DISCHARGE';
        nextCareStage = 'READY_FOR_DISCHARGE';
      } else {
        nextStatus = 'AWAITING_PAYMENT';
        nextCareStage = 'AWAITING_PAYMENT';
      }

      // 7. Update Visit with all cross references
      await _visitRepo.updateVisit(visitId, {
        'status': nextStatus,
        'careStage': nextCareStage,
        if (consultationId.isNotEmpty) 'consultationId': consultationId,
        if (createdDiagnosticRequestIds.isNotEmpty)
          'diagnosticRequestIds': createdDiagnosticRequestIds,
        if (createdPrescriptionIds.isNotEmpty)
          'prescriptionIds': createdPrescriptionIds,
        if (createdAdmissionId != null)
          'admissionRequestId': createdAdmissionId,
        if (invoiceId != null) 'invoiceId': invoiceId,
      });

      // 8. Complete doctor queue item
      await _visitRepo.completeDoctorConsultation(
        visitId: visitId,
        doctorQueueId: queueId,
      );

      // 9. Send Notification to patient
      if (_notificationRepo != null && patientId.isNotEmpty) {
        await _notificationRepo.notify(
          recipientId: patientId,
          recipientType: 'patient',
          title: 'Consultation Completed',
          body:
              'Dr. $doctorName has finalized your consultation. Your next step is: $nextCareStage.',
          type: 'CONSULTATION_DONE',
          relatedId: visitId,
        );
      }

      _resetConsultationForm();
      currentlyServing.value = null;
      currentPatient.value = null;
      currentVisit.value = null;
      return true;
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> skipPatient(String queueId) async {
    try {
      await _queueRepo.skipPatient(queueId);
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
    }
  }

  Future<void> markNoShow(String queueId) async {
    try {
      await _queueRepo.markNoShow(queueId);
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
    }
  }

  List<QueueItemModel> get waitingItems =>
      doctorQueue.where((i) => i.status == QueueStatus.waiting).toList();

  void clearError() => errorMessage.value = '';
}
