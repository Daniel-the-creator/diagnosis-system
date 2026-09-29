/// Application-wide string constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'MediFlow HMS';
  static const String appTagline = 'Hospital & Diagnostic Centre Management';
  static const String appVersion = '1.0.0';

  // ── Patient Types ──────────────────────────────────────────────
  static const String patientTypeRegular = 'REGULAR';
  static const String patientTypeEmergency = 'EMERGENCY';

  // ── Visit Statuses ─────────────────────────────────────────────
  static const String visitStatusActive = 'ACTIVE';
  static const String visitStatusCompleted = 'COMPLETED';
  static const String visitStatusCancelled = 'CANCELLED';

  // ── Queue Statuses ─────────────────────────────────────────────
  static const String queueStatusWaiting = 'WAITING';
  static const String queueStatusCalled = 'CALLED';
  static const String queueStatusInProgress = 'IN_PROGRESS';
  static const String queueStatusCompleted = 'COMPLETED';
  static const String queueStatusSkipped = 'SKIPPED';
  static const String queueStatusCancelled = 'CANCELLED';
  static const String queueStatusNoShow = 'NO_SHOW';
  static const String queueStatusTransferred = 'TRANSFERRED';

  // ── Staff Roles ────────────────────────────────────────────────
  static const String roleSuperAdmin = 'super_admin';
  static const String roleHospitalAdmin = 'hospital_admin';
  static const String roleGateOfficer = 'gate_officer';
  static const String roleRegistrationOfficer = 'registration_officer';
  static const String roleDoctor = 'doctor';

  // ── Phase 2 Roles ──────────────────────────────────────────────
  static const String rolePatient = 'patient';
  static const String roleDiagnosticStaff = 'diagnostic_staff';
  static const String roleAccountOfficer = 'account_officer';
  static const String rolePharmacist = 'pharmacist';
  static const String roleAdmissionOfficer = 'admission_officer';

  // ── Department Codes ───────────────────────────────────────────
  static const String deptCodeGate = 'GATE';
  static const String deptCodeRegistration = 'REG';
  static const String deptCodeGeneralMedicine = 'GEN';
  static const String deptCodePediatrics = 'PED';
  static const String deptCodeSurgery = 'SUR';
  static const String deptCodeLaboratory = 'LAB';
  static const String deptCodeXray = 'XR';
  static const String deptCodeScan = 'SCAN';
  static const String deptCodeAccount = 'ACC';
  static const String deptCodePharmacy = 'PHM';
  static const String deptCodeAdmission = 'ADM';
  static const String deptCodeDischarge = 'DIS';
  static const String deptCodeDoctor = 'DOC';

  // ── Priority Levels (Phase 3) ──────────────────────────────────
  static const String priorityCriticalEmergency = 'CRITICAL_EMERGENCY';
  static const String priorityEmergency = 'EMERGENCY';
  static const String priorityUrgent = 'URGENT';
  static const String priorityRegular = 'REGULAR';

  // ── Priority Weights ───────────────────────────────────────────
  static const int priorityWeightCriticalEmergency = 100;
  static const int priorityWeightEmergency = 50;
  static const int priorityWeightUrgent = 20;
  static const int priorityWeightRegular = 1;

  // ── Notification Categories (Phase 3) ───────────────────────────
  static const String notifCategoryQueue = 'QUEUE';
  static const String notifCategoryMedical = 'MEDICAL';
  static const String notifCategoryPayment = 'PAYMENT';
  static const String notifCategoryAppointment = 'APPOINTMENT';
  static const String notifCategoryPharmacy = 'PHARMACY';
  static const String notifCategoryAdmission = 'ADMISSION';
  static const String notifCategorySystem = 'SYSTEM';

  // ── Queue Prefix Map ───────────────────────────────────────────
  static const Map<String, String> queuePrefixes = {
    'REG': 'REG',
    'GEN': 'DOC',
    'PED': 'DOC',
    'SUR': 'DOC',
    'LAB': 'LAB',
    'XR': 'XR',
    'SCAN': 'SCAN',
    'ACC': 'ACC',
    'PHM': 'PHM',
    'ADM': 'ADM',
    'GATE': 'GATE',
    'DOC': 'DOC',
  };

  // ── Workflow Chain (Phase 1) ────────────────────────────────────
  /// Maps current department code to the next department code in the workflow.
  static const Map<String, String?> workflowNextDept = {
    'GATE': 'REG',
    'REG': 'DOC',
    'DOC': null, // Phase 2 extends this dynamically via WorkflowEngineService
  };

  // ── Phase 2 — Visit Care Stages ────────────────────────────────
  static const String careStageArrived = 'ARRIVED';
  static const String careStageRegistered = 'REGISTERED';
  static const String careStageWaitingForDoctor = 'WAITING_FOR_DOCTOR';
  static const String careStageInConsultation = 'IN_CONSULTATION';
  static const String careStageAwaitingPayment = 'AWAITING_PAYMENT';
  static const String careStageWaitingForDiagnostic = 'WAITING_FOR_DIAGNOSTIC';
  static const String careStageDiagnosticInProgress = 'DIAGNOSTIC_IN_PROGRESS';
  static const String careStageDiagnosticCompleted = 'DIAGNOSTIC_COMPLETED';
  static const String careStageAwaitingReview = 'AWAITING_REVIEW';
  static const String careStageWaitingForPharmacy = 'WAITING_FOR_PHARMACY';
  static const String careStagePharmacyInProgress = 'PHARMACY_IN_PROGRESS';
  static const String careStageAdmissionRequested = 'ADMISSION_REQUESTED';
  static const String careStageWaitingForBed = 'WAITING_FOR_BED';
  static const String careStageAdmitted = 'ADMITTED';
  static const String careStageReadyForDischarge = 'READY_FOR_DISCHARGE';
  static const String careStageDischarged = 'DISCHARGED';

  // ── Phase 2 — Diagnostic Types ─────────────────────────────────
  static const String diagnosticTypeLab = 'LAB';
  static const String diagnosticTypeXray = 'XR';
  static const String diagnosticTypeScan = 'SCAN';

  // ── Phase 2 — Diagnostic Request Statuses ──────────────────────
  static const String diagnosticStatusRequested = 'REQUESTED';
  static const String diagnosticStatusAwaitingPayment = 'AWAITING_PAYMENT';
  static const String diagnosticStatusPaid = 'PAID';
  static const String diagnosticStatusWaiting = 'WAITING';
  static const String diagnosticStatusInProgress = 'IN_PROGRESS';
  static const String diagnosticStatusCompleted = 'COMPLETED';
  static const String diagnosticStatusCancelled = 'CANCELLED';

  // ── Phase 2 — Invoice / Payment Statuses ───────────────────────
  static const String invoiceStatusPending = 'PENDING';
  static const String invoiceStatusPartiallyPaid = 'PARTIALLY_PAID';
  static const String invoiceStatusPaid = 'PAID';
  static const String invoiceStatusRefunded = 'REFUNDED';
  static const String invoiceStatusCancelled = 'CANCELLED';

  static const String paymentMethodCash = 'CASH';
  static const String paymentMethodPos = 'POS';
  static const String paymentMethodBankTransfer = 'BANK_TRANSFER';
  static const String paymentMethodOnline = 'ONLINE';

  // ── Phase 2 — Prescription Statuses ───────────────────────────
  static const String prescriptionStatusPending = 'PENDING';
  static const String prescriptionStatusPartiallyDispensed = 'PARTIALLY_DISPENSED';
  static const String prescriptionStatusDispensed = 'DISPENSED';
  static const String prescriptionStatusCancelled = 'CANCELLED';

  // ── Phase 2 — Admission Statuses ──────────────────────────────
  static const String admissionStatusRequested = 'REQUESTED';
  static const String admissionStatusApproved = 'APPROVED';
  static const String admissionStatusWaitingForBed = 'WAITING_FOR_BED';
  static const String admissionStatusAdmitted = 'ADMITTED';
  static const String admissionStatusDeclined = 'DECLINED';
  static const String admissionStatusCancelled = 'CANCELLED';
  static const String admissionStatusDischarged = 'DISCHARGED';

  // ── Phase 2 — Bed Statuses ─────────────────────────────────────
  static const String bedStatusAvailable = 'AVAILABLE';
  static const String bedStatusReserved = 'RESERVED';
  static const String bedStatusOccupied = 'OCCUPIED';
  static const String bedStatusMaintenance = 'MAINTENANCE';

  // ── Phase 2 — Appointment Statuses ────────────────────────────
  static const String appointmentStatusScheduled = 'SCHEDULED';
  static const String appointmentStatusConfirmed = 'CONFIRMED';
  static const String appointmentStatusCompleted = 'COMPLETED';
  static const String appointmentStatusCancelled = 'CANCELLED';
  static const String appointmentStatusRescheduled = 'RESCHEDULED';
  static const String appointmentStatusNoShow = 'NO_SHOW';

  // ── Phase 2 — Invoice Item Categories ─────────────────────────
  static const String invoiceCategoryConsultation = 'CONSULTATION';
  static const String invoiceCategoryLaboratory = 'LABORATORY';
  static const String invoiceCategoryXray = 'XRAY';
  static const String invoiceCategoryScan = 'SCAN';
  static const String invoiceCategoryMedication = 'MEDICATION';
  static const String invoiceCategoryAdmission = 'ADMISSION';
  static const String invoiceCategoryBed = 'BED';
  static const String invoiceCategoryOther = 'OTHER';
}
