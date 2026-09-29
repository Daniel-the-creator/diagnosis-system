import '../../models/queue_item_model.dart';
import '../../models/visit_model.dart';
import '../../models/invoice_model.dart';
import '../../models/diagnostic_request_model.dart';
import '../../models/prescription_model.dart';
import '../../models/medication_model.dart';
import '../../models/admission_models.dart';

/// Models for computed hospital operational analytics

class DepartmentQueueStats {
  final String departmentCode;
  final String departmentName;
  final int waitingCount;
  final int inServiceCount;
  final int completedCount;
  final double avgWaitingMinutes;
  final double avgServiceMinutes;

  const DepartmentQueueStats({
    required this.departmentCode,
    required this.departmentName,
    required this.waitingCount,
    required this.inServiceCount,
    required this.completedCount,
    required this.avgWaitingMinutes,
    required this.avgServiceMinutes,
  });

  int get totalActive => waitingCount + inServiceCount;
}

class WaitingTimeBreakdown {
  final double overallAvgWaitMinutes;
  final double overallAvgServiceMinutes;
  final double overallAvgJourneyMinutes;
  final Map<String, double> deptWaitMinutes;
  final Map<String, double> deptServiceMinutes;

  const WaitingTimeBreakdown({
    required this.overallAvgWaitMinutes,
    required this.overallAvgServiceMinutes,
    required this.overallAvgJourneyMinutes,
    required this.deptWaitMinutes,
    required this.deptServiceMinutes,
  });
}

class VolumeAnalyticsData {
  final Map<String, int> dailyVolumes;
  final Map<String, int> emergencyVsRegular;
  final Map<String, int> patientsByDept;
  final Map<String, int> patientsByDoctor;
  final int diagnosticCount;
  final int admissionCount;
  final int dischargeCount;

  const VolumeAnalyticsData({
    required this.dailyVolumes,
    required this.emergencyVsRegular,
    required this.patientsByDept,
    required this.patientsByDoctor,
    required this.diagnosticCount,
    required this.admissionCount,
    required this.dischargeCount,
  });
}

class DiagnosticAnalyticsData {
  final int labRequests;
  final int xrayRequests;
  final int scanRequests;
  final int completedTests;
  final int pendingTests;
  final int emergencyTests;
  final double avgCompletionMinutes;
  final Map<String, int> mostRequested;

  const DiagnosticAnalyticsData({
    required this.labRequests,
    required this.xrayRequests,
    required this.scanRequests,
    required this.completedTests,
    required this.pendingTests,
    required this.emergencyTests,
    required this.avgCompletionMinutes,
    required this.mostRequested,
  });

  int get totalRequests => labRequests + xrayRequests + scanRequests;
}

class PharmacyAnalyticsData {
  final int totalPrescriptions;
  final int dispensedPrescriptions;
  final int pendingPrescriptions;
  final int lowStockDrugs;
  final int expiredDrugs;
  final int nearExpiryDrugs;
  final double inventoryValue;
  final double pharmacyRevenue;
  final Map<String, int> mostDispensedDrugs;

  const PharmacyAnalyticsData({
    required this.totalPrescriptions,
    required this.dispensedPrescriptions,
    required this.pendingPrescriptions,
    required this.lowStockDrugs,
    required this.expiredDrugs,
    required this.nearExpiryDrugs,
    required this.inventoryValue,
    required this.pharmacyRevenue,
    required this.mostDispensedDrugs,
  });
}

class FinancialAnalyticsData {
  final double dailyRevenue;
  final double weeklyRevenue;
  final double monthlyRevenue;
  final double consultationRevenue;
  final double diagnosticRevenue;
  final double pharmacyRevenue;
  final double admissionRevenue;
  final double otherRevenue;
  final double totalRevenue;
  final double outstandingBalance;
  final double refunds;

  const FinancialAnalyticsData({
    required this.dailyRevenue,
    required this.weeklyRevenue,
    required this.monthlyRevenue,
    required this.consultationRevenue,
    required this.diagnosticRevenue,
    required this.pharmacyRevenue,
    required this.admissionRevenue,
    required this.otherRevenue,
    required this.totalRevenue,
    required this.outstandingBalance,
    required this.refunds,
  });
}

class AdmissionAnalyticsData {
  final int currentAdmissions;
  final int availableBeds;
  final int occupiedBeds;
  final double bedOccupancyPercentage;
  final int admissionsToday;
  final int dischargesToday;
  final double avgAdmissionDurationDays;
  final Map<String, int> wardOccupancy;

  const AdmissionAnalyticsData({
    required this.currentAdmissions,
    required this.availableBeds,
    required this.occupiedBeds,
    required this.bedOccupancyPercentage,
    required this.admissionsToday,
    required this.dischargesToday,
    required this.avgAdmissionDurationDays,
    required this.wardOccupancy,
  });
}

/// Central analytics engine for computing hospital performance metrics from live Firestore datasets.
class AnalyticsService {
  AnalyticsService();

  // ── 1. Department Queue Statistics & Waiting Times ──────────────

  /// Calculates waiting and service times strictly using queue item timestamps:
  /// waiting time = calledAt - createdAt (or serviceStartedAt - createdAt)
  /// service time = completedAt - serviceStartedAt
  DepartmentQueueStats computeDepartmentStats({
    required String deptCode,
    required String deptName,
    required List<QueueItemModel> items,
  }) {
    int waiting = 0;
    int inService = 0;
    int completed = 0;

    double totalWaitMinutes = 0;
    int waitSamples = 0;

    double totalServiceMinutes = 0;
    int serviceSamples = 0;

    for (final item in items) {
      if (item.departmentId != deptCode && deptCode != 'ALL') continue;

      if (item.status == QueueStatus.waiting) {
        waiting++;
      } else if (item.status == QueueStatus.inProgress || item.status == QueueStatus.called) {
        inService++;
      } else if (item.status == QueueStatus.completed) {
        completed++;
      }

      // Waiting duration calculation
      DateTime? endWait = item.calledAt ?? item.serviceStartedAt;
      if (endWait != null) {
        final waitDiff = endWait.difference(item.createdAt).inMinutes;
        if (waitDiff >= 0) {
          totalWaitMinutes += waitDiff;
          waitSamples++;
        }
      }

      // Service duration calculation
      if (item.completedAt != null && item.serviceStartedAt != null) {
        final servDiff = item.completedAt!.difference(item.serviceStartedAt!).inMinutes;
        if (servDiff >= 0) {
          totalServiceMinutes += servDiff;
          serviceSamples++;
        }
      }
    }

    final avgWait = waitSamples > 0 ? (totalWaitMinutes / waitSamples) : 0.0;
    final avgService = serviceSamples > 0 ? (totalServiceMinutes / serviceSamples) : 0.0;

    return DepartmentQueueStats(
      departmentCode: deptCode,
      departmentName: deptName,
      waitingCount: waiting,
      inServiceCount: inService,
      completedCount: completed,
      avgWaitingMinutes: double.parse(avgWait.toStringAsFixed(1)),
      avgServiceMinutes: double.parse(avgService.toStringAsFixed(1)),
    );
  }

  /// Computes granular waiting time breakdown across all operational units
  WaitingTimeBreakdown computeWaitingTimeBreakdown({
    required List<QueueItemModel> allQueueItems,
    required List<VisitModel> completedVisits,
  }) {
    final deptWait = <String, double>{};
    final deptWaitSamples = <String, int>{};

    final deptServ = <String, double>{};
    final deptServSamples = <String, int>{};

    double totalWait = 0;
    int totalWaitSamples = 0;

    double totalService = 0;
    int totalServiceSamples = 0;

    for (final q in allQueueItems) {
      final dept = q.departmentId;
      final waitEnd = q.calledAt ?? q.serviceStartedAt;
      if (waitEnd != null) {
        final diff = waitEnd.difference(q.createdAt).inMinutes;
        if (diff >= 0) {
          totalWait += diff;
          totalWaitSamples++;
          deptWait[dept] = (deptWait[dept] ?? 0) + diff;
          deptWaitSamples[dept] = (deptWaitSamples[dept] ?? 0) + 1;
        }
      }

      if (q.completedAt != null && q.serviceStartedAt != null) {
        final diff = q.completedAt!.difference(q.serviceStartedAt!).inMinutes;
        if (diff >= 0) {
          totalService += diff;
          totalServiceSamples++;
          deptServ[dept] = (deptServ[dept] ?? 0) + diff;
          deptServSamples[dept] = (deptServSamples[dept] ?? 0) + 1;
        }
      }
    }

    final computedDeptWait = <String, double>{};
    for (final entry in deptWait.entries) {
      final count = deptWaitSamples[entry.key] ?? 1;
      computedDeptWait[entry.key] = double.parse((entry.value / count).toStringAsFixed(1));
    }

    final computedDeptServ = <String, double>{};
    for (final entry in deptServ.entries) {
      final count = deptServSamples[entry.key] ?? 1;
      computedDeptServ[entry.key] = double.parse((entry.value / count).toStringAsFixed(1));
    }

    // Patient journey duration (from visit arrival to completion)
    double totalJourney = 0;
    int journeySamples = 0;
    for (final v in completedVisits) {
      if (v.completed) {
        final diff = v.updatedAt.difference(v.arrivalTime).inMinutes;
        if (diff > 0) {
          totalJourney += diff;
          journeySamples++;
        }
      }
    }

    final overallWait = totalWaitSamples > 0 ? (totalWait / totalWaitSamples) : 0.0;
    final overallServ = totalServiceSamples > 0 ? (totalService / totalServiceSamples) : 0.0;
    final overallJourney = journeySamples > 0 ? (totalJourney / journeySamples) : 0.0;

    return WaitingTimeBreakdown(
      overallAvgWaitMinutes: double.parse(overallWait.toStringAsFixed(1)),
      overallAvgServiceMinutes: double.parse(overallServ.toStringAsFixed(1)),
      overallAvgJourneyMinutes: double.parse(overallJourney.toStringAsFixed(1)),
      deptWaitMinutes: computedDeptWait,
      deptServiceMinutes: computedDeptServ,
    );
  }

  // ── 2. Patient Volume Analytics ──────────────────────────────────

  VolumeAnalyticsData computeVolumeAnalytics({
    required List<VisitModel> visits,
    required int diagnosticCount,
    required int admissionCount,
    required int dischargeCount,
  }) {
    final daily = <String, int>{};
    final emergencyVsRegular = {'REGULAR': 0, 'EMERGENCY': 0, 'CRITICAL_EMERGENCY': 0, 'URGENT': 0};
    final byDept = <String, int>{};
    final byDoctor = <String, int>{};

    for (final v in visits) {
      final dayKey =
          '${v.visitDate.year}-${v.visitDate.month.toString().padLeft(2, '0')}-${v.visitDate.day.toString().padLeft(2, '0')}';
      daily[dayKey] = (daily[dayKey] ?? 0) + 1;

      final pLevel = v.priority.level;
      emergencyVsRegular[pLevel] = (emergencyVsRegular[pLevel] ?? 0) + 1;

      final dept = v.currentDepartment.isNotEmpty ? v.currentDepartment : 'GATE';
      byDept[dept] = (byDept[dept] ?? 0) + 1;

      if (v.assignedDoctorId != null && v.assignedDoctorId!.isNotEmpty) {
        final doc = v.assignedDoctorName ?? v.assignedDoctorId!;
        byDoctor[doc] = (byDoctor[doc] ?? 0) + 1;
      }
    }

    return VolumeAnalyticsData(
      dailyVolumes: daily,
      emergencyVsRegular: emergencyVsRegular,
      patientsByDept: byDept,
      patientsByDoctor: byDoctor,
      diagnosticCount: diagnosticCount,
      admissionCount: admissionCount,
      dischargeCount: dischargeCount,
    );
  }

  // ── 3. Diagnostic Analytics ──────────────────────────────────────

  DiagnosticAnalyticsData computeDiagnosticAnalytics(List<DiagnosticRequestModel> requests) {
    int lab = 0;
    int xray = 0;
    int scan = 0;
    int completed = 0;
    int pending = 0;
    int emergency = 0;

    double totalCompletionMin = 0;
    int completionSamples = 0;
    final testFreq = <String, int>{};

    for (final r in requests) {
      if (r.diagnosticType == 'LAB') lab++;
      if (r.diagnosticType == 'XR') xray++;
      if (r.diagnosticType == 'SCAN') scan++;

      if (r.status == 'COMPLETED') {
        completed++;
        if (r.completedAt != null) {
          final diff = r.completedAt!.difference(r.requestedAt).inMinutes;
          if (diff >= 0) {
            totalCompletionMin += diff;
            completionSamples++;
          }
        }
      } else if (r.status != 'CANCELLED') {
        pending++;
      }

      if (r.priority == 'EMERGENCY' || r.priority == 'CRITICAL_EMERGENCY') {
        emergency++;
      }

      final tName = r.testName.trim();
      if (tName.isNotEmpty) {
        testFreq[tName] = (testFreq[tName] ?? 0) + 1;
      }
    }

    final avgComp = completionSamples > 0 ? (totalCompletionMin / completionSamples) : 0.0;

    return DiagnosticAnalyticsData(
      labRequests: lab,
      xrayRequests: xray,
      scanRequests: scan,
      completedTests: completed,
      pendingTests: pending,
      emergencyTests: emergency,
      avgCompletionMinutes: double.parse(avgComp.toStringAsFixed(1)),
      mostRequested: testFreq,
    );
  }

  // ── 4. Pharmacy Analytics ────────────────────────────────────────

  PharmacyAnalyticsData computePharmacyAnalytics({
    required List<PrescriptionModel> prescriptions,
    required List<MedicationModel> medications,
    required double pharmacyRevenue,
  }) {
    int dispensed = 0;
    int pending = 0;
    final drugFreq = <String, int>{};

    for (final p in prescriptions) {
      if (p.isDispensed) {
        dispensed++;
      } else if (!p.isCancelled) {
        pending++;
      }
      final drug = p.medicationName.trim();
      drugFreq[drug] = (drugFreq[drug] ?? 0) + (p.dispensedQuantity > 0 ? p.dispensedQuantity : p.quantity);
    }

    int lowStock = 0;
    int expired = 0;
    int nearExpiry = 0;
    double inventoryVal = 0;

    final now = DateTime.now();
    final in30Days = now.add(const Duration(days: 30));

    for (final m in medications) {
      inventoryVal += (m.stockQuantity * m.unitPrice);
      if (m.isLowStock) lowStock++;
      if (m.expiryDate != null) {
        if (m.expiryDate!.isBefore(now)) {
          expired++;
        } else if (m.expiryDate!.isBefore(in30Days)) {
          nearExpiry++;
        }
      }
    }

    return PharmacyAnalyticsData(
      totalPrescriptions: prescriptions.length,
      dispensedPrescriptions: dispensed,
      pendingPrescriptions: pending,
      lowStockDrugs: lowStock,
      expiredDrugs: expired,
      nearExpiryDrugs: nearExpiry,
      inventoryValue: double.parse(inventoryVal.toStringAsFixed(2)),
      pharmacyRevenue: pharmacyRevenue,
      mostDispensedDrugs: drugFreq,
    );
  }

  // ── 5. Financial Analytics ───────────────────────────────────────

  FinancialAnalyticsData computeFinancialAnalytics(List<InvoiceModel> invoices) {
    double daily = 0;
    double weekly = 0;
    double monthly = 0;

    double consult = 0;
    double diag = 0;
    double pharm = 0;
    double adm = 0;
    double other = 0;

    double totalRev = 0;
    double outstanding = 0;
    double refunds = 0;

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);

    for (final inv in invoices) {
      if (inv.status == 'CANCELLED') continue;

      if (inv.status == 'REFUNDED') {
        refunds += inv.amountPaid;
        continue;
      }

      totalRev += inv.amountPaid;
      outstanding += inv.balance;

      if (inv.createdAt.isAfter(startOfDay)) {
        daily += inv.amountPaid;
      }
      if (inv.createdAt.isAfter(startOfWeek)) {
        weekly += inv.amountPaid;
      }
      if (inv.createdAt.isAfter(startOfMonth)) {
        monthly += inv.amountPaid;
      }

      // Categorize line items
      for (final item in inv.items) {
        final cat = item.category.toUpperCase();
        if (cat == 'CONSULTATION') {
          consult += item.total;
        } else if (cat == 'LABORATORY' || cat == 'XRAY' || cat == 'SCAN') {
          diag += item.total;
        } else if (cat == 'MEDICATION') {
          pharm += item.total;
        } else if (cat == 'ADMISSION' || cat == 'BED') {
          adm += item.total;
        } else {
          other += item.total;
        }
      }
    }

    return FinancialAnalyticsData(
      dailyRevenue: double.parse(daily.toStringAsFixed(2)),
      weeklyRevenue: double.parse(weekly.toStringAsFixed(2)),
      monthlyRevenue: double.parse(monthly.toStringAsFixed(2)),
      consultationRevenue: double.parse(consult.toStringAsFixed(2)),
      diagnosticRevenue: double.parse(diag.toStringAsFixed(2)),
      pharmacyRevenue: double.parse(pharm.toStringAsFixed(2)),
      admissionRevenue: double.parse(adm.toStringAsFixed(2)),
      otherRevenue: double.parse(other.toStringAsFixed(2)),
      totalRevenue: double.parse(totalRev.toStringAsFixed(2)),
      outstandingBalance: double.parse(outstanding.toStringAsFixed(2)),
      refunds: double.parse(refunds.toStringAsFixed(2)),
    );
  }

  // ── 6. Admission Analytics ───────────────────────────────────────

  AdmissionAnalyticsData computeAdmissionAnalytics({
    required List<AdmissionRequestModel> admissions,
    required List<BedModel> beds,
    required List<WardModel> wards,
  }) {
    int currentAdm = 0;
    int admissionsToday = 0;
    int dischargesToday = 0;

    double totalDays = 0;
    int dischargedSamples = 0;

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    for (final a in admissions) {
      if (a.status == 'ADMITTED') {
        currentAdm++;
      }
      if (a.requestedAt.isAfter(startOfDay)) {
        admissionsToday++;
      }
      if (a.status == 'DISCHARGED') {
        if (a.dischargedAt != null && a.dischargedAt!.isAfter(startOfDay)) {
          dischargesToday++;
        }
        if (a.dischargedAt != null && a.admittedAt != null) {
          final diff = a.dischargedAt!.difference(a.admittedAt!).inHours / 24.0;
          if (diff >= 0) {
            totalDays += diff;
            dischargedSamples++;
          }
        }
      }
    }

    int occupied = 0;
    int available = 0;
    final wardOcc = <String, int>{};

    for (final b in beds) {
      if (b.status == 'OCCUPIED') {
        occupied++;
        final wName = b.wardId;
        wardOcc[wName] = (wardOcc[wName] ?? 0) + 1;
      } else if (b.status == 'AVAILABLE') {
        available++;
      }
    }

    final totalBeds = occupied + available;
    final occRate = totalBeds > 0 ? (occupied / totalBeds) * 100.0 : 0.0;
    final avgDuration = dischargedSamples > 0 ? (totalDays / dischargedSamples) : 0.0;

    return AdmissionAnalyticsData(
      currentAdmissions: currentAdm,
      availableBeds: available,
      occupiedBeds: occupied,
      bedOccupancyPercentage: double.parse(occRate.toStringAsFixed(1)),
      admissionsToday: admissionsToday,
      dischargesToday: dischargesToday,
      avgAdmissionDurationDays: double.parse(avgDuration.toStringAsFixed(1)),
      wardOccupancy: wardOcc,
    );
  }
}
