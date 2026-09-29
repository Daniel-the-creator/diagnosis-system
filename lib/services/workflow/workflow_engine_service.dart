import '../../models/visit_model.dart';
import '../../models/diagnostic_request_model.dart';
import '../../models/prescription_model.dart';
import '../../models/admission_models.dart';
import '../../models/invoice_model.dart';

enum JourneyStageStatus {
  completed,
  inProgress,
  pending,
}

class JourneyStage {
  final String id;
  final String title;
  final String subtitle;
  final JourneyStageStatus status;
  final DateTime? timestamp;

  const JourneyStage({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
    this.timestamp,
  });

  bool get isCompleted => status == JourneyStageStatus.completed;
  bool get isInProgress => status == JourneyStageStatus.inProgress;
  bool get isPending => status == JourneyStageStatus.pending;
}

/// Dynamic Care Pathway and Workflow Engine.
/// Computes a patient's customized journey stages based on active orders,
/// visit status, diagnostic requests, prescriptions, and admission records.
class WorkflowEngineService {
  List<JourneyStage> computeJourney({
    required VisitModel visit,
    List<DiagnosticRequestModel> diagnosticRequests = const [],
    List<PrescriptionModel> prescriptions = const [],
    AdmissionRequestModel? admissionRequest,
    InvoiceModel? invoice,
  }) {
    final stages = <JourneyStage>[];
    final visitStatus = visit.status.toUpperCase();
    final careStage = (visit.careStage ?? visit.status).toUpperCase();

    // 1. Hospital Arrival
    final arrivedDone = visitStatus != 'ARRIVED';
    stages.add(JourneyStage(
      id: 'ARRIVAL',
      title: 'Hospital Gate Arrival',
      subtitle: arrivedDone ? 'Patient checked in at hospital gate' : 'Gate check-in completed',
      status: arrivedDone ? JourneyStageStatus.completed : JourneyStageStatus.inProgress,
      timestamp: visit.arrivalTime,
    ));

    // 2. Registration & Triage
    final regDone = visitStatus != 'ARRIVED' && visitStatus != 'REGISTERED';
    stages.add(JourneyStage(
      id: 'REGISTRATION',
      title: 'Registration & Triage',
      subtitle: regDone
          ? 'Patient file and vitals recorded'
          : (visitStatus == 'REGISTERED' ? 'Waiting at registration' : 'Pending registration'),
      status: regDone
          ? JourneyStageStatus.completed
          : (visitStatus == 'REGISTERED' || visitStatus == 'ARRIVED'
              ? JourneyStageStatus.inProgress
              : JourneyStageStatus.pending),
      timestamp: visit.registrationTime,
    ));

    // 3. Doctor Consultation
    final isConsultPast = [
      'AWAITING_PAYMENT',
      'WAITING_FOR_DIAGNOSTIC',
      'DIAGNOSTIC_IN_PROGRESS',
      'DIAGNOSTIC_COMPLETED',
      'AWAITING_REVIEW',
      'WAITING_FOR_PHARMACY',
      'PHARMACY_IN_PROGRESS',
      'ADMISSION_REQUESTED',
      'WAITING_FOR_BED',
      'ADMITTED',
      'READY_FOR_DISCHARGE',
      'DISCHARGED',
      'COMPLETED'
    ].contains(visitStatus);

    final isConsultNow = visitStatus == 'WAITING_FOR_DOCTOR' ||
        visitStatus == 'IN_CONSULTATION' ||
        visitStatus == 'AWAITING_REVIEW';

    stages.add(JourneyStage(
      id: 'CONSULTATION',
      title: 'Doctor Consultation',
      subtitle: isConsultPast
          ? 'Consultation completed'
          : (visitStatus == 'IN_CONSULTATION'
              ? 'Currently in doctor consultation'
              : (visitStatus == 'AWAITING_REVIEW'
                  ? 'Awaiting doctor test review'
                  : 'In doctor consultation queue')),
      status: isConsultPast
          ? JourneyStageStatus.completed
          : (isConsultNow ? JourneyStageStatus.inProgress : JourneyStageStatus.pending),
    ));

    // 4. Billing / Cashier (If invoice exists and has a balance)
    if (invoice != null && (invoice.items.isNotEmpty || invoice.total > 0)) {
      final isPaid = invoice.isPaid;
      final isBillingNow = careStage == 'AWAITING_PAYMENT' || (!isPaid && !isConsultNow && !isConsultPast);
      stages.add(JourneyStage(
        id: 'BILLING',
        title: 'Billing & Cashier',
        subtitle: isPaid
            ? 'Invoices fully settled'
            : (invoice.isPartiallyPaid
                ? 'Partially paid - Balance: \$${invoice.balance.toStringAsFixed(2)}'
                : 'Pending payment: \$${invoice.total.toStringAsFixed(2)}'),
        status: isPaid
            ? JourneyStageStatus.completed
            : (isBillingNow ? JourneyStageStatus.inProgress : JourneyStageStatus.pending),
      ));
    }

    // 5. Diagnostics (Lab, X-Ray, Scan)
    if (diagnosticRequests.isNotEmpty) {
      for (final req in diagnosticRequests) {
        final reqStatus = req.status.toUpperCase();
        final isDone = reqStatus == 'COMPLETED';
        final isProg = reqStatus == 'IN_PROGRESS' || reqStatus == 'WAITING' || reqStatus == 'PAID';

        stages.add(JourneyStage(
          id: 'DIAGNOSTIC_${req.diagnosticRequestId}',
          title: '${req.diagnosticTypeLabel}: ${req.testName}',
          subtitle: isDone
              ? 'Test completed & results recorded'
              : (reqStatus == 'IN_PROGRESS'
                  ? 'Test currently in progress'
                  : (reqStatus == 'AWAITING_PAYMENT'
                      ? 'Payment required before test'
                      : 'In diagnostic queue')),
          status: isDone
              ? JourneyStageStatus.completed
              : (isProg ? JourneyStageStatus.inProgress : JourneyStageStatus.pending),
        ));
      }
    }

    // 6. Pharmacy (If prescriptions exist)
    if (prescriptions.isNotEmpty) {
      final allDispensed = prescriptions.every((p) => p.isDispensed);
      final anyDispensed = prescriptions.any((p) => p.isDispensed || p.status == 'PARTIALLY_DISPENSED');
      final isPharmNow = careStage == 'WAITING_FOR_PHARMACY' ||
          careStage == 'PHARMACY_IN_PROGRESS' ||
          visitStatus == 'WAITING_FOR_PHARMACY' ||
          visitStatus == 'PHARMACY_IN_PROGRESS';

      stages.add(JourneyStage(
        id: 'PHARMACY',
        title: 'Pharmacy & Medications',
        subtitle: allDispensed
            ? 'All prescribed medications dispensed'
            : (anyDispensed
                ? 'Partially dispensed'
                : 'Medications awaiting dispensing'),
        status: allDispensed
            ? JourneyStageStatus.completed
            : ((isPharmNow || anyDispensed)
                ? JourneyStageStatus.inProgress
                : JourneyStageStatus.pending),
      ));
    }

    // 7. In-Patient Admission (If admission was requested)
    if (admissionRequest != null ||
        visitStatus == 'ADMITTED' ||
        visitStatus == 'WAITING_FOR_BED' ||
        visitStatus == 'ADMISSION_REQUESTED') {
      final admStatus = admissionRequest?.status.toUpperCase() ?? visitStatus;
      final isAdmDone = admStatus == 'DISCHARGED';
      final isAdmNow = admStatus == 'ADMITTED' || admStatus == 'WAITING_FOR_BED' || admStatus == 'REQUESTED';

      stages.add(JourneyStage(
        id: 'ADMISSION',
        title: 'Ward In-Patient Care',
        subtitle: isAdmDone
            ? 'Ward stay concluded'
            : (admStatus == 'ADMITTED'
                ? 'Admitted in ${admissionRequest?.assignedWardName ?? 'Ward'} (Bed ${admissionRequest?.assignedBedNumber ?? '-'})'
                : (admStatus == 'WAITING_FOR_BED'
                    ? 'Admission approved - waiting for bed assignment'
                    : 'Admission requested by physician')),
        status: isAdmDone
            ? JourneyStageStatus.completed
            : (isAdmNow ? JourneyStageStatus.inProgress : JourneyStageStatus.pending),
      ));
    }

    // 8. Discharge & Conclusion
    final isDischarged = visitStatus == 'DISCHARGED' || careStage == 'DISCHARGED';
    final isReadyDischarge = visitStatus == 'READY_FOR_DISCHARGE' || careStage == 'READY_FOR_DISCHARGE';

    stages.add(JourneyStage(
      id: 'DISCHARGE',
      title: 'Formal Discharge & Exit',
      subtitle: isDischarged
          ? 'Patient formally discharged'
          : (isReadyDischarge ? 'Cleared for discharge' : 'Discharge upon completion of treatment'),
      status: isDischarged
          ? JourneyStageStatus.completed
          : (isReadyDischarge ? JourneyStageStatus.inProgress : JourneyStageStatus.pending),
    ));

    return stages;
  }
}
