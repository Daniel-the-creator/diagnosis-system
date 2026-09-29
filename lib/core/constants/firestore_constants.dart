/// Firestore collection and field name constants.
/// Use these everywhere instead of raw strings to avoid typos.
class FirestoreConstants {
  FirestoreConstants._();

  // ── Collections — Phase 1 ──────────────────────────────────────
  static const String usersCollection = 'users';
  static const String patientsCollection = 'patients';
  static const String visitsCollection = 'visits';
  static const String queueItemsCollection = 'queue_items';
  static const String departmentsCollection = 'departments';
  static const String roomsCollection = 'rooms';
  static const String doctorsCollection = 'doctors';
  static const String queueCountersCollection = 'queue_counters';

  // ── Collections — Phase 2 ──────────────────────────────────────
  static const String consultationsCollection = 'consultations';
  static const String diagnosticRequestsCollection = 'diagnostic_requests';
  static const String diagnosticResultsCollection = 'diagnostic_results';
  static const String invoicesCollection = 'invoices';
  static const String paymentsCollection = 'payments';
  static const String prescriptionsCollection = 'prescriptions';
  static const String medicationsCollection = 'medications';
  static const String admissionsCollection = 'admissions';
  static const String wardsCollection = 'wards';
  static const String bedsCollection = 'beds';
  static const String dischargesCollection = 'discharges';
  static const String appointmentsCollection = 'appointments';
  static const String notificationsCollection = 'notifications';

  // ── Collections — Phase 3 ──────────────────────────────────────
  static const String auditLogsCollection = 'audit_logs';
  static const String staffSchedulesCollection = 'staff_schedules';
  static const String settingsCollection = 'settings';

  // ── User Fields ────────────────────────────────────────────────
  static const String uid = 'uid';
  static const String fullName = 'fullName';
  static const String email = 'email';
  static const String phone = 'phone';
  static const String role = 'role';
  static const String departmentId = 'departmentId';
  static const String roomId = 'roomId';
  static const String active = 'active';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
  static const String patientIdRef = 'patientId'; // for user->patient link

  // ── Patient Fields ─────────────────────────────────────────────
  static const String patientId = 'patientId';
  static const String hospitalNumber = 'hospitalNumber';
  static const String dateOfBirth = 'dateOfBirth';
  static const String gender = 'gender';
  static const String address = 'address';
  static const String emergencyContactName = 'emergencyContactName';
  static const String emergencyContactPhone = 'emergencyContactPhone';
  static const String bloodGroup = 'bloodGroup';
  static const String genotype = 'genotype';
  static const String allergies = 'allergies';
  static const String medicalHistory = 'medicalHistory';
  static const String insuranceProvider = 'insuranceProvider';
  static const String insuranceNumber = 'insuranceNumber';
  static const String linkedUserId = 'linkedUserId'; // Phase 2: firebase uid

  // ── Visit Fields ───────────────────────────────────────────────
  static const String visitId = 'visitId';
  static const String visitDate = 'visitDate';
  static const String arrivalTime = 'arrivalTime';
  static const String patientType = 'patientType';
  static const String priority = 'priority';
  static const String currentDepartment = 'currentDepartment';
  static const String currentStatus = 'currentStatus';
  static const String careStage = 'careStage';
  static const String assignedDoctorId = 'assignedDoctorId';
  static const String assignedRoomId = 'assignedRoomId';
  static const String completed = 'completed';
  static const String consultationId = 'consultationId';
  static const String diagnosticRequestIds = 'diagnosticRequestIds';
  static const String prescriptionIds = 'prescriptionIds';
  static const String admissionRequestId = 'admissionRequestId';
  static const String invoiceId = 'invoiceId';
  static const String dischargeId = 'dischargeId';

  // ── Queue Item Fields ──────────────────────────────────────────
  static const String queueId = 'queueId';
  static const String queueNumber = 'queueNumber';
  static const String status = 'status';
  static const String calledAt = 'calledAt';
  static const String serviceStartedAt = 'serviceStartedAt';
  static const String completedAt = 'completedAt';
  static const String assignedStaffId = 'assignedStaffId';

  // ── Department Fields ──────────────────────────────────────────
  static const String name = 'name';
  static const String code = 'code';
  static const String description = 'description';
  static const String order = 'order';

  // ── Room Fields ────────────────────────────────────────────────
  static const String roomName = 'roomName';
  static const String roomNumber = 'roomNumber';
  static const String type = 'type';

  // ── Doctor Fields ──────────────────────────────────────────────
  static const String doctorId = 'doctorId';
  static const String userId = 'userId';
  static const String specialty = 'specialty';

  // ── Queue Counter Fields ───────────────────────────────────────
  static const String counter = 'counter';
  static const String prefix = 'prefix';
  static const String date = 'date';

  // ── Consultation Fields ────────────────────────────────────────
  static const String consultationIdField = 'consultationId';
  static const String doctorId2 = 'doctorId';
  static const String doctorName = 'doctorName';
  static const String symptoms = 'symptoms';
  static const String observations = 'observations';
  static const String vitals = 'vitals';
  static const String diagnosis = 'diagnosis';
  static const String notes = 'notes';
  static const String treatmentPlan = 'treatmentPlan';
  static const String admissionRequested = 'admissionRequested';
  static const String dischargeRecommended = 'dischargeRecommended';

  // ── Diagnostic Request Fields ──────────────────────────────────
  static const String diagnosticRequestId = 'diagnosticRequestId';
  static const String diagnosticType = 'diagnosticType';
  static const String testName = 'testName';
  static const String instructions = 'instructions';
  static const String requestedAt = 'requestedAt';
  static const String startedAt = 'startedAt';
  static const String isReleasedToPatient = 'isReleasedToPatient';

  // ── Diagnostic Result Fields ───────────────────────────────────
  static const String resultId = 'resultId';
  static const String performedBy = 'performedBy';
  static const String findings = 'findings';
  static const String interpretation = 'interpretation';
  static const String attachments = 'attachments';

  // ── Invoice Fields ─────────────────────────────────────────────
  static const String invoiceIdField = 'invoiceId';
  static const String items = 'items';
  static const String subtotal = 'subtotal';
  static const String discount = 'discount';
  static const String total = 'total';
  static const String amountPaid = 'amountPaid';
  static const String balance = 'balance';

  // ── Payment Fields ─────────────────────────────────────────────
  static const String paymentId = 'paymentId';
  static const String invoiceIdRef = 'invoiceId';
  static const String amount = 'amount';
  static const String paymentMethod = 'paymentMethod';
  static const String transactionReference = 'transactionReference';
  static const String receivedBy = 'receivedBy';
  static const String paymentDate = 'paymentDate';

  // ── Prescription Fields ────────────────────────────────────────
  static const String prescriptionId = 'prescriptionId';
  static const String medicationName = 'medicationName';
  static const String dosage = 'dosage';
  static const String frequency = 'frequency';
  static const String duration = 'duration';
  static const String quantity = 'quantity';
  static const String dispensedQuantity = 'dispensedQuantity';
  static const String dispensedBy = 'dispensedBy';
  static const String dispensedAt = 'dispensedAt';

  // ── Medication / Inventory Fields ─────────────────────────────
  static const String medicationId = 'medicationId';
  static const String drugName = 'drugName';
  static const String genericName = 'genericName';
  static const String category = 'category';
  static const String batchNumber = 'batchNumber';
  static const String unitPrice = 'unitPrice';
  static const String expiryDate = 'expiryDate';
  static const String supplier = 'supplier';
  static const String minimumStockLevel = 'minimumStockLevel';

  // ── Admission Fields ───────────────────────────────────────────
  static const String reason = 'reason';
  static const String assignedWardId = 'assignedWardId';
  static const String assignedBedId = 'assignedBedId';
  static const String admittedAt = 'admittedAt';

  // ── Ward Fields ────────────────────────────────────────────────
  static const String wardId = 'wardId';
  static const String capacity = 'capacity';

  // ── Bed Fields ─────────────────────────────────────────────────
  static const String bedId = 'bedId';
  static const String wardIdRef = 'wardId';
  static const String bedNumber = 'bedNumber';
  static const String currentPatientId = 'currentPatientId';
  static const String currentVisitId = 'currentVisitId';
  static const String assignedAt = 'assignedAt';

  // ── Discharge Fields ───────────────────────────────────────────
  static const String dischargeIdField = 'dischargeId';
  static const String dischargeSummary = 'dischargeSummary';
  static const String followUpInstructions = 'followUpInstructions';
  static const String dischargedAt = 'dischargedAt';
  static const String dischargedBy = 'dischargedBy';

  // ── Appointment Fields ─────────────────────────────────────────
  static const String appointmentId = 'appointmentId';
  static const String timeSlot = 'timeSlot';
  static const String patientName = 'patientName';

  // ── Notification Fields ────────────────────────────────────────
  static const String notificationId = 'notificationId';
  static const String recipientId = 'recipientId';
  static const String recipientType = 'recipientType';
  static const String title = 'title';
  static const String body = 'body';
  static const String relatedId = 'relatedId';
  static const String read = 'read';
}
