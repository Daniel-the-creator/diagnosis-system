import 'dart:async';
import 'package:get/get.dart';
import '../models/patient_model.dart';
import '../models/visit_model.dart';
import '../models/queue_item_model.dart';
import '../models/diagnostic_result_model.dart';
import '../models/diagnostic_request_model.dart';
import '../models/prescription_model.dart';
import '../models/invoice_model.dart';
import '../models/payment_model.dart';
import '../models/appointment_model.dart';
import '../models/notification_model.dart';
import '../models/admission_models.dart';
import '../repositories/patient_repository.dart';
import '../repositories/visit_repository.dart';
import '../repositories/queue_repository.dart';
import '../repositories/diagnostic_repository.dart';
import '../repositories/pharmacy_repository.dart';
import '../repositories/billing_repository.dart';
import '../repositories/appointment_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/admission_repository.dart';
import '../services/workflow/workflow_engine_service.dart';
import '../core/errors/firebase_error_handler.dart';

/// Comprehensive controller managing the Patient Portal interface.
class PatientPortalController extends GetxController {
  PatientPortalController({
    required this.patientId,
    required PatientRepository patientRepo,
    required VisitRepository visitRepo,
    required QueueRepository queueRepo,
    required DiagnosticRepository diagnosticRepo,
    required PharmacyRepository pharmacyRepo,
    required BillingRepository billingRepo,
    required AppointmentRepository appointmentRepo,
    required NotificationRepository notificationRepo,
    required AdmissionRepository admissionRepo,
    required WorkflowEngineService workflowEngine,
  })  : _patientRepo = patientRepo,
        _visitRepo = visitRepo,
        _queueRepo = queueRepo,
        _diagRepo = diagnosticRepo,
        _pharmRepo = pharmacyRepo,
        _billRepo = billingRepo,
        _aptRepo = appointmentRepo,
        _notifRepo = notificationRepo,
        _admRepo = admissionRepo,
        _workflowEngine = workflowEngine;

  final String patientId;
  final PatientRepository _patientRepo;
  final VisitRepository _visitRepo;
  final QueueRepository _queueRepo;
  final DiagnosticRepository _diagRepo;
  final PharmacyRepository _pharmRepo;
  final BillingRepository _billRepo;
  final AppointmentRepository _aptRepo;
  final NotificationRepository _notifRepo;
  final AdmissionRepository _admRepo;
  final WorkflowEngineService _workflowEngine;

  // Profile
  final Rx<PatientModel?> patient = Rx<PatientModel?>(null);

  // Active Visit & Queue
  final Rx<VisitModel?> activeVisit = Rx<VisitModel?>(null);
  final Rx<QueueItemModel?> activeQueueItem = Rx<QueueItemModel?>(null);
  final RxInt peopleAhead = 0.obs;
  final RxString nowServingNumber = '-'.obs;
  final RxBool isCalled = false.obs;

  // Dynamic Journey
  final RxList<JourneyStage> journeyStages = <JourneyStage>[].obs;

  // Clinical & Operational Records
  final RxList<DiagnosticResultModel> releasedResults = <DiagnosticResultModel>[].obs;
  final RxList<DiagnosticRequestModel> diagnosticRequests = <DiagnosticRequestModel>[].obs;
  final RxList<PrescriptionModel> prescriptions = <PrescriptionModel>[].obs;
  final RxList<InvoiceModel> invoices = <InvoiceModel>[].obs;
  final Rx<InvoiceModel?> activeInvoice = Rx<InvoiceModel?>(null);
  final RxList<PaymentModel> payments = <PaymentModel>[].obs;
  final RxList<AppointmentModel> appointments = <AppointmentModel>[].obs;
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxInt unreadNotifications = 0.obs;
  final Rx<AdmissionRequestModel?> activeAdmission = Rx<AdmissionRequestModel?>(null);

  final RxInt currentTabIndex = 0.obs;
  final RxBool isLoading = false.obs;
  final RxBool isBookingAppointment = false.obs;
  final RxString errorMessage = ''.obs;

  final List<StreamSubscription> _subscriptions = [];

  @override
  void onInit() {
    super.onInit();
    _loadPatientData();
    _setupStreams();
  }

  @override
  void onClose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    super.onClose();
  }

  Future<void> _loadPatientData() async {
    if (patientId.isEmpty) return;
    isLoading.value = true;
    try {
      final p = await _patientRepo
          .getPatientById(patientId)
          .timeout(const Duration(seconds: 4));
      if (p != null) patient.value = p;
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  void _setupStreams() {
    if (patientId.isEmpty) return;

    // 1. Patient profile stream
    _subscriptions.add(
      _patientRepo.streamPatient(patientId).listen((p) {
        if (p != null) patient.value = p;
      }),
    );

    // 2. Active visit stream
    _subscriptions.add(
      _visitRepo.streamPatientVisits(patientId).listen((visits) {
        final active = visits.where((v) => v.status != 'DISCHARGED' && v.status != 'CANCELLED').firstOrNull;
        activeVisit.value = active ?? visits.firstOrNull;
        _recomputeJourney();
        if (active != null) {
          _listenToActiveVisitDetails(active.visitId);
        }
      }),
    );

    // 3. Released diagnostic results
    _subscriptions.add(
      _diagRepo.streamPatientReleasedResults(patientId).listen((results) {
        releasedResults.assignAll(results);
      }),
    );

    // 4. Prescriptions
    _subscriptions.add(
      _pharmRepo.streamPatientPrescriptions(patientId).listen((rxList) {
        prescriptions.assignAll(rxList);
        _recomputeJourney();
      }),
    );

    // 5. Invoices
    _subscriptions.add(
      _billRepo.streamPatientInvoices(patientId).listen((invList) {
        invoices.assignAll(invList);
        activeInvoice.value = invList.where((i) => !i.isPaid).firstOrNull ?? invList.firstOrNull;
        _recomputeJourney();
      }),
    );

    // 6. Payments
    _subscriptions.add(
      _billRepo.streamPatientPayments(patientId).listen((payList) {
        payments.assignAll(payList);
      }),
    );

    // 7. Appointments
    _subscriptions.add(
      _aptRepo.streamPatientAppointments(patientId).listen(
        (aptList) {
          appointments.assignAll(aptList);
        },
        onError: (e) {
          errorMessage.value = 'Appointments error: ${e.toString()}';
        },
      ),
    );

    // 8. Notifications
    _subscriptions.add(
      _notifRepo.streamUserNotifications(patientId).listen((notifs) {
        notifications.assignAll(notifs);
        unreadNotifications.value = notifs.where((n) => !n.read).length;
      }),
    );

    // 9. Admissions
    _subscriptions.add(
      _admRepo.streamPatientAdmissions(patientId).listen((adms) {
        activeAdmission.value = adms.where((a) => a.status != 'DISCHARGED').firstOrNull;
        _recomputeJourney();
      }),
    );
  }

  void _listenToActiveVisitDetails(String visitId) {
    // Stream active queue item for this visit
    _subscriptions.add(
      _queueRepo.streamQueueForVisit(visitId).listen((items) {
        final current = items.where((i) => i.status != QueueStatus.completed && i.status != QueueStatus.cancelled).firstOrNull;
        activeQueueItem.value = current;
        isCalled.value = current?.status == QueueStatus.called || current?.status == QueueStatus.inProgress;

        if (current != null) {
          _queueRepo.streamActiveQueue(current.departmentCode).listen((deptQueue) {
            final nowServing = deptQueue.where((i) => i.status == QueueStatus.inProgress || i.status == QueueStatus.called).firstOrNull;
            nowServingNumber.value = nowServing?.queueNumber ?? '-';

            final waitingList = deptQueue.where((i) => i.status == QueueStatus.waiting).toList();
            final currentIndex = waitingList.indexWhere((i) => i.queueId == current.queueId);
            peopleAhead.value = currentIndex >= 0 ? currentIndex : 0;
          });
        }
      }),
    );

    // Stream diagnostic requests for active visit
    _subscriptions.add(
      _diagRepo.streamVisitRequests(visitId).listen((reqs) {
        diagnosticRequests.assignAll(reqs);
        _recomputeJourney();
      }),
    );
  }

  void _recomputeJourney() {
    final v = activeVisit.value;
    if (v == null) {
      journeyStages.clear();
      return;
    }
    final stages = _workflowEngine.computeJourney(
      visit: v,
      diagnosticRequests: diagnosticRequests,
      prescriptions: prescriptions,
      admissionRequest: activeAdmission.value,
      invoice: activeInvoice.value,
    );
    journeyStages.assignAll(stages);
  }

  Future<void> bookAppointment({
    required String doctorId,
    required String doctorName,
    required String departmentId,
    required String departmentName,
    required DateTime date,
    required String timeSlot,
    required String reason,
  }) async {
    isBookingAppointment.value = true;
    errorMessage.value = '';
    try {
      final aptId = _aptRepo.generateAppointmentId();
      final pName = patient.value?.fullName ?? '';
      final appointment = AppointmentModel(
        appointmentId: aptId,
        patientId: patientId,
        patientName: pName,
        doctorId: doctorId,
        doctorName: doctorName,
        departmentId: departmentId,
        departmentName: departmentName,
        date: date,
        timeSlot: timeSlot,
        reason: reason,
        status: 'SCHEDULED',
        createdAt: DateTime.now(),
      );
      // Immediate optimistic update
      appointments.insert(0, appointment);
      appointments.refresh();

      await _aptRepo.saveAppointment(appointment);
      Get.snackbar(
        'Appointment Booked',
        'Your appointment with Dr. $doctorName has been scheduled for $timeSlot.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
      // Reload stream data if error occurred
      _loadPatientData();
    } finally {
      isBookingAppointment.value = false;
    }
  }

  Future<void> cancelAppointment(String appointmentId, {String? reason}) async {
    // Immediate optimistic update so it leaves active list instantly
    final idx = appointments.indexWhere((a) => a.appointmentId == appointmentId);
    if (idx != -1) {
      appointments[idx] = appointments[idx].copyWith(status: 'CANCELLED');
      appointments.refresh();
    }

    try {
      await _aptRepo.cancelAppointment(appointmentId, reason: reason);
      Get.snackbar('Appointment Cancelled', 'Your appointment has been cancelled.');
    } catch (e) {
      errorMessage.value = FirebaseErrorHandler.toMessage(e);
    }
  }

  Future<void> markNotificationRead(String notificationId) async {
    await _notifRepo.markAsRead(notificationId);
  }

  Future<void> markAllNotificationsRead() async {
    await _notifRepo.markAllAsRead(patientId);
  }

  void selectTab(int index) {
    currentTabIndex.value = index;
  }
}
