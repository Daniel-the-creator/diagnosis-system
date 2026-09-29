import '../../models/queue_item_model.dart';
import '../../models/invoice_model.dart';
import '../../models/medication_model.dart';
import '../../models/prescription_model.dart';
import '../../models/admission_models.dart';
import '../../models/appointment_model.dart';

/// Comprehensive domain validator ensuring strict integrity across hospital workflows,
/// finances, queues, medication dispensing, and bed allocations.
class HospitalDataValidator {
  HospitalDataValidator._();

  // ── 1. Queue Transitions ────────────────────────────────────────

  /// State machine:
  /// WAITING -> CALLED | SKIPPED | CANCELLED | NO_SHOW | TRANSFERRED
  /// CALLED -> IN_PROGRESS | WAITING | NO_SHOW | CANCELLED
  /// IN_PROGRESS -> COMPLETED | TRANSFERRED | CANCELLED
  /// COMPLETED, CANCELLED, NO_SHOW are terminal.
  static bool isValidQueueTransition(QueueStatus current, QueueStatus next) {
    if (current == next) return true;

    // Terminal states cannot transition
    if (current == QueueStatus.completed ||
        current == QueueStatus.cancelled ||
        current == QueueStatus.noShow) {
      return false;
    }

    switch (current) {
      case QueueStatus.waiting:
        return next == QueueStatus.called ||
            next == QueueStatus.inProgress ||
            next == QueueStatus.skipped ||
            next == QueueStatus.cancelled ||
            next == QueueStatus.noShow ||
            next == QueueStatus.transferred;

      case QueueStatus.called:
        return next == QueueStatus.inProgress ||
            next == QueueStatus.waiting ||
            next == QueueStatus.noShow ||
            next == QueueStatus.cancelled;

      case QueueStatus.inProgress:
        return next == QueueStatus.completed ||
            next == QueueStatus.transferred ||
            next == QueueStatus.cancelled;

      case QueueStatus.skipped:
        return next == QueueStatus.waiting ||
            next == QueueStatus.called ||
            next == QueueStatus.cancelled;

      case QueueStatus.transferred:
        return next == QueueStatus.waiting ||
            next == QueueStatus.completed ||
            next == QueueStatus.cancelled;

      default:
        return false;
    }
  }

  // ── 2. Payment & Invoice Validation ─────────────────────────────

  /// Validates payment transactions:
  /// - Amount must be strictly greater than 0
  /// - Amount cannot exceed the remaining balance
  /// - Balance cannot become negative
  static void validatePayment({
    required InvoiceModel invoice,
    required double paymentAmount,
  }) {
    if (paymentAmount <= 0) {
      throw ArgumentError('Payment amount must be greater than zero.');
    }
    if (paymentAmount > (invoice.balance + 0.001)) {
      throw ArgumentError(
          'Payment amount (\$${paymentAmount.toStringAsFixed(2)}) exceeds remaining invoice balance (\$${invoice.balance.toStringAsFixed(2)}).');
    }
    if (invoice.isPaid) {
      throw StateError('Invoice ${invoice.invoiceId} is already fully paid.');
    }
    if (invoice.status == 'CANCELLED') {
      throw StateError('Cannot accept payments for a cancelled invoice.');
    }
  }

  // ── 3. Pharmacy & Medication Validation ──────────────────────────

  /// Validates medication dispensing:
  /// - Quantity must be > 0
  /// - Cannot exceed remaining un-dispensed prescription quantity
  /// - Cannot exceed available medication inventory stock
  /// - Checks that medication has not expired
  static void validateDispensing({
    required PrescriptionModel prescription,
    required MedicationModel medication,
    required int dispenseQuantity,
  }) {
    if (dispenseQuantity <= 0) {
      throw ArgumentError('Dispensing quantity must be at least 1 unit.');
    }
    if (dispenseQuantity > prescription.remaining) {
      throw ArgumentError(
          'Cannot dispense $dispenseQuantity units. Only ${prescription.remaining} units remaining on prescription.');
    }
    if (dispenseQuantity > medication.stockQuantity) {
      throw StateError(
          'Insufficient inventory: only ${medication.stockQuantity} units of ${medication.name} in stock.');
    }
    if (medication.isExpired) {
      throw StateError(
          'Cannot dispense expired medication: ${medication.name} expired on ${medication.expiryDate}.');
    }
    if (prescription.isDispensed) {
      throw StateError('Prescription ${prescription.prescriptionId} has already been fully dispensed.');
    }
  }

  // ── 4. Bed & Admission Validation ───────────────────────────────

  /// Validates bed assignment:
  /// - Bed status must be 'AVAILABLE'
  /// - Prevents duplicate bed assignments to multiple active patients
  static void validateBedAssignment({
    required BedModel bed,
    required AdmissionRequestModel admission,
  }) {
    if (bed.status != 'AVAILABLE') {
      throw StateError(
          'Bed ${bed.bedNumber} is not available (Current status: ${bed.status}).');
    }
    if (admission.status == 'DISCHARGED') {
      throw StateError('Cannot assign bed to an already discharged patient admission record.');
    }
    if (admission.status == 'CANCELLED') {
      throw StateError('Cannot assign bed to a cancelled admission request.');
    }
  }

  // ── 5. Appointment Validation ───────────────────────────────────

  /// Validates appointment scheduling:
  /// - Date must be in the future
  /// - Valid doctor ID and patient ID required
  static void validateAppointmentBooking(AppointmentModel appt) {
    if (appt.patientId.isEmpty) {
      throw ArgumentError('Patient ID is required for booking an appointment.');
    }
    if (appt.doctorId.isEmpty) {
      throw ArgumentError('Doctor selection is required for booking an appointment.');
    }
    final now = DateTime.now();
    // Allow today's dates if within valid hours, but disallow past dates
    final apptDay = DateTime(appt.date.year, appt.date.month, appt.date.day);
    final today = DateTime(now.year, now.month, now.day);
    if (apptDay.isBefore(today)) {
      throw ArgumentError('Cannot book an appointment for a past date.');
    }
  }

  // ── 6. Diagnostic State Transitions ─────────────────────────────

  /// Validates diagnostic request flow:
  /// REQUESTED -> AWAITING_PAYMENT | PAID | WAITING
  /// WAITING -> IN_PROGRESS
  /// IN_PROGRESS -> COMPLETED
  static bool isValidDiagnosticTransition(String current, String next) {
    if (current == next) return true;
    if (current == 'COMPLETED' || current == 'CANCELLED') return false;

    switch (current.toUpperCase()) {
      case 'REQUESTED':
        return next == 'AWAITING_PAYMENT' || next == 'PAID' || next == 'WAITING' || next == 'CANCELLED';
      case 'AWAITING_PAYMENT':
        return next == 'PAID' || next == 'WAITING' || next == 'CANCELLED';
      case 'PAID':
      case 'WAITING':
        return next == 'IN_PROGRESS' || next == 'CANCELLED';
      case 'IN_PROGRESS':
        return next == 'COMPLETED' || next == 'CANCELLED';
      default:
        return false;
    }
  }
}
