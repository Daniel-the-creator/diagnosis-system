import 'package:flutter_test/flutter_test.dart';
import 'package:diagnosis_system/models/visit_model.dart';
import 'package:diagnosis_system/models/diagnostic_request_model.dart';
import 'package:diagnosis_system/models/diagnostic_result_model.dart';
import 'package:diagnosis_system/models/prescription_model.dart';
import 'package:diagnosis_system/models/invoice_model.dart';
import 'package:diagnosis_system/models/admission_models.dart';
import 'package:diagnosis_system/services/workflow/workflow_engine_service.dart';

void main() {
  group('Phase 2 Dynamic Workflow Engine Tests', () {
    late WorkflowEngineService workflowEngine;
    final now = DateTime.now();

    setUp(() {
      workflowEngine = WorkflowEngineService();
    });

    VisitModel createBaseVisit({
      String status = 'ARRIVED',
      String dept = 'GATE',
      String? careStage,
    }) {
      return VisitModel(
        visitId: 'VISIT-001',
        patientId: 'PAT-001',
        visitDate: now,
        arrivalTime: now,
        patientType: 'REGULAR',
        priority: Priority.regular,
        currentDepartment: dept,
        currentStatus: status,
        careStage: careStage ?? status,
        completed: false,
        createdAt: now,
        updatedAt: now,
      );
    }

    test('Test 1 — Simple Patient Journey (Doctor -> Pharmacy -> Discharge)', () {
      final visit = createBaseVisit(
        status: 'WAITING_FOR_PHARMACY',
        dept: 'PHARM',
        careStage: 'WAITING_FOR_PHARMACY',
      );

      final rx = PrescriptionModel(
        prescriptionId: 'RX-1',
        patientId: 'PAT-001',
        patientName: 'John Doe',
        visitId: 'VISIT-001',
        consultationId: 'CONS-001',
        doctorId: 'DOC-1',
        doctorName: 'Dr. Sarah',
        medicationName: 'Amoxicillin 500mg',
        quantity: 21,
        status: 'PENDING',
        createdAt: now,
      );

      final stages = workflowEngine.computeJourney(
        visit: visit,
        prescriptions: [rx],
      );

      // Verify stages: Arrival, Registration, Consultation, Pharmacy, Discharge
      final stageIds = stages.map((s) => s.id).toList();
      expect(stageIds.contains('ARRIVAL'), isTrue);
      expect(stageIds.contains('REGISTRATION'), isTrue);
      expect(stageIds.contains('CONSULTATION'), isTrue);
      expect(stageIds.contains('PHARMACY'), isTrue);
      expect(stageIds.contains('DISCHARGE'), isTrue);
      // No diagnostics or admissions
      expect(stageIds.any((id) => id.startsWith('DIAGNOSTIC_')), isFalse);
      expect(stageIds.contains('ADMISSION'), isFalse);

      // Verify progress states
      final consultStage = stages.firstWhere((s) => s.id == 'CONSULTATION');
      expect(consultStage.isCompleted, isTrue);

      final pharmStage = stages.firstWhere((s) => s.id == 'PHARMACY');
      expect(pharmStage.isInProgress, isTrue);
    });

    test('Test 2 — Diagnostic Patient Journey (Doctor -> Account -> Lab -> Review)', () {
      final visit = createBaseVisit(
        status: 'WAITING_FOR_DIAGNOSTIC',
        dept: 'LAB',
        careStage: 'WAITING_FOR_DIAGNOSTIC',
      );

      final labReq = DiagnosticRequestModel(
        diagnosticRequestId: 'REQ-LAB-01',
        patientId: 'PAT-001',
        patientName: 'Jane Smith',
        visitId: 'VISIT-001',
        consultationId: 'CONS-001',
        doctorId: 'DOC-1',
        doctorName: 'Dr. Sarah',
        diagnosticType: 'LAB',
        testName: 'Full Blood Count (FBC)',
        status: 'WAITING',
        requestedAt: now,
      );

      final invoice = InvoiceModel(
        invoiceId: 'INV-001',
        patientId: 'PAT-001',
        patientName: 'Jane Smith',
        visitId: 'VISIT-001',
        items: const [
          InvoiceItemModel(
            description: 'Laboratory: Full Blood Count',
            category: 'LABORATORY',
            unitPrice: 50.0,
            quantity: 1,
            total: 50.0,
          ),
        ],
        subtotal: 50.0,
        total: 50.0,
        amountPaid: 50.0,
        balance: 0.0,
        status: 'PAID',
        createdAt: now,
      );

      final stages = workflowEngine.computeJourney(
        visit: visit,
        diagnosticRequests: [labReq],
        invoice: invoice,
      );

      final stageIds = stages.map((s) => s.id).toList();
      expect(stageIds.contains('BILLING'), isTrue);
      expect(stageIds.contains('DIAGNOSTIC_REQ-LAB-01'), isTrue);

      final billingStage = stages.firstWhere((s) => s.id == 'BILLING');
      expect(billingStage.isCompleted, isTrue);

      final diagStage = stages.firstWhere((s) => s.id == 'DIAGNOSTIC_REQ-LAB-01');
      expect(diagStage.isInProgress, isTrue);
    });

    test('Test 3 — Multiple Diagnostics Patient Journey (Lab + X-Ray + Scan)', () {
      final visit = createBaseVisit(
        status: 'DIAGNOSTIC_IN_PROGRESS',
        dept: 'DIAG',
        careStage: 'DIAGNOSTIC_IN_PROGRESS',
      );

      final reqs = [
        DiagnosticRequestModel(
          diagnosticRequestId: 'REQ-LAB',
          patientId: 'PAT-001',
          visitId: 'VISIT-001',
          consultationId: 'CONS-001',
          doctorId: 'DOC-1',
          doctorName: 'Dr. Sarah',
          diagnosticType: 'LAB',
          testName: 'Lipid Profile',
          status: 'COMPLETED',
          requestedAt: now,
        ),
        DiagnosticRequestModel(
          diagnosticRequestId: 'REQ-XR',
          patientId: 'PAT-001',
          visitId: 'VISIT-001',
          consultationId: 'CONS-001',
          doctorId: 'DOC-1',
          doctorName: 'Dr. Sarah',
          diagnosticType: 'XR',
          testName: 'Chest X-Ray',
          status: 'IN_PROGRESS',
          requestedAt: now,
        ),
        DiagnosticRequestModel(
          diagnosticRequestId: 'REQ-SCAN',
          patientId: 'PAT-001',
          visitId: 'VISIT-001',
          consultationId: 'CONS-001',
          doctorId: 'DOC-1',
          doctorName: 'Dr. Sarah',
          diagnosticType: 'SCAN',
          testName: 'Abdominal Ultrasound',
          status: 'WAITING',
          requestedAt: now,
        ),
      ];

      final stages = workflowEngine.computeJourney(
        visit: visit,
        diagnosticRequests: reqs,
      );

      final labStage = stages.firstWhere((s) => s.id == 'DIAGNOSTIC_REQ-LAB');
      final xrStage = stages.firstWhere((s) => s.id == 'DIAGNOSTIC_REQ-XR');
      final scanStage = stages.firstWhere((s) => s.id == 'DIAGNOSTIC_REQ-SCAN');

      expect(labStage.isCompleted, isTrue);
      expect(xrStage.isInProgress, isTrue);
      expect(scanStage.isInProgress, isTrue);
    });

    test('Test 4 — In-Patient Admission Journey (Doctor -> Ward -> Bed)', () {
      final visit = createBaseVisit(
        status: 'ADMITTED',
        dept: 'WARD',
        careStage: 'ADMITTED',
      );

      final admission = AdmissionRequestModel(
        admissionRequestId: 'ADM-001',
        patientId: 'PAT-001',
        patientName: 'Michael Brown',
        visitId: 'VISIT-001',
        doctorId: 'DOC-1',
        doctorName: 'Dr. Sarah',
        reason: 'Post-op observation',
        assignedWardId: 'WARD-A',
        assignedWardName: 'Male Surgical Ward',
        assignedBedId: 'BED-04',
        assignedBedNumber: 'B-04',
        status: 'ADMITTED',
        requestedAt: now,
      );

      final stages = workflowEngine.computeJourney(
        visit: visit,
        admissionRequest: admission,
      );

      final admStage = stages.firstWhere((s) => s.id == 'ADMISSION');
      expect(admStage.isInProgress, isTrue);
      expect(admStage.subtitle.contains('Male Surgical Ward'), isTrue);
      expect(admStage.subtitle.contains('B-04'), isTrue);
    });
  });

  group('Phase 2 Model Business Logic Tests', () {
    test('Invoice calculation, payment status and balance check', () {
      final inv = InvoiceModel(
        invoiceId: 'INV-10',
        patientId: 'PAT-1',
        patientName: 'Test Patient',
        visitId: 'VIS-1',
        items: const [
          InvoiceItemModel(description: 'Doctor Consultation', category: 'CONSULTATION', unitPrice: 100.0, quantity: 1, total: 100.0),
          InvoiceItemModel(description: 'Amoxicillin', category: 'MEDICATION', unitPrice: 20.0, quantity: 2, total: 40.0),
        ],
        subtotal: 140.0,
        discount: 10.0,
        total: 130.0,
        amountPaid: 50.0,
        balance: 80.0,
        status: 'PARTIALLY_PAID',
        createdAt: DateTime.now(),
      );

      expect(inv.isPartiallyPaid, isTrue);
      expect(inv.isPaid, isFalse);
      expect(inv.isPending, isFalse);
      expect(inv.balance, equals(80.0));
      expect(inv.items.length, equals(2));
    });

    test('Prescription dispensing calculations', () {
      final rx = PrescriptionModel(
        prescriptionId: 'RX-99',
        patientId: 'P-1',
        visitId: 'V-1',
        consultationId: 'C-1',
        doctorId: 'D-1',
        doctorName: 'Doctor',
        medicationName: 'Paracetamol',
        quantity: 20,
        dispensedQuantity: 15,
        status: 'PARTIALLY_DISPENSED',
        createdAt: DateTime.now(),
      );

      expect(rx.remaining, equals(5));
      expect(rx.isDispensed, isFalse);
      expect(rx.isCancelled, isFalse);
    });

    test('Diagnostic result release gate visibility', () {
      final unreleasedResult = DiagnosticResultModel(
        resultId: 'RES-1',
        diagnosticRequestId: 'REQ-1',
        patientId: 'P-1',
        visitId: 'V-1',
        performedBy: 'TECH-1',
        findings: 'Normal sinus rhythm',
        isReleasedToPatient: false,
        createdAt: DateTime.now(),
      );

      final releasedResult = unreleasedResult.copyWith(isReleasedToPatient: true);

      expect(unreleasedResult.isReleasedToPatient, isFalse);
      expect(releasedResult.isReleasedToPatient, isTrue);
    });
  });
}
