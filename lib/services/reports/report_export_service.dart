import 'package:intl/intl.dart';
import '../../models/visit_model.dart';
import '../../models/queue_item_model.dart';
import '../../models/diagnostic_request_model.dart';
import '../../models/prescription_model.dart';
import '../../models/invoice_model.dart';
import '../../models/admission_models.dart';
import '../../models/user_model.dart';

enum ReportType {
  dailyPatients,
  departmentPerformance,
  queuePerformance,
  diagnostics,
  pharmacy,
  admissions,
  discharges,
  revenue,
  staffPerformance,
}

extension ReportTypeExtension on ReportType {
  String get displayName {
    switch (this) {
      case ReportType.dailyPatients:
        return 'Daily Patient Report';
      case ReportType.departmentPerformance:
        return 'Department Performance Report';
      case ReportType.queuePerformance:
        return 'Queue Performance Report';
      case ReportType.diagnostics:
        return 'Diagnostic Services Report';
      case ReportType.pharmacy:
        return 'Pharmacy & Dispensing Report';
      case ReportType.admissions:
        return 'Inpatient Admission Report';
      case ReportType.discharges:
        return 'Patient Discharge Report';
      case ReportType.revenue:
        return 'Financial & Revenue Report';
      case ReportType.staffPerformance:
        return 'Staff Operations Report';
    }
  }
}

/// Service to format and export hospital operational and analytical reports as CSV and printable text.
class ReportExportService {
  /// Converts a table of headers and rows into clean RFC-4180 compliant CSV format.
  String toCsv({
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) {
    final buffer = StringBuffer();

    // Headers
    buffer.writeln(headers.map(_escapeCsvCell).join(','));

    // Rows
    for (final row in rows) {
      buffer.writeln(row.map(_escapeCsvCell).join(','));
    }

    return buffer.toString();
  }

  String _escapeCsvCell(dynamic value) {
    if (value == null) return '';
    String str = value.toString();
    if (str.contains(',') || str.contains('"') || str.contains('\n')) {
      str = '"${str.replaceAll('"', '""')}"';
    }
    return str;
  }

  // ── 1. Daily Patients Report ─────────────────────────────────────
  String generateDailyPatientReport({
    required List<VisitModel> visits,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final headers = [
      'Visit ID',
      'Patient ID',
      'Arrival Date/Time',
      'Patient Type',
      'Priority',
      'Department',
      'Status',
      'Completed',
      'Doctor'
    ];

    final rows = visits.map((v) => [
          v.visitId,
          v.patientId,
          dateFormat.format(v.arrivalTime),
          v.patientType,
          v.priority.label,
          v.currentDepartment,
          v.currentStatus,
          v.completed ? 'YES' : 'NO',
          v.assignedDoctorName ?? v.assignedDoctorId ?? 'N/A',
        ]).toList();

    return toCsv(headers: headers, rows: rows);
  }

  // ── 2. Department Performance Report ─────────────────────────────
  String generateDepartmentPerformanceReport({
    required Map<String, Map<String, dynamic>> deptMetrics,
  }) {
    final headers = [
      'Department Code',
      'Department Name',
      'Total Served',
      'Currently Waiting',
      'In Service',
      'Avg Waiting Time (min)',
      'Avg Service Time (min)',
    ];

    final rows = deptMetrics.entries.map((e) {
      final m = e.value;
      return [
        e.key,
        m['name'] ?? e.key,
        m['completed'] ?? 0,
        m['waiting'] ?? 0,
        m['inService'] ?? 0,
        m['avgWait'] ?? '0.0',
        m['avgService'] ?? '0.0',
      ];
    }).toList();

    return toCsv(headers: headers, rows: rows);
  }

  // ── 3. Queue Performance Report ──────────────────────────────────
  String generateQueuePerformanceReport({
    required List<QueueItemModel> items,
  }) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    final headers = [
      'Queue Number',
      'Department',
      'Priority',
      'Status',
      'Created At',
      'Called At',
      'Service Started At',
      'Completed At',
      'Wait Duration (min)',
      'Service Duration (min)',
      'Assigned Room'
    ];

    final rows = items.map((i) {
      final waitMin = (i.calledAt ?? i.serviceStartedAt) != null
          ? (i.calledAt ?? i.serviceStartedAt)!.difference(i.createdAt).inMinutes
          : 'N/A';
      final servMin = i.completedAt != null && i.serviceStartedAt != null
          ? i.completedAt!.difference(i.serviceStartedAt!).inMinutes
          : 'N/A';

      return [
        i.queueNumber,
        i.departmentName,
        i.priorityLabel,
        i.status.displayLabel,
        dateFormat.format(i.createdAt),
        i.calledAt != null ? dateFormat.format(i.calledAt!) : 'N/A',
        i.serviceStartedAt != null ? dateFormat.format(i.serviceStartedAt!) : 'N/A',
        i.completedAt != null ? dateFormat.format(i.completedAt!) : 'N/A',
        waitMin,
        servMin,
        i.assignedRoomName ?? i.assignedRoomNumber ?? 'N/A',
      ];
    }).toList();

    return toCsv(headers: headers, rows: rows);
  }

  // ── 4. Diagnostic Report ─────────────────────────────────────────
  String generateDiagnosticReport({
    required List<DiagnosticRequestModel> requests,
  }) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final headers = [
      'Request ID',
      'Patient Name',
      'Type',
      'Test Name',
      'Status',
      'Doctor',
      'Requested At',
      'Completed At',
      'Turnaround (min)'
    ];

    final rows = requests.map((r) {
      final turnMin = r.completedAt != null
          ? r.completedAt!.difference(r.requestedAt).inMinutes
          : 'N/A';

      return [
        r.diagnosticRequestId,
        r.patientName,
        r.diagnosticType,
        r.testName,
        r.status,
        r.doctorName,
        dateFormat.format(r.requestedAt),
        r.completedAt != null ? dateFormat.format(r.completedAt!) : 'N/A',
        turnMin,
      ];
    }).toList();

    return toCsv(headers: headers, rows: rows);
  }

  // ── 5. Pharmacy Report ───────────────────────────────────────────
  String generatePharmacyReport({
    required List<PrescriptionModel> prescriptions,
  }) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final headers = [
      'Prescription ID',
      'Patient Name',
      'Doctor Name',
      'Medication',
      'Dosage',
      'Prescribed Qty',
      'Dispensed Qty',
      'Remaining',
      'Status',
      'Date'
    ];

    final rows = prescriptions.map((p) => [
          p.prescriptionId,
          p.patientName,
          p.doctorName,
          p.medicationName,
          p.dosage,
          p.quantity,
          p.dispensedQuantity,
          p.remaining,
          p.status,
          dateFormat.format(p.createdAt),
        ]).toList();

    return toCsv(headers: headers, rows: rows);
  }

  // ── 6. Admission Report ──────────────────────────────────────────
  String generateAdmissionReport({
    required List<AdmissionRequestModel> admissions,
  }) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final headers = [
      'Admission ID',
      'Patient Name',
      'Doctor',
      'Reason',
      'Ward',
      'Bed',
      'Status',
      'Admitted At',
    ];

    final rows = admissions.map((a) => [
          a.admissionRequestId,
          a.patientName,
          a.doctorName,
          a.reason,
          a.assignedWardName ?? 'N/A',
          a.assignedBedNumber ?? 'N/A',
          a.status,
          a.admittedAt != null ? dateFormat.format(a.admittedAt!) : 'N/A',
        ]).toList();

    return toCsv(headers: headers, rows: rows);
  }

  // ── 7. Discharge Report ──────────────────────────────────────────
  String generateDischargeReport({
    required List<AdmissionRequestModel> dischargedList,
  }) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final headers = [
      'Admission ID',
      'Patient Name',
      'Doctor',
      'Ward',
      'Admitted Date',
      'Discharged Date',
      'Length of Stay (Days)',
    ];

    final rows = dischargedList.where((a) => a.status == 'DISCHARGED').map((a) {
      final days = (a.dischargedAt != null && a.admittedAt != null)
          ? (a.dischargedAt!.difference(a.admittedAt!).inHours / 24.0).toStringAsFixed(1)
          : 'N/A';

      return [
        a.admissionRequestId,
        a.patientName,
        a.doctorName,
        a.assignedWardName ?? 'N/A',
        a.admittedAt != null ? dateFormat.format(a.admittedAt!) : 'N/A',
        a.dischargedAt != null ? dateFormat.format(a.dischargedAt!) : 'N/A',
        days,
      ];
    }).toList();

    return toCsv(headers: headers, rows: rows);
  }

  // ── 8. Revenue Report ────────────────────────────────────────────
  String generateRevenueReport({
    required List<InvoiceModel> invoices,
  }) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final headers = [
      'Invoice ID',
      'Patient Name',
      'Total Amount',
      'Amount Paid',
      'Balance',
      'Status',
      'Created At',
      'Item Count'
    ];

    final rows = invoices.map((inv) => [
          inv.invoiceId,
          inv.patientName,
          inv.total.toStringAsFixed(2),
          inv.amountPaid.toStringAsFixed(2),
          inv.balance.toStringAsFixed(2),
          inv.status,
          dateFormat.format(inv.createdAt),
          inv.items.length,
        ]).toList();

    return toCsv(headers: headers, rows: rows);
  }

  // ── 9. Staff Performance Report ──────────────────────────────────
  String generateStaffPerformanceReport({
    required List<UserModel> staffList,
    required List<QueueItemModel> queueItems,
  }) {
    final headers = [
      'Staff ID',
      'Full Name',
      'Role',
      'Department',
      'Room',
      'Active Status',
      'Patients Handled',
      'Avg Service Duration (min)',
    ];

    final rows = staffList.map((s) {
      final staffItems = queueItems.where((q) => q.assignedStaffId == s.uid).toList();
      double totalService = 0;
      int servCount = 0;
      for (final it in staffItems) {
        if (it.completedAt != null && it.serviceStartedAt != null) {
          totalService += it.completedAt!.difference(it.serviceStartedAt!).inMinutes;
          servCount++;
        }
      }
      final avgServ = servCount > 0 ? (totalService / servCount).toStringAsFixed(1) : '0.0';

      return [
        s.uid,
        s.fullName,
        s.role,
        s.departmentId ?? 'N/A',
        s.roomId ?? 'N/A',
        s.active ? 'ACTIVE' : 'INACTIVE',
        staffItems.length,
        avgServ,
      ];
    }).toList();

    return toCsv(headers: headers, rows: rows);
  }
}
