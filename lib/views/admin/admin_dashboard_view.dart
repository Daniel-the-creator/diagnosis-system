import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../controllers/admin_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/user_model.dart';
import '../../services/analytics/analytics_service.dart';
import '../../services/reports/report_export_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/route_constants.dart';
import '../../core/utils/app_utils.dart';
import '../../widgets/common/stat_card_widget.dart';
import '../../widgets/layout/app_scaffold.dart';
import '../../widgets/layout/sidebar_widget.dart';

/// Professional, enterprise-grade Hospital Operations & Executive Administration Dashboard.
class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key});

  static List<SidebarItem> get sidebarItems => AppScaffold.adminSidebarItems;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AdminController>();

    return AppScaffold(
      title: 'Hospital Operations & Administration',
      sidebarItems: sidebarItems,
      activeRoute: AppRoutes.adminDashboard,
      child: DefaultTabController(
        length: 7,
        child: Column(
          children: [
            // ── Tab Bar Navigation ────────────────────────────────
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: const TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                tabs: [
                  Tab(
                      icon: Icon(Icons.dashboard_outlined, size: 20),
                      text: 'Operations Overview'),
                  Tab(
                      icon: Icon(Icons.table_chart_outlined, size: 20),
                      text: 'Department Queues'),
                  Tab(
                      icon: Icon(Icons.insights_rounded, size: 20),
                      text: 'Analytics & Insights'),
                  Tab(
                      icon: Icon(Icons.badge_outlined, size: 20),
                      text: 'Staff & Schedules'),
                  Tab(
                      icon: Icon(Icons.history_edu_outlined, size: 20),
                      text: 'Audit Trails'),
                  Tab(
                      icon: Icon(Icons.summarize_outlined, size: 20),
                      text: 'Reports & Export'),
                  Tab(
                      icon: Icon(Icons.tune_rounded, size: 20),
                      text: 'System Settings'),
                ],
              ),
            ),
            const Divider(height: 1),

            // ── Tab Bar Views ─────────────────────────────────────
            Expanded(
              child: TabBarView(
                children: [
                  _OperationsOverviewTab(ctrl: ctrl),
                  _DepartmentQueuesTab(ctrl: ctrl),
                  _AnalyticsTab(ctrl: ctrl),
                  _StaffAndSchedulingTab(ctrl: ctrl),
                  _AuditLogsTab(ctrl: ctrl),
                  _ReportsTab(ctrl: ctrl),
                  _SystemSettingsTab(ctrl: ctrl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RESPONSIVE SECTION HEADER HELPER
// ─────────────────────────────────────────────────────────────────────────────
Widget _buildAdminSectionHeader({
  required BuildContext context,
  required String title,
  required String subtitle,
  Widget? action,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final isSmall = constraints.maxWidth < 650;
      if (isSmall) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.titleLarge),
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            if (action != null) ...[
              const SizedBox(height: 12),
              action,
            ],
          ],
        );
      }
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleLarge),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: 16),
            action,
          ],
        ],
      );
    },
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1: OPERATIONS OVERVIEW (12 REAL-TIME KPIS + PENDING STAFF + QUICK ACTIONS)
// ─────────────────────────────────────────────────────────────────────────────
class _OperationsOverviewTab extends StatelessWidget {
  const _OperationsOverviewTab({required this.ctrl});
  final AdminController ctrl;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final isMobile = width < 600;
      final padding = width < 420 ? 12.0 : (isMobile ? 16.0 : 28.0);

      return SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Welcome Banner ──────────────────────────────────
            _OperationsHeader(),
            SizedBox(height: isMobile ? 18 : 24),

            // ── 12 Real-Time Operational KPIs ───────────────────
            const Text('Real-Time Hospital Vitals',
                style: AppTextStyles.titleLarge),
            const SizedBox(height: 4),
            const Text(
                'Live operational census continuously updated across all active units',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            SizedBox(height: isMobile ? 12 : 16),
            Obx(() => _buildRealtimeKpiGrid(context, ctrl)),
            SizedBox(height: isMobile ? 24 : 32),

            // ── Pending Staff Approvals ─────────────────────────
            Obx(() => _PendingStaffSection(
                  pendingList: ctrl.pendingStaff.toList(),
                  onApprove: ctrl.approveStaff,
                  onReject: ctrl.rejectStaff,
                )),

            // ── Quick Department Access ─────────────────────────
            const Text('Operational Stations & Command Units',
                style: AppTextStyles.titleLarge),
            SizedBox(height: isMobile ? 12 : 16),
            _QuickActions(),
          ],
        ),
      );
    });
  }

  Widget _buildRealtimeKpiGrid(BuildContext context, AdminController ctrl) {
    final kpis = [
      (
        'Total Patients Today',
        ctrl.totalPatientsToday.value.toString(),
        Icons.people_alt_outlined,
        AppColors.primary,
        null
      ),
      (
        'Regular Patients',
        ctrl.regularPatients.value.toString(),
        Icons.person_outlined,
        AppColors.info,
        null
      ),
      (
        'Emergency Cases',
        ctrl.emergencyPatients.value.toString(),
        Icons.emergency_outlined,
        AppColors.emergency,
        'Priority flow'
      ),
      (
        'Currently Waiting',
        ctrl.waitingPatients.value.toString(),
        Icons.hourglass_top_rounded,
        AppColors.warning,
        null
      ),
      (
        'Currently in Service',
        ctrl.inProgressPatients.value.toString(),
        Icons.medical_services_outlined,
        AppColors.secondary,
        null
      ),
      (
        'Completed Visits',
        ctrl.completedVisits.value.toString(),
        Icons.check_circle_outline,
        AppColors.success,
        null
      ),
      (
        'Active Admissions',
        ctrl.activeAdmissions.value.toString(),
        Icons.hotel_rounded,
        const Color(0xFF1565C0),
        null
      ),
      (
        'Discharges Today',
        ctrl.dischargesToday.value.toString(),
        Icons.meeting_room_outlined,
        const Color(0xFF00897B),
        null
      ),
      (
        'Pending Diagnostics',
        ctrl.pendingDiagnostics.value.toString(),
        Icons.biotech_rounded,
        const Color(0xFF673AB7),
        'Lab / XR / Scan'
      ),
      (
        'Pending Payments',
        ctrl.pendingPayments.value.toString(),
        Icons.receipt_long_rounded,
        const Color(0xFFC2185B),
        'Unpaid invoices'
      ),
      (
        'Pharmacy Queue',
        ctrl.pharmacyQueue.value.toString(),
        Icons.medication_liquid_rounded,
        const Color(0xFFE65100),
        'Prescriptions'
      ),
      (
        'Available Beds',
        ctrl.availableBeds.value.toString(),
        Icons.bed_outlined,
        const Color(0xFF2E7D32),
        'Open ward beds'
      ),
    ];

    return LayoutBuilder(builder: (ctx, constraints) {
      final width = constraints.maxWidth;
      final crossCount =
          width > 1150 ? 4 : (width > 800 ? 3 : (width > 320 ? 2 : 1));
      final childAspectRatio = width > 1150
          ? 1.55
          : (width > 800 ? 1.45 : (width > 320 ? 1.30 : 2.4));
      final spacing = width > 600 ? 14.0 : 10.0;

      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: crossCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: childAspectRatio,
        children: kpis
            .map((c) => StatCardWidget(
                  title: c.$1,
                  value: c.$2,
                  icon: c.$3,
                  color: c.$4,
                  subtitle: c.$5,
                ))
            .toList(),
      );
    });
  }
}

class _OperationsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 650;
        return Container(
          padding: EdgeInsets.all(isSmall ? 16 : 24),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: isSmall
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.local_hospital_rounded,
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hospital Operations Centre',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat.yMMMMEEEEd().format(now),
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () =>
                            Get.toNamed(AppRoutes.digitalQueueDisplay),
                        icon: const Icon(Icons.tv_rounded, size: 18),
                        label: const Text('Open TV Queue Display',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.local_hospital_rounded,
                          color: Colors.white, size: 36),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hospital Operations & Administration Centre',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat.yMMMMEEEEd().format(now),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onPressed: () =>
                          Get.toNamed(AppRoutes.digitalQueueDisplay),
                      icon: const Icon(Icons.tv_rounded, size: 18),
                      label: const Text('Open TV Queue Display',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2: DEPARTMENT QUEUE MONITORING (ALL 9 UNITS WITH AVG WAIT & SERVICE TIME)
// ─────────────────────────────────────────────────────────────────────────────
class _DepartmentQueuesTab extends StatelessWidget {
  const _DepartmentQueuesTab({required this.ctrl});
  final AdminController ctrl;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isSmall = constraints.maxWidth < 700;
      return SingleChildScrollView(
        padding: EdgeInsets.all(isSmall ? 16 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAdminSectionHeader(
              context: context,
              title: 'Department Queue Monitoring',
              subtitle:
                  'Real-time queue throughput, waiting counts, and calculated service durations',
              action: OutlinedButton.icon(
                onPressed: () => Get.toNamed(AppRoutes.digitalQueueDisplay),
                icon: const Icon(Icons.tv_rounded, size: 16),
                label: const Text('TV Display Mode'),
              ),
            ),
            const SizedBox(height: 24),
            Obx(() {
              final stats = ctrl.departmentStats;
              if (stats.isEmpty) {
                return const Center(
                    child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator()));
              }

              final items = [
                (
                  'REG',
                  'Registration Desk',
                  Icons.app_registration,
                  AppColors.secondary,
                  AppRoutes.registrationDashboard
                ),
                (
                  'DOC',
                  'Consultation (Doctors)',
                  Icons.medical_services,
                  AppColors.primary,
                  AppRoutes.doctorDashboard
                ),
                (
                  'LAB',
                  'Laboratory Unit',
                  Icons.biotech,
                  const Color(0xFF673AB7),
                  AppRoutes.diagnosticDashboard
                ),
                (
                  'XR',
                  'X-Ray Department',
                  Icons.camera_indoor,
                  const Color(0xFF00897B),
                  AppRoutes.diagnosticDashboard
                ),
                (
                  'SCAN',
                  'Ultrasound & Scan',
                  Icons.radar,
                  const Color(0xFF1565C0),
                  AppRoutes.diagnosticDashboard
                ),
                (
                  'ACC',
                  'Billing & Accounts',
                  Icons.receipt_long,
                  const Color(0xFF00897B),
                  AppRoutes.accountDashboard
                ),
                (
                  'PHM',
                  'Pharmacy & Dispensary',
                  Icons.medication,
                  const Color(0xFFE65100),
                  AppRoutes.pharmacyDashboard
                ),
                (
                  'ADM',
                  'Admissions & Wards',
                  Icons.hotel,
                  const Color(0xFF283593),
                  AppRoutes.admissionDashboard
                ),
                (
                  'DIS',
                  'Discharge Lounge',
                  Icons.exit_to_app,
                  const Color(0xFF43A047),
                  AppRoutes.admissionDashboard
                ),
              ];

              return LayoutBuilder(builder: (ctx, constraints) {
                final crossCount = constraints.maxWidth > 1100
                    ? 3
                    : (constraints.maxWidth > 700 ? 2 : 1);
                final itemWidth =
                    (constraints.maxWidth - (crossCount - 1) * 16) / crossCount;

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: items.map((tuple) {
                    final stat = stats[tuple.$1] ??
                        DepartmentQueueStats(
                          departmentCode: tuple.$1,
                          departmentName: tuple.$2,
                          waitingCount: 0,
                          inServiceCount: 0,
                          completedCount: 0,
                          avgWaitingMinutes: 0.0,
                          avgServiceMinutes: 0.0,
                        );

                    return SizedBox(
                      width: itemWidth,
                      child: _DepartmentQueueCard(
                        stats: stat,
                        icon: tuple.$3,
                        accentColor: tuple.$4,
                        onDrillDown: () => Get.toNamed(tuple.$5),
                      ),
                    );
                  }).toList(),
                );
              });
            }),
          ],
        ),
      );
    });
  }
}

class _DepartmentQueueCard extends StatelessWidget {
  const _DepartmentQueueCard({
    required this.stats,
    required this.icon,
    required this.accentColor,
    required this.onDrillDown,
  });

  final DepartmentQueueStats stats;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onDrillDown;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onDrillDown,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(icon, color: accentColor, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(stats.departmentName,
                                    style: AppTextStyles.titleMedium,
                                    overflow: TextOverflow.ellipsis),
                                Text('Code: ${stats.departmentCode}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textHint)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: AppColors.textHint),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // Metrics Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSubMetric('Waiting', stats.waitingCount.toString(),
                        AppColors.warning),
                    _buildSubMetric('In Service',
                        stats.inServiceCount.toString(), AppColors.secondary),
                    _buildSubMetric('Completed',
                        stats.completedCount.toString(), AppColors.success),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Timestamp-Calculated Timing (Wrap protects against overflow on mobile)
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.schedule,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text('Avg Wait: ${stats.avgWaitingMinutes} min',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text('Avg Service: ${stats.avgServiceMinutes} min',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3: ANALYTICS & INSIGHTS (FL_CHART PATIENT VOLUME, TIMINGS, FINANCES)
// ─────────────────────────────────────────────────────────────────────────────
class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab({required this.ctrl});
  final AdminController ctrl;

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final canViewFinancials = auth.isAdmin || auth.isAccountOfficer;

    return LayoutBuilder(builder: (context, constraints) {
      final isSmall = constraints.maxWidth < 700;
      return SingleChildScrollView(
        padding: EdgeInsets.all(isSmall ? 16 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Chips (Today, 7 days, 30 days, 3 months, 1 year)
            _buildAdminSectionHeader(
              context: context,
              title: 'Executive Analytics & Volume Intelligence',
              subtitle:
                  'Calculated duration breakdowns, throughput trends, and resource utilization',
              action: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildFilterChips(ctrl),
              ),
            ),
            const SizedBox(height: 24),

            // ── Timing Analytics Section ──────────────────────────
            Obx(() {
              final timings = ctrl.waitingBreakdown.value;
              if (timings == null) return const SizedBox.shrink();

              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Timestamp-Calculated Journey Times',
                        style: AppTextStyles.titleMedium),
                    const SizedBox(height: 4),
                    const Text(
                        'Evaluated automatically from queue item transition timestamps',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 24,
                      runSpacing: 16,
                      alignment: WrapAlignment.spaceAround,
                      children: [
                        _buildTimerBadge(
                            'Overall Avg Wait',
                            '${timings.overallAvgWaitMinutes} min',
                            Icons.hourglass_empty,
                            AppColors.warning),
                        _buildTimerBadge(
                            'Overall Avg Service',
                            '${timings.overallAvgServiceMinutes} min',
                            Icons.medical_services_outlined,
                            AppColors.secondary),
                        _buildTimerBadge(
                            'Avg Total Journey',
                            '${timings.overallAvgJourneyMinutes} min',
                            Icons.route_rounded,
                            AppColors.primary),
                      ],
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),

            // ── Charts Row (fl_chart) ─────────────────────────────
            Obx(() {
              final vol = ctrl.volumeData.value;
              if (vol == null)
                return const Center(child: CircularProgressIndicator());

              return LayoutBuilder(builder: (ctx, chartConstraints) {
                final isWide = chartConstraints.maxWidth > 900;
                final pieCard = _buildPieChartCard(vol);
                final barCard = _buildBarChartCard(vol);

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: pieCard),
                      const SizedBox(width: 20),
                      Expanded(flex: 7, child: barCard),
                    ],
                  );
                }

                return Column(
                  children: [
                    pieCard,
                    const SizedBox(height: 20),
                    barCard,
                  ],
                );
              });
            }),
            const SizedBox(height: 24),

            // ── Diagnostic & Pharmacy Analytics ───────────────────
            LayoutBuilder(builder: (ctx, diagConstraints) {
              final isWide = diagConstraints.maxWidth > 800;
              final diagCard = Obx(() {
                final diag = ctrl.diagnosticData.value;
                if (diag == null) return const SizedBox.shrink();

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Diagnostics Analytics',
                          style: AppTextStyles.titleMedium),
                      const SizedBox(height: 14),
                      _buildRowStat(
                          'Lab Requests', diag.labRequests.toString()),
                      _buildRowStat(
                          'X-Ray Requests', diag.xrayRequests.toString()),
                      _buildRowStat(
                          'Scan Requests', diag.scanRequests.toString()),
                      _buildRowStat(
                          'Completed Tests', diag.completedTests.toString()),
                      _buildRowStat('Avg Turnaround Time',
                          '${diag.avgCompletionMinutes} min'),
                    ],
                  ),
                );
              });

              final pharmCard = Obx(() {
                final pharm = ctrl.pharmacyData.value;
                if (pharm == null) return const SizedBox.shrink();

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pharmacy & Inventory Analytics',
                          style: AppTextStyles.titleMedium),
                      const SizedBox(height: 14),
                      _buildRowStat('Total Prescriptions',
                          pharm.totalPrescriptions.toString()),
                      _buildRowStat(
                          'Dispensed', pharm.dispensedPrescriptions.toString()),
                      _buildRowStat(
                          'Low Stock Drugs', pharm.lowStockDrugs.toString(),
                          isAlert: pharm.lowStockDrugs > 0),
                      _buildRowStat('Expired / Near Expiry',
                          '${pharm.expiredDrugs + pharm.nearExpiryDrugs}',
                          isAlert:
                              (pharm.expiredDrugs + pharm.nearExpiryDrugs) > 0),
                      _buildRowStat('Inventory Valuation',
                          '\$${pharm.inventoryValue.toStringAsFixed(2)}'),
                    ],
                  ),
                );
              });

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: diagCard),
                    const SizedBox(width: 20),
                    Expanded(child: pharmCard),
                  ],
                );
              }

              return Column(
                children: [
                  diagCard,
                  const SizedBox(height: 20),
                  pharmCard,
                ],
              );
            }),
            const SizedBox(height: 24),

            // ── Financial Analytics (Role-Restricted) ──────────────
            if (canViewFinancials)
              Obx(() {
                final fin = ctrl.financialData.value;
                if (fin == null) return const SizedBox.shrink();

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                                'Financial Revenue & Billing Aggregation',
                                style: AppTextStyles.titleMedium,
                                overflow: TextOverflow.ellipsis),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8)),
                            child: const Text('Authorized View',
                                style: TextStyle(
                                    color: AppColors.success,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (ctx, finConstraints) {
                          final isNarrow = finConstraints.maxWidth < 650;
                          final metrics = [
                            _buildFinMetric(
                                'Daily Revenue',
                                '\$${fin.dailyRevenue.toStringAsFixed(2)}',
                                AppColors.success),
                            _buildFinMetric(
                                'Weekly Revenue',
                                '\$${fin.weeklyRevenue.toStringAsFixed(2)}',
                                AppColors.primary),
                            _buildFinMetric(
                                'Consultation Rev',
                                '\$${fin.consultationRevenue.toStringAsFixed(2)}',
                                const Color(0xFF673AB7)),
                            _buildFinMetric(
                                'Outstanding Balance',
                                '\$${fin.outstandingBalance.toStringAsFixed(2)}',
                                AppColors.warning),
                          ];

                          if (isNarrow) {
                            return GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 2.2,
                              children: metrics,
                            );
                          }

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: metrics,
                          );
                        },
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      );
    });
  }

  Widget _buildPieChartCard(VolumeAnalyticsData vol) {
    return Container(
      height: 340,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Priority Volume Distribution',
              style: AppTextStyles.titleMedium),
          const SizedBox(height: 16),
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    color: AppColors.primary,
                    value: (vol.emergencyVsRegular['REGULAR'] ?? 1).toDouble(),
                    title: 'Reg',
                    radius: 50,
                    titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                  PieChartSectionData(
                    color: AppColors.warning,
                    value: (vol.emergencyVsRegular['URGENT'] ?? 0).toDouble(),
                    title: 'Urg',
                    radius: 50,
                    titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                  PieChartSectionData(
                    color: AppColors.emergency,
                    value:
                        (vol.emergencyVsRegular['EMERGENCY'] ?? 0).toDouble(),
                    title: 'Emg',
                    radius: 50,
                    titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                  PieChartSectionData(
                    color: Colors.purple,
                    value: (vol.emergencyVsRegular['CRITICAL_EMERGENCY'] ?? 0)
                        .toDouble(),
                    title: 'Crit',
                    radius: 50,
                    titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChartCard(VolumeAnalyticsData vol) {
    return Container(
      height: 340,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Patient Volume by Operational Station',
              style: AppTextStyles.titleMedium),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 25,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final depts = ['REG', 'DOC', 'LAB', 'XR', 'PHM', 'ADM'];
                        final idx = val.toInt();
                        if (idx >= 0 && idx < depts.length) {
                          return Text(depts[idx],
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.bold));
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _makeGroupData(0, (vol.patientsByDept['REG'] ?? 0).toDouble(),
                      AppColors.secondary),
                  _makeGroupData(1, (vol.patientsByDept['DOC'] ?? 0).toDouble(),
                      AppColors.primary),
                  _makeGroupData(2, (vol.patientsByDept['LAB'] ?? 0).toDouble(),
                      const Color(0xFF673AB7)),
                  _makeGroupData(3, (vol.patientsByDept['XR'] ?? 0).toDouble(),
                      const Color(0xFF00897B)),
                  _makeGroupData(4, (vol.patientsByDept['PHM'] ?? 0).toDouble(),
                      const Color(0xFFE65100)),
                  _makeGroupData(5, (vol.patientsByDept['ADM'] ?? 0).toDouble(),
                      const Color(0xFF1565C0)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static BarChartGroupData _makeGroupData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 22,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }

  Widget _buildFilterChips(AdminController ctrl) {
    final filters = [
      'Today',
      'Last 7 days',
      'Last 30 days',
      '3 months',
      '1 year'
    ];
    return Obx(() {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: filters.map((f) {
          final isSelected = ctrl.selectedDateFilter.value == f;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(f,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal)),
              selected: isSelected,
              onSelected: (_) => ctrl.selectedDateFilter.value = f,
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildTimerBadge(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 20)),
        const SizedBox(height: 8),
        Text(label,
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRowStat(String label, String value, {bool isAlert = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isAlert ? AppColors.error : AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildFinMetric(String label, String value, Color color) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        ),
        const SizedBox(height: 4),
        Text(label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 4: STAFF MANAGEMENT & SCHEDULING (FULL CRUD + CONFLICT-FREE ROSTERS)
// ─────────────────────────────────────────────────────────────────────────────
class _StaffAndSchedulingTab extends StatelessWidget {
  const _StaffAndSchedulingTab({required this.ctrl});
  final AdminController ctrl;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isSmall = constraints.maxWidth < 700;
      return SingleChildScrollView(
        padding: EdgeInsets.all(isSmall ? 16 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAdminSectionHeader(
              context: context,
              title: 'Staff Management & Duty Scheduling',
              subtitle:
                  'Administer staff accounts, roles, departments, rooms, specialties, and conflict-checked rosters',
              action: ElevatedButton.icon(
                onPressed: () => _showCreateScheduleDialog(context, ctrl),
                icon: const Icon(Icons.add_task_rounded, size: 16),
                label: const Text('Assign Duty Schedule'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Staff Directory ───────────────────────────────────
            const Text('Hospital Staff Directory',
                style: AppTextStyles.titleMedium),
            const SizedBox(height: 12),
            Obx(() {
              final staff = ctrl.allStaff;
              if (staff.isEmpty) {
                return const Center(
                    child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No staff members registered.')));
              }

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.divider)),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: staff.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, idx) {
                    final s = staff[idx];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.12),
                        child: Text(AppUtils.getInitials(s.fullName),
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold)),
                      ),
                      title: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(s.fullName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6)),
                            child: Text(AppUtils.getRoleLabel(s.role),
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                          if (s.specialty != null && s.specialty!.isNotEmpty)
                            Text('• ${s.specialty}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                        ],
                      ),
                      subtitle: Text(
                          '${s.email} | Dept: ${s.departmentId ?? "All"} | Room: ${s.roomId ?? "N/A"}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            tooltip: 'Edit Profile & Room',
                            onPressed: () =>
                                _showEditStaffDialog(context, ctrl, s),
                          ),
                          Switch(
                            value: s.active,
                            activeThumbColor: AppColors.success,
                            onChanged: (_) => ctrl.toggleStaffStatus(s),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            }),
            const SizedBox(height: 32),

            // ── Duty Schedules Roster ─────────────────────────────
            const Text('Upcoming Active Duty Schedules',
                style: AppTextStyles.titleMedium),
            const SizedBox(height: 12),
            Obx(() {
              final scheds = ctrl.schedules;
              if (scheds.isEmpty) {
                return const Center(
                    child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No active schedules for this period.')));
              }

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.divider)),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: scheds.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, idx) {
                    final sc = scheds[idx];
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.blueGrey,
                        child: Icon(Icons.calendar_month,
                            color: Colors.white, size: 20),
                      ),
                      title: Text(
                          '${sc.staffName} (${AppUtils.getRoleLabel(sc.role)})',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          'Date: ${DateFormat.yMMMd().format(sc.date)} | Shift: ${sc.startTime} - ${sc.endTime} | Room: ${sc.roomName ?? sc.roomId ?? "N/A"}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.error, size: 20),
                        tooltip: 'Cancel Shift',
                        onPressed: () => ctrl.cancelSchedule(sc.scheduleId),
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        ),
      );
    });
  }

  void _showCreateScheduleDialog(BuildContext context, AdminController ctrl) {
    final staff = ctrl.allStaff;
    if (staff.isEmpty) {
      Get.snackbar('Notice', 'No active staff available to schedule.');
      return;
    }

    UserModel selectedUser = staff.first;
    DateTime selectedDate = DateTime.now();
    final startCtrl = TextEditingController(text: '08:00');
    final endCtrl = TextEditingController(text: '16:00');
    final roomCtrl = TextEditingController(text: '101');

    Get.dialog(
      StatefulBuilder(builder: (ctx, setState) {
        return AlertDialog(
          title: const Text('Assign Duty Schedule'),
          content: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<UserModel>(
                    initialValue: selectedUser,
                    decoration:
                        const InputDecoration(labelText: 'Staff Member'),
                    items: staff
                        .map((u) => DropdownMenuItem(
                            value: u,
                            child: Text(
                                '${u.fullName} (${AppUtils.getRoleLabel(u.role)})')))
                        .toList(),
                    onChanged: (u) => setState(() => selectedUser = u!),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                        'Date: ${DateFormat.yMMMd().format(selectedDate)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 1)),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (d != null) setState(() => selectedDate = d);
                    },
                  ),
                  TextField(
                      controller: startCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Start Time (HH:mm)')),
                  TextField(
                      controller: endCtrl,
                      decoration:
                          const InputDecoration(labelText: 'End Time (HH:mm)')),
                  TextField(
                      controller: roomCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Assigned Room (Optional)')),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Get.back(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final ok = await ctrl.createSchedule(
                  staff: selectedUser,
                  date: selectedDate,
                  startTime: startCtrl.text.trim(),
                  endTime: endCtrl.text.trim(),
                  roomId: roomCtrl.text.trim(),
                  roomName: 'Room ${roomCtrl.text.trim()}',
                );
                if (ok) Get.back();
              },
              child: const Text('Confirm Schedule'),
            ),
          ],
        );
      }),
    );
  }

  void _showEditStaffDialog(
      BuildContext context, AdminController ctrl, UserModel staff) {
    final nameCtrl = TextEditingController(text: staff.fullName);
    final roomCtrl = TextEditingController(text: staff.roomId ?? '');
    final specCtrl = TextEditingController(text: staff.specialty ?? '');
    String selectedRole = staff.role;
    String selectedDept = staff.departmentId ?? 'GEN';

    Get.dialog(
      StatefulBuilder(builder: (ctx, setState) {
        return AlertDialog(
          title: Text('Edit Profile: ${staff.fullName}'),
          content: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: nameCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Full Name')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration:
                        const InputDecoration(labelText: 'Assigned Role'),
                    items: const [
                      DropdownMenuItem(value: 'doctor', child: Text('Doctor')),
                      DropdownMenuItem(value: 'nurse', child: Text('Nurse')),
                      DropdownMenuItem(
                          value: 'pharmacist', child: Text('Pharmacist')),
                      DropdownMenuItem(
                          value: 'diagnostic_staff',
                          child: Text('Diagnostic / Lab Tech')),
                      DropdownMenuItem(
                          value: 'account_officer',
                          child: Text('Account Officer')),
                      DropdownMenuItem(
                          value: 'registration_officer',
                          child: Text('Registration Officer')),
                      DropdownMenuItem(
                          value: 'gate_officer', child: Text('Gate Officer')),
                      DropdownMenuItem(
                          value: 'admission_officer',
                          child: Text('Admission Officer')),
                      DropdownMenuItem(
                          value: 'hospital_admin',
                          child: Text('Hospital Admin')),
                    ],
                    onChanged: (r) => setState(() => selectedRole = r!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                      controller: specCtrl,
                      decoration: const InputDecoration(
                          labelText:
                              'Specialty (e.g. Pediatrics, Cardiology)')),
                  TextField(
                      controller: roomCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Default Room (e.g. 102)')),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Get.back(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                ctrl.updateStaffProfile(
                  uid: staff.uid,
                  fullName: nameCtrl.text.trim(),
                  role: selectedRole,
                  departmentId: selectedDept,
                  roomId: roomCtrl.text.trim(),
                  specialty: specCtrl.text.trim(),
                );
                Get.back();
              },
              child: const Text('Save Changes'),
            ),
          ],
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 5: AUDIT LOGS (IMMUTABLE RECORD TRAILS WITH MODULE FILTERING)
// ─────────────────────────────────────────────────────────────────────────────
class _AuditLogsTab extends StatelessWidget {
  const _AuditLogsTab({required this.ctrl});
  final AdminController ctrl;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isSmall = constraints.maxWidth < 700;
      return SingleChildScrollView(
        padding: EdgeInsets.all(isSmall ? 16 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAdminSectionHeader(
              context: context,
              title: 'System Audit Logs & Security Trails',
              subtitle:
                  'Read-only tamper-evident event log recording clinical, financial, and operational decisions',
              action: Obx(() {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: ctrl.selectedAuditModule.value,
                      items: const [
                        DropdownMenuItem(
                            value: 'ALL', child: Text('All Modules')),
                        DropdownMenuItem(
                            value: 'QUEUE', child: Text('Queue Module')),
                        DropdownMenuItem(
                            value: 'DOCTOR',
                            child: Text('Doctor Consultations')),
                        DropdownMenuItem(
                            value: 'DIAGNOSTICS',
                            child: Text('Diagnostics & Lab')),
                        DropdownMenuItem(
                            value: 'BILLING',
                            child: Text('Billing & Payments')),
                        DropdownMenuItem(
                            value: 'PHARMACY',
                            child: Text('Pharmacy Dispensing')),
                        DropdownMenuItem(
                            value: 'ADMISSION',
                            child: Text('Admissions & Beds')),
                        DropdownMenuItem(
                            value: 'STAFF',
                            child: Text('Staff Administration')),
                        DropdownMenuItem(
                            value: 'SETTINGS', child: Text('System Settings')),
                      ],
                      onChanged: (m) => ctrl.filterAuditLogs(m ?? 'ALL'),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            Obx(() {
              final logs = ctrl.auditLogs;
              if (logs.isEmpty) {
                return const Center(
                    child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text('No audit events found.')));
              }

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.divider)),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, idx) {
                    final log = logs[idx];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor:
                            _getModuleColor(log.module).withValues(alpha: 0.12),
                        child: Icon(_getModuleIcon(log.module),
                            color: _getModuleColor(log.module), size: 18),
                      ),
                      title: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          Text(log.action,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4)),
                            child: Text(log.module,
                                style: const TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Text(
                              'By: ${log.userName} (${log.role}) • Record: ${log.recordId}',
                              style: const TextStyle(fontSize: 12)),
                          if (log.details != null)
                            Text(log.details!,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('MMM d, h:mm:ss a')
                                .format(log.timestamp),
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textHint),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        ),
      );
    });
  }

  Color _getModuleColor(String mod) {
    switch (mod.toUpperCase()) {
      case 'QUEUE':
        return AppColors.secondary;
      case 'DOCTOR':
        return AppColors.primary;
      case 'DIAGNOSTICS':
        return const Color(0xFF673AB7);
      case 'BILLING':
        return const Color(0xFF00897B);
      case 'PHARMACY':
        return const Color(0xFFE65100);
      case 'ADMISSION':
        return const Color(0xFF1565C0);
      default:
        return Colors.blueGrey;
    }
  }

  IconData _getModuleIcon(String mod) {
    switch (mod.toUpperCase()) {
      case 'QUEUE':
        return Icons.people_outline;
      case 'DOCTOR':
        return Icons.medical_services_outlined;
      case 'DIAGNOSTICS':
        return Icons.biotech_outlined;
      case 'BILLING':
        return Icons.receipt_long_outlined;
      case 'PHARMACY':
        return Icons.medication_outlined;
      case 'ADMISSION':
        return Icons.hotel_outlined;
      default:
        return Icons.security_rounded;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 6: REPORTS & DATA EXPORT (ALL 9 PRE-DEFINED DOWNLOADABLE/PRINTABLE CSVs)
// ─────────────────────────────────────────────────────────────────────────────
class _ReportsTab extends StatelessWidget {
  const _ReportsTab({required this.ctrl});
  final AdminController ctrl;

  @override
  Widget build(BuildContext context) {
    final reports = [
      (
        ReportType.dailyPatients,
        Icons.people,
        'Patient census, queue arrivals, and visit outcomes'
      ),
      (
        ReportType.departmentPerformance,
        Icons.table_chart,
        'Queue wait and service times across all units'
      ),
      (
        ReportType.queuePerformance,
        Icons.access_time,
        'Detailed entry, call, start and completion queue items'
      ),
      (
        ReportType.diagnostics,
        Icons.biotech,
        'Laboratory, X-Ray, and Ultrasound turnaround metrics'
      ),
      (
        ReportType.pharmacy,
        Icons.medication,
        'Dispensed medications, dosages, and stock depletion'
      ),
      (
        ReportType.admissions,
        Icons.hotel,
        'Ward admissions, reasons, and bed occupancy'
      ),
      (
        ReportType.discharges,
        Icons.exit_to_app,
        'Discharged patients and average length of stay'
      ),
      (
        ReportType.revenue,
        Icons.receipt_long,
        'Billed invoices, amounts received, and balances'
      ),
      (
        ReportType.staffPerformance,
        Icons.badge,
        'Staff consultations, workloads, and service durations'
      ),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final isSmall = constraints.maxWidth < 700;
      return SingleChildScrollView(
        padding: EdgeInsets.all(isSmall ? 16 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Downloadable & Printable Operational Reports',
                style: AppTextStyles.titleLarge),
            const SizedBox(height: 4),
            const Text(
                'Export RFC-4180 standard CSV datasets ready for auditing, reporting, and printing',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 24),
            LayoutBuilder(builder: (ctx, constraints) {
              final crossCount = constraints.maxWidth > 950
                  ? 3
                  : (constraints.maxWidth > 650 ? 2 : 1);
              final itemWidth =
                  (constraints.maxWidth - (crossCount - 1) * 16) / crossCount;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: reports.map((r) {
                  return SizedBox(
                    width: itemWidth,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.1),
                                child: Icon(r.$2,
                                    color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Text(r.$1.displayName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14))),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(r.$3,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary),
                              maxLines: 2),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                            ),
                            onPressed: () =>
                                _previewAndDownloadReport(context, ctrl, r.$1),
                            icon: const Icon(Icons.download_rounded, size: 16),
                            label: const Text('Export & Preview',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            }),
          ],
        ),
      );
    });
  }

  void _previewAndDownloadReport(
      BuildContext context, AdminController ctrl, ReportType type) {
    final csv = ctrl.exportReport(type);
    Get.dialog(
      AlertDialog(
        title: Text(type.displayName),
        content: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Generated RFC-4180 CSV Content:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(8)),
                  child: SingleChildScrollView(
                    child: Text(csv,
                        style: const TextStyle(
                            color: Colors.greenAccent,
                            fontFamily: 'monospace',
                            fontSize: 11)),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
          ElevatedButton.icon(
            onPressed: () {
              Get.back();
              Get.snackbar(
                  'Downloaded', '${type.displayName} successfully exported.');
            },
            icon: const Icon(Icons.print_rounded, size: 16),
            label: const Text('Print / Download'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 7: SYSTEM SETTINGS (HOSPITAL METADATA, SPEECH, WORKING HOURS, PAYMENT)
// ─────────────────────────────────────────────────────────────────────────────
class _SystemSettingsTab extends StatelessWidget {
  const _SystemSettingsTab({required this.ctrl});
  final AdminController ctrl;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isSmall = constraints.maxWidth < 700;
      return SingleChildScrollView(
        padding: EdgeInsets.all(isSmall ? 16 : 28),
        child: Obx(() {
          final s = ctrl.systemSettings.value;
          final nameCtrl = TextEditingController(text: s.hospitalName);
          final tagCtrl = TextEditingController(text: s.hospitalTagline);
          final phoneCtrl = TextEditingController(text: s.phone);
          final emailCtrl = TextEditingController(text: s.email);
          final addrCtrl = TextEditingController(text: s.address);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAdminSectionHeader(
                context: context,
                title: 'Hospital System Configuration',
                subtitle:
                    'Adjust hospital identity, queue display speech parameters, and financial rules',
                action: ElevatedButton.icon(
                  onPressed: () {
                    ctrl.updateSettings(s.copyWith(
                      hospitalName: nameCtrl.text.trim(),
                      hospitalTagline: tagCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                      address: addrCtrl.text.trim(),
                    ));
                  },
                  icon: const Icon(Icons.save_rounded, size: 16),
                  label: const Text('Save All Settings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Identity Form
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Hospital Identity',
                        style: AppTextStyles.titleMedium),
                    const SizedBox(height: 16),
                    TextField(
                        controller: nameCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Hospital Name')),
                    const SizedBox(height: 12),
                    TextField(
                        controller: tagCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Tagline')),
                    const SizedBox(height: 12),
                    LayoutBuilder(builder: (ctx, c) {
                      if (c.maxWidth < 600) {
                        return Column(
                          children: [
                            TextField(
                                controller: phoneCtrl,
                                decoration: const InputDecoration(
                                    labelText: 'Contact Phone')),
                            const SizedBox(height: 12),
                            TextField(
                                controller: emailCtrl,
                                decoration: const InputDecoration(
                                    labelText: 'Contact Email')),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(
                              child: TextField(
                                  controller: phoneCtrl,
                                  decoration: const InputDecoration(
                                      labelText: 'Contact Phone'))),
                          const SizedBox(width: 16),
                          Expanded(
                              child: TextField(
                                  controller: emailCtrl,
                                  decoration: const InputDecoration(
                                      labelText: 'Contact Email'))),
                        ],
                      );
                    }),
                    const SizedBox(height: 12),
                    TextField(
                        controller: addrCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Physical Address')),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Audio & Workflow Rules
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Queue & Audio Announcements',
                        style: AppTextStyles.titleMedium),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable Voice Queue Announcements'),
                      subtitle: const Text(
                          'Plays: "Queue number DOC-024, please proceed to Room 103"'),
                      value: s.enableAudioAnnouncements,
                      onChanged: (val) => ctrl.updateSettings(
                          s.copyWith(enableAudioAnnouncements: val)),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                          'Require Payment Prior to Diagnostic Execution'),
                      subtitle: const Text(
                          'Diagnostic requests cannot begin until marked PAID at cashier'),
                      value: s.requirePaymentBeforeDiagnostics,
                      onChanged: (val) => ctrl.updateSettings(
                          s.copyWith(requirePaymentBeforeDiagnostics: val)),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('24-Hour Emergency Operation Mode'),
                      subtitle: const Text(
                          'Keep Emergency Gate and Triage units open continuously'),
                      value: s.emergencyOpen24h,
                      onChanged: (val) => ctrl
                          .updateSettings(s.copyWith(emergencyOpen24h: val)),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE DASHBOARD COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        Icons.meeting_room_rounded,
        'Gate Entry',
        AppColors.primary,
        AppRoutes.gateDashboard
      ),
      (
        Icons.how_to_reg_rounded,
        'Registration',
        AppColors.secondary,
        AppRoutes.registrationDashboard
      ),
      (
        Icons.medical_services_rounded,
        'Consultation',
        AppColors.success,
        AppRoutes.doctorDashboard
      ),
      (
        Icons.biotech_rounded,
        'Diagnostics & Lab',
        const Color(0xFF673AB7),
        AppRoutes.diagnosticDashboard
      ),
      (
        Icons.receipt_long_rounded,
        'Billing & Cashier',
        const Color(0xFF00897B),
        AppRoutes.accountDashboard
      ),
      (
        Icons.medication_rounded,
        'Pharmacy',
        const Color(0xFFE65100),
        AppRoutes.pharmacyDashboard
      ),
      (
        Icons.hotel_rounded,
        'Wards & Admissions',
        const Color(0xFF1565C0),
        AppRoutes.admissionDashboard
      ),
      (
        Icons.tv_rounded,
        'Queue Display TV',
        const Color(0xFF0284C7),
        AppRoutes.digitalQueueDisplay
      ),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final isSmall = constraints.maxWidth < 650;
      if (isSmall) {
        final isVeryNarrow = constraints.maxWidth < 360;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isVeryNarrow ? 1 : 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: isVeryNarrow ? 4.5 : 2.7,
          children: actions.map((a) {
            return OutlinedButton.icon(
              onPressed: () => Get.offNamed(a.$4),
              icon: Icon(a.$1, color: a.$3, size: 16),
              label: Text(
                a.$2,
                style: TextStyle(
                    fontSize: 11.5, fontWeight: FontWeight.w600, color: a.$3),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: a.$3,
                side: BorderSide(color: a.$3.withValues(alpha: 0.35)),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
          }).toList(),
        );
      }

      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: actions
            .map((a) => OutlinedButton.icon(
                  onPressed: () => Get.offNamed(a.$4),
                  icon: Icon(a.$1, color: a.$3, size: 18),
                  label: Text(a.$2),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: a.$3,
                    side: BorderSide(color: a.$3.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ))
            .toList(),
      );
    });
  }
}

class _PendingStaffSection extends StatelessWidget {
  const _PendingStaffSection({
    required this.pendingList,
    required this.onApprove,
    required this.onReject,
  });
  final List<UserModel> pendingList;
  final void Function(String uid) onApprove;
  final void Function(String uid) onReject;

  @override
  Widget build(BuildContext context) {
    if (pendingList.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 6,
          children: [
            const Text('Pending Staff Verifications',
                style: AppTextStyles.titleLarge),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(12)),
              child: Text('${pendingList.length} Pending',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxWidth < 650;

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side:
                    BorderSide(color: AppColors.warning.withValues(alpha: 0.4)),
              ),
              color: AppColors.surface,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pendingList.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, idx) {
                  final staff = pendingList[idx];

                  if (isSmall) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.primaryLight,
                                child: Text(
                                    AppUtils.getInitials(staff.fullName),
                                    style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(staff.fullName,
                                        style: AppTextStyles.titleMedium),
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                          AppUtils.getRoleLabel(staff.role),
                                          style: const TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                              '${staff.email} • ${staff.phone.isNotEmpty ? staff.phone : "No phone"}',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.textSecondary)),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.error,
                                    side: const BorderSide(
                                        color: AppColors.error),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                  onPressed: () => onReject(staff.uid),
                                  icon: const Icon(Icons.close, size: 16),
                                  label: const Text('Reject'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                  onPressed: () => onApprove(staff.uid),
                                  icon: const Icon(Icons.check, size: 16),
                                  label: const Text('Approve'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }

                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Text(AppUtils.getInitials(staff.fullName),
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700)),
                    ),
                    title: Row(
                      children: [
                        Text(staff.fullName, style: AppTextStyles.titleMedium),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(AppUtils.getRoleLabel(staff.role),
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                          '${staff.email} • ${staff.phone.isNotEmpty ? staff.phone : "No phone"}',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary)),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton.icon(
                          onPressed: () => onReject(staff.uid),
                          icon: const Icon(Icons.close,
                              size: 16, color: AppColors.error),
                          label: const Text('Reject',
                              style: TextStyle(color: AppColors.error)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => onApprove(staff.uid),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Approve & Activate'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
