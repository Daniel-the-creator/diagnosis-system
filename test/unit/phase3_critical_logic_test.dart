import 'package:flutter_test/flutter_test.dart';
import 'package:diagnosis_system/models/queue_item_model.dart';
import 'package:diagnosis_system/models/visit_model.dart';
import 'package:diagnosis_system/models/invoice_model.dart';
import 'package:diagnosis_system/models/medication_model.dart';
import 'package:diagnosis_system/models/prescription_model.dart';
import 'package:diagnosis_system/models/admission_models.dart';
import 'package:diagnosis_system/models/staff_schedule_model.dart';
import 'package:diagnosis_system/core/utils/data_validator.dart';
import 'package:diagnosis_system/services/analytics/analytics_service.dart';
import 'package:diagnosis_system/services/reports/report_export_service.dart';

void main() {
  group('Phase 3 Critical Queue Logic Tests', () {
    final now = DateTime.now();

    test(
        '1. Priority weight order: Critical Emergency > Emergency > Urgent > Regular',
        () {
      expect(Priority.criticalEmergency.weight,
          greaterThan(Priority.emergency.weight));
      expect(Priority.emergency.weight, greaterThan(Priority.urgent.weight));
      expect(Priority.urgent.weight, greaterThan(Priority.regular.weight));
    });

    test('2. Same-priority FIFO sorting logic', () {
      final item1 = QueueItemModel(
        queueId: 'Q-1',
        queueNumber: 'REG-001',
        patientId: 'P-1',
        visitId: 'V-1',
        departmentId: 'REG',
        departmentName: 'Registration',
        priority: Priority.regular.toMap(),
        status: QueueStatus.waiting,
        createdAt: now.subtract(const Duration(minutes: 20)),
      );

      final item2 = QueueItemModel(
        queueId: 'Q-2',
        queueNumber: 'REG-002',
        patientId: 'P-2',
        visitId: 'V-2',
        departmentId: 'REG',
        departmentName: 'Registration',
        priority: Priority.regular.toMap(),
        status: QueueStatus.waiting,
        createdAt: now.subtract(const Duration(minutes: 10)),
      );

      final queue = [item2, item1];
      queue.sort((a, b) {
        final pw = b.priorityWeight.compareTo(a.priorityWeight);
        if (pw != 0) return pw;
        return a.createdAt.compareTo(b.createdAt);
      });

      // item1 arrived earlier, so it must be first (FIFO)
      expect(queue.first.queueId, equals('Q-1'));
      expect(queue.last.queueId, equals('Q-2'));
    });

    test(
        '3. Higher priority preempts earlier regular arrivals in waiting queue',
        () {
      final regularEarly = QueueItemModel(
        queueId: 'Q-REG',
        queueNumber: 'DOC-001',
        patientId: 'P-1',
        visitId: 'V-1',
        departmentId: 'DOC',
        departmentName: 'Doctor',
        priority: Priority.regular.toMap(),
        status: QueueStatus.waiting,
        createdAt: now.subtract(const Duration(minutes: 30)),
      );

      final emergencyLate = QueueItemModel(
        queueId: 'Q-EMG',
        queueNumber: 'DOC-002',
        patientId: 'P-2',
        visitId: 'V-2',
        departmentId: 'DOC',
        departmentName: 'Doctor',
        priority: Priority.emergency.toMap(),
        status: QueueStatus.waiting,
        createdAt: now.subtract(const Duration(minutes: 5)),
      );

      final criticalLatest = QueueItemModel(
        queueId: 'Q-CRIT',
        queueNumber: 'DOC-003',
        patientId: 'P-3',
        visitId: 'V-3',
        departmentId: 'DOC',
        departmentName: 'Doctor',
        priority: Priority.criticalEmergency.toMap(),
        status: QueueStatus.waiting,
        createdAt: now,
      );

      final queue = [regularEarly, emergencyLate, criticalLatest];
      queue.sort((a, b) {
        final pw = b.priorityWeight.compareTo(a.priorityWeight);
        if (pw != 0) return pw;
        return a.createdAt.compareTo(b.createdAt);
      });

      expect(queue[0].queueId, equals('Q-CRIT'));
      expect(queue[1].queueId, equals('Q-EMG'));
      expect(queue[2].queueId, equals('Q-REG'));
    });

    test('4. Queue state transitions and terminal states validation', () {
      // Valid transitions
      expect(
          HospitalDataValidator.isValidQueueTransition(
              QueueStatus.waiting, QueueStatus.called),
          isTrue);
      expect(
          HospitalDataValidator.isValidQueueTransition(
              QueueStatus.called, QueueStatus.inProgress),
          isTrue);
      expect(
          HospitalDataValidator.isValidQueueTransition(
              QueueStatus.inProgress, QueueStatus.completed),
          isTrue);
      expect(
          HospitalDataValidator.isValidQueueTransition(
              QueueStatus.waiting, QueueStatus.noShow),
          isTrue);
      expect(
          HospitalDataValidator.isValidQueueTransition(
              QueueStatus.waiting, QueueStatus.transferred),
          isTrue);

      // Invalid transitions
      expect(
          HospitalDataValidator.isValidQueueTransition(
              QueueStatus.completed, QueueStatus.waiting),
          isFalse);
      expect(
          HospitalDataValidator.isValidQueueTransition(
              QueueStatus.cancelled, QueueStatus.inProgress),
          isFalse);
      expect(
          HospitalDataValidator.isValidQueueTransition(
              QueueStatus.noShow, QueueStatus.called),
          isFalse);
    });
  });

  group('Phase 3 Critical Billing Tests', () {
    test('1. Invoice totals, partial payments, full payment, and balance', () {
      final invoice = InvoiceModel(
        invoiceId: 'INV-100',
        patientId: 'PAT-1',
        patientName: 'Alice',
        visitId: 'VIS-1',
        items: const [
          InvoiceItemModel(
              description: 'Doctor Consultation',
              category: 'CONSULTATION',
              unitPrice: 80.0,
              quantity: 1,
              total: 80.0),
          InvoiceItemModel(
              description: 'Laboratory FBC',
              category: 'LABORATORY',
              unitPrice: 40.0,
              quantity: 1,
              total: 40.0),
        ],
        subtotal: 120.0,
        discount: 20.0,
        total: 100.0,
        amountPaid: 0.0,
        balance: 100.0,
        status: 'PENDING',
        createdAt: DateTime.now(),
      );

      expect(invoice.total, equals(100.0));
      expect(invoice.balance, equals(100.0));
      expect(invoice.isPending, isTrue);

      // Partial payment
      final partial = invoice.copyWith(
          amountPaid: 60.0, balance: 40.0, status: 'PARTIALLY_PAID');
      expect(partial.isPartiallyPaid, isTrue);
      expect(partial.balance, equals(40.0));

      // Full payment
      final paid =
          partial.copyWith(amountPaid: 100.0, balance: 0.0, status: 'PAID');
      expect(paid.isPaid, isTrue);
      expect(paid.balance, equals(0.0));
    });

    test('2. Negative payments and over-payments are strictly rejected', () {
      final invoice = InvoiceModel(
        invoiceId: 'INV-101',
        patientId: 'P-1',
        visitId: 'V-1',
        items: const [],
        subtotal: 50.0,
        total: 50.0,
        amountPaid: 20.0,
        balance: 30.0,
        status: 'PARTIALLY_PAID',
        createdAt: DateTime.now(),
      );

      // Negative amount rejected
      expect(
          () => HospitalDataValidator.validatePayment(
              invoice: invoice, paymentAmount: -10.0),
          throwsArgumentError);
      expect(
          () => HospitalDataValidator.validatePayment(
              invoice: invoice, paymentAmount: 0.0),
          throwsArgumentError);

      // Payment exceeding remaining balance rejected
      expect(
          () => HospitalDataValidator.validatePayment(
              invoice: invoice, paymentAmount: 40.0),
          throwsArgumentError);

      // Valid payment allowed
      expect(
          () => HospitalDataValidator.validatePayment(
              invoice: invoice, paymentAmount: 30.0),
          returnsNormally);
    });
  });

  group('Phase 3 Critical Pharmacy Tests', () {
    final now = DateTime.now();
    final med = MedicationModel(
      medicationId: 'MED-1',
      drugName: 'Amoxicillin 500mg',
      genericName: 'Amoxicillin',
      category: 'ANTIBIOTIC',
      unitPrice: 2.5,
      quantity: 10,
      minimumStockLevel: 5,
      expiryDate: now.add(const Duration(days: 180)),
      createdAt: now,
      updatedAt: now,
    );

    final rx = PrescriptionModel(
      prescriptionId: 'RX-1',
      patientId: 'P-1',
      visitId: 'V-1',
      consultationId: 'C-1',
      doctorId: 'D-1',
      doctorName: 'Dr. John',
      medicationName: 'Amoxicillin 500mg',
      quantity: 15,
      dispensedQuantity: 5,
      status: 'PARTIALLY_DISPENSED',
      createdAt: DateTime.now(),
    );

    test('1. Valid medication dispensing deduction calculation', () {
      expect(rx.remaining, equals(10));
      expect(
          () => HospitalDataValidator.validateDispensing(
                prescription: rx,
                medication: med,
                dispenseQuantity: 5,
              ),
          returnsNormally);
    });

    test('2. Insufficient stock prevention', () {
      // Trying to dispense 15 when med only has 10 units in stock
      final medLow = med.copyWith(stockQuantity: 4);
      expect(
          () => HospitalDataValidator.validateDispensing(
                prescription: rx,
                medication: medLow,
                dispenseQuantity: 6,
              ),
          throwsStateError);
    });

    test('3. Expired medication cannot be dispensed', () {
      final expiredMed = med.copyWith(
        expiryDate: DateTime.now().subtract(const Duration(days: 10)),
      );
      expect(expiredMed.isExpired, isTrue);
      expect(
          () => HospitalDataValidator.validateDispensing(
                prescription: rx,
                medication: expiredMed,
                dispenseQuantity: 2,
              ),
          throwsStateError);
    });
  });

  group('Phase 3 Critical Admission & Bed Tests', () {
    const availableBed = BedModel(
      bedId: 'BED-101',
      wardId: 'WARD-A',
      wardName: 'General Ward A',
      bedNumber: 'A-101',
      status: 'AVAILABLE',
    );

    const occupiedBed = BedModel(
      bedId: 'BED-102',
      wardId: 'WARD-A',
      wardName: 'General Ward A',
      bedNumber: 'A-102',
      status: 'OCCUPIED',
      currentAdmissionId: 'ADM-EXISTING',
    );

    final admReq = AdmissionRequestModel(
      admissionRequestId: 'ADM-NEW',
      patientId: 'PAT-1',
      visitId: 'VIS-1',
      doctorId: 'DOC-1',
      reason: 'Surgical recovery',
      status: 'APPROVED',
      requestedAt: DateTime.now(),
    );

    test('1. Bed availability validation', () {
      expect(
          () => HospitalDataValidator.validateBedAssignment(
                bed: availableBed,
                admission: admReq,
              ),
          returnsNormally);
    });

    test('2. Duplicate bed prevention prevents assigning already occupied bed',
        () {
      expect(
          () => HospitalDataValidator.validateBedAssignment(
                bed: occupiedBed,
                admission: admReq,
              ),
          throwsStateError);
    });
  });

  group('Phase 3 Staff Scheduling Conflict Tests', () {
    final today = DateTime.now();

    final schedule1 = StaffScheduleModel(
      scheduleId: 'SCH-1',
      staffId: 'DOC-1',
      staffName: 'Dr. Sarah',
      role: 'doctor',
      departmentCode: 'GEN',
      departmentName: 'General OPD',
      date: today,
      startTime: '08:00',
      endTime: '14:00',
      roomId: '101',
      roomName: 'Room 101',
      createdAt: today,
    );

    test('1. Overlapping shift detection for same staff member', () {
      // Overlaps 10:00 - 16:00
      expect(
          schedule1.overlapsWith(
            otherDate: today,
            otherStart: '10:00',
            otherEnd: '16:00',
          ),
          isTrue);

      // Non-overlapping: earlier shift
      expect(
          schedule1.overlapsWith(
            otherDate: today,
            otherStart: '06:00',
            otherEnd: '08:00',
          ),
          isFalse);

      // Non-overlapping: later shift
      expect(
          schedule1.overlapsWith(
            otherDate: today,
            otherStart: '14:00',
            otherEnd: '20:00',
          ),
          isFalse);

      // Non-overlapping: different date
      expect(
          schedule1.overlapsWith(
            otherDate: today.add(const Duration(days: 1)),
            otherStart: '08:00',
            otherEnd: '14:00',
          ),
          isFalse);
    });
  });

  group('Phase 3 Timestamp Analytics & Report Tests', () {
    final analytics = AnalyticsService();
    final reports = ReportExportService();
    final start = DateTime(2026, 9, 28, 9, 0);

    test('1. Accurate waiting and service time from actual timestamps', () {
      final item = QueueItemModel(
        queueId: 'Q-TEST',
        queueNumber: 'DOC-099',
        patientId: 'P-1',
        visitId: 'V-1',
        departmentId: 'DOC',
        departmentName: 'Doctor',
        priority: Priority.regular.toMap(),
        status: QueueStatus.completed,
        createdAt: start,
        calledAt: start.add(const Duration(minutes: 15)),
        serviceStartedAt: start.add(const Duration(minutes: 15)),
        completedAt: start.add(const Duration(minutes: 35)),
      );

      final stats = analytics.computeDepartmentStats(
        deptCode: 'DOC',
        deptName: 'Doctor',
        items: [item],
      );

      // 15 min wait, 20 min service
      expect(stats.avgWaitingMinutes, equals(15.0));
      expect(stats.avgServiceMinutes, equals(20.0));
      expect(stats.completedCount, equals(1));
    });

    test('2. RFC-4180 CSV Export Generation', () {
      final headers = ['ID', 'Name', 'Status'];
      final rows = [
        ['1', 'General Hospital, Central', 'ACTIVE'],
        ['2', 'Dr. "Smith" & Partners', 'COMPLETED'],
      ];

      final csv = reports.toCsv(headers: headers, rows: rows);
      expect(csv.contains('ID,Name,Status'), isTrue);
      // Properly escaped comma and quotes
      expect(csv.contains('"General Hospital, Central"'), isTrue);
      expect(csv.contains('"Dr. ""Smith"" & Partners"'), isTrue);
    });
  });
}
