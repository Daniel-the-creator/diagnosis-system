import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/patient_portal_controller.dart';
import '../../services/workflow/workflow_engine_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_text_field.dart';
import '../../models/patient_model.dart';

class PatientDashboardView extends StatefulWidget {
  const PatientDashboardView({super.key});

  @override
  State<PatientDashboardView> createState() => _PatientDashboardViewState();
}

class _PatientDashboardViewState extends State<PatientDashboardView> {
  late final PatientPortalController _portalCtrl;
  final _auth = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    final patientId = _auth.patientId ?? _auth.user?.uid ?? '';
    if (Get.isRegistered<PatientPortalController>()) {
      _portalCtrl = Get.find<PatientPortalController>();
    } else {
      _portalCtrl = Get.put(
        PatientPortalController(
          patientId: patientId,
          patientRepo: Get.find(),
          visitRepo: Get.find(),
          queueRepo: Get.find(),
          diagnosticRepo: Get.find(),
          pharmacyRepo: Get.find(),
          billingRepo: Get.find(),
          appointmentRepo: Get.find(),
          notificationRepo: Get.find(),
          admissionRepo: Get.find(),
          workflowEngine: Get.find(),
        ),
      );
    }
    // Pre-populate patient profile from auth credentials to eliminate loading delay
    final user = _auth.user;
    if (user != null && _portalCtrl.patient.value == null) {
      _portalCtrl.patient.value = PatientModel(
        patientId: patientId,
        hospitalNumber: '...',
        fullName: user.fullName,
        email: user.email,
        phone: user.phone,
        gender: 'Not specified',
        createdAt: user.createdAt,
        updatedAt: user.createdAt,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 760;
    final isPhone = width < 600;

    final content = Obx(() => IndexedStack(
          index: _portalCtrl.currentTabIndex.value,
          children: [
            _buildLiveVisitTab(isPhone),
            _buildDiagnosticResultsTab(isPhone),
            _buildPrescriptionsTab(isPhone),
            _buildBillingTab(isPhone),
            _buildAppointmentsTab(isPhone),
            _buildProfileTab(isPhone),
          ],
        ));

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: _buildAppBar(isPhone),
      body: isMobile
          ? content
          : Row(
              children: [
                // Navigation rail reacts to tab index changes
                Obx(() => _buildNavigationRail()),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            ),
      bottomNavigationBar: isMobile
          ? Obx(() => BottomNavigationBar(
                currentIndex: _portalCtrl.currentTabIndex.value,
                onTap: _portalCtrl.selectTab,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: AppColors.primary,
                unselectedItemColor: AppColors.textSecondary,
                selectedFontSize: 11,
                unselectedFontSize: 10,
                items: const [
                  BottomNavigationBarItem(
                      icon: Icon(Icons.stream_rounded), label: 'Live Visit'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.biotech_rounded), label: 'Tests'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.medication_rounded), label: 'Rx'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.receipt_long_rounded), label: 'Bills'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.calendar_month_rounded),
                      label: 'Appointments'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.person_rounded), label: 'Profile'),
                ],
              ))
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar(bool isPhone) {
    return AppBar(
      elevation: 0.5,
      backgroundColor: Colors.white,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.favorite_rounded,
                color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MediFlow HMS',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.bold)),
              Text('Patient Portal',
                  style:
                      AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
      actions: [
        Obx(() {
          final count = _portalCtrl.unreadNotifications.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                color: AppColors.textPrimary),
                onPressed: _showNotificationsDialog,
              ),
              if (count > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          );
        }),
        if (!isPhone) ...[
          const SizedBox(width: 8),
          Obx(() {
            final p = _portalCtrl.patient.value;
            return Chip(
              avatar: const Icon(Icons.badge_outlined,
                  size: 16, color: AppColors.primary),
              label: Text(p?.hospitalNumber ?? 'MFP-00000',
                  style: AppTextStyles.bodySmall
                      .copyWith(fontWeight: FontWeight.bold)),
              backgroundColor: AppColors.primary.withOpacity(0.08),
            );
          }),
        ],
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Sign Out',
          icon: const Icon(Icons.logout, color: AppColors.textSecondary),
          onPressed: () => _auth.signOut(),
        ),
        const SizedBox(width: 12),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(2),
        child: Obx(() => _portalCtrl.isLoading.value ||
                _portalCtrl.isBookingAppointment.value
            ? const LinearProgressIndicator(minHeight: 2)
            : const SizedBox(height: 2)),
      ),
    );
  }

  Widget _buildNavigationRail() {
    final tabs = [
      {'icon': Icons.stream_rounded, 'label': 'Live Visit & Queue'},
      {'icon': Icons.biotech_rounded, 'label': 'Test Results'},
      {'icon': Icons.medication_rounded, 'label': 'Prescriptions'},
      {'icon': Icons.receipt_long_rounded, 'label': 'Bills & Payments'},
      {'icon': Icons.calendar_month_rounded, 'label': 'Appointments'},
      {'icon': Icons.person_rounded, 'label': 'My Health Profile'},
    ];

    return NavigationRail(
      selectedIndex: _portalCtrl.currentTabIndex.value,
      onDestinationSelected: _portalCtrl.selectTab,
      labelType: NavigationRailLabelType.all,
      backgroundColor: Colors.white,
      selectedIconTheme: const IconThemeData(color: AppColors.primary),
      selectedLabelTextStyle: AppTextStyles.bodySmall
          .copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
      unselectedLabelTextStyle:
          AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
      destinations: tabs
          .map((t) => NavigationRailDestination(
                icon: Icon(t['icon'] as IconData),
                label: Text(t['label'] as String),
              ))
          .toList(),
    );
  }

  // ── Tab 1: Live Visit & Queue ──────────────────────────────────────
  Widget _buildLiveVisitTab(bool isPhone) {
    return Obx(() {
      final queue = _portalCtrl.activeQueueItem.value;
      final isCalled = _portalCtrl.isCalled.value;
      final stages = _portalCtrl.journeyStages;

      return SingleChildScrollView(
        padding: EdgeInsets.all(isPhone ? 16 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isCalled)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF43A047)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.campaign_rounded,
                        color: Colors.white, size: 36),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'YOU HAVE BEEN CALLED!',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Please proceed to Room ${queue?.assignedRoomNumber ?? queue?.assignedRoomName ?? 'Consultation Room'}.',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Live Queue Ticket Card
            if (queue != null)
              AppCard(
                child: Padding(
                  padding: EdgeInsets.all(isPhone ? 16 : 20),
                  child: isPhone
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: AppColors.primary.withOpacity(0.2)),
                                  ),
                                  child: Column(
                                    children: [
                                      Text('YOUR TICKET',
                                          style: AppTextStyles.caption.copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10)),
                                      Text(queue.displayQueueNumber,
                                          style: AppTextStyles.h2.copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold)),
                                      Text(queue.departmentCode,
                                          style: AppTextStyles.caption.copyWith(
                                              color: AppColors.textSecondary,
                                              fontSize: 10)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(queue.departmentName,
                                          style: AppTextStyles.h4),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Room: ${queue.assignedRoomNumber ?? queue.assignedRoomName ?? 'Waiting Room'}',
                                        style: AppTextStyles.caption.copyWith(
                                            color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildMetricChip(
                                    Icons.play_circle_fill_rounded,
                                    'Now Serving',
                                    '#${_portalCtrl.nowServingNumber.value}'),
                                _buildMetricChip(
                                    Icons.people_alt_rounded,
                                    'Ahead of You',
                                    '${_portalCtrl.peopleAhead.value}'),
                                _buildMetricChip(
                                    Icons.schedule_rounded,
                                    'Est. Wait',
                                    '${_portalCtrl.peopleAhead.value * 8} mins'),
                              ],
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 16),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: AppColors.primary.withOpacity(0.2)),
                              ),
                              child: Column(
                                children: [
                                  Text('YOUR TICKET',
                                      style: AppTextStyles.caption.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold)),
                                  Text(queue.displayQueueNumber,
                                      style: AppTextStyles.h1.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 36)),
                                  Text(queue.departmentCode,
                                      style: AppTextStyles.caption.copyWith(
                                          color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 32),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(queue.departmentName,
                                      style: AppTextStyles.h3),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 8,
                                    children: [
                                      _buildMetricChip(
                                          Icons.play_circle_fill_rounded,
                                          'Now Serving',
                                          '#${_portalCtrl.nowServingNumber.value}'),
                                      _buildMetricChip(
                                          Icons.people_alt_rounded,
                                          'Ahead of You',
                                          '${_portalCtrl.peopleAhead.value}'),
                                      _buildMetricChip(
                                          Icons.schedule_rounded,
                                          'Est. Wait',
                                          '${_portalCtrl.peopleAhead.value * 8} mins'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ),

            const SizedBox(height: 28),
            const Text('Dynamic Care Pathway', style: AppTextStyles.h3),
            const SizedBox(height: 6),
            Text(
                'Real-time timeline tracking your personalized journey across hospital units.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 20),

            if (stages.isEmpty)
              const AppCard(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                        'No active visit found. When you arrive at the hospital, your journey will appear here in real time.'),
                  ),
                ),
              )
            else
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: stages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (ctx, idx) {
                      final stage = stages[idx];
                      return _buildJourneyStep(stage,
                          isLast: idx == stages.length - 1);
                    },
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildMetricChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textSecondary)),
              Text(value,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyStep(JourneyStage stage, {required bool isLast}) {
    Color color;
    IconData icon;
    if (stage.isCompleted) {
      color = AppColors.success;
      icon = Icons.check_circle_rounded;
    } else if (stage.isInProgress) {
      color = AppColors.primary;
      icon = Icons.arrow_circle_right_rounded;
    } else {
      color = AppColors.textSecondary.withOpacity(0.4);
      icon = Icons.radio_button_unchecked_rounded;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(icon, color: color, size: 24),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: stage.isCompleted
                    ? AppColors.success.withOpacity(0.4)
                    : Colors.black.withOpacity(0.1),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(stage.title,
                      style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: stage.isPending
                              ? AppColors.textSecondary
                              : AppColors.textPrimary)),
                  if (stage.timestamp != null)
                    Text(DateFormat.jm().format(stage.timestamp!),
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 4),
              Text(stage.subtitle,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tab 2: Diagnostic Results ──────────────────────────────────────
  Widget _buildDiagnosticResultsTab(bool isPhone) {
    return Obx(() {
      final results = _portalCtrl.releasedResults;

      return SingleChildScrollView(
        padding: EdgeInsets.all(isPhone ? 16 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Diagnostic & Laboratory Reports',
                style: AppTextStyles.h3),
            const SizedBox(height: 6),
            Text(
                'Official laboratory, x-ray, and scan reports released by medical specialists.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            if (results.isEmpty)
              const AppCard(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.biotech_outlined,
                            size: 48, color: AppColors.textSecondary),
                        SizedBox(height: 12),
                        Text('No released reports available at this time.'),
                      ],
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: results.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (ctx, idx) {
                  final res = results[idx];
                  return AppCard(
                    child: Padding(
                      padding: EdgeInsets.all(isPhone ? 14 : 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(res.diagnosticType,
                                        style: AppTextStyles.caption.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: Text(res.testName,
                                        style: AppTextStyles.h4),
                                  ),
                                ],
                              ),
                              Text(DateFormat.yMMMd().format(res.createdAt),
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text('Findings / Results:',
                              style: AppTextStyles.bodySmall
                                  .copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(res.findings,
                                style: AppTextStyles.bodyMedium),
                          ),
                          if (res.interpretation.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text('Clinical Interpretation:',
                                style: AppTextStyles.bodySmall
                                    .copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(res.interpretation,
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.textSecondary)),
                          ],
                          const SizedBox(height: 12),
                          Text(
                              'Performed by: ${res.performedByName.isNotEmpty ? res.performedByName : 'Diagnostic Staff'}',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      );
    });
  }

  // ── Tab 3: Prescriptions ───────────────────────────────────────────
  Widget _buildPrescriptionsTab(bool isPhone) {
    return Obx(() {
      final rxs = _portalCtrl.prescriptions;

      return SingleChildScrollView(
        padding: EdgeInsets.all(isPhone ? 16 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Prescribed Medications', style: AppTextStyles.h3),
            const SizedBox(height: 6),
            Text(
                'Prescriptions issued by your doctor with dosage directions and dispensing status.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            if (rxs.isEmpty)
              const AppCard(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.medication_outlined,
                            size: 48, color: AppColors.textSecondary),
                        SizedBox(height: 12),
                        Text('No prescriptions on record.'),
                      ],
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rxs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (ctx, idx) {
                  final rx = rxs[idx];
                  return AppCard(
                    child: Padding(
                      padding: EdgeInsets.all(isPhone ? 14 : 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: rx.isDispensed
                                  ? AppColors.success.withOpacity(0.1)
                                  : AppColors.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.medication_rounded,
                                color: rx.isDispensed
                                    ? AppColors.success
                                    : AppColors.warning,
                                size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(rx.medicationName,
                                          style: AppTextStyles.h4),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: rx.isDispensed
                                            ? AppColors.success
                                                .withOpacity(0.15)
                                            : AppColors.warning
                                                .withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        rx.status,
                                        style: TextStyle(
                                          color: rx.isDispensed
                                              ? AppColors.success
                                              : AppColors.warning,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                    'Dosage: ${rx.dosage} • Frequency: ${rx.frequency} • Duration: ${rx.duration}',
                                    style: AppTextStyles.bodyMedium),
                                if (rx.instructions.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text('Instructions: ${rx.instructions}',
                                      style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textSecondary)),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                    'Prescribed by Dr. ${rx.doctorName} on ${DateFormat.yMMMd().format(rx.createdAt)}',
                                    style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      );
    });
  }

  // ── Tab 4: Billing & Payments ──────────────────────────────────────
  Widget _buildBillingTab(bool isPhone) {
    return Obx(() {
      final invoices = _portalCtrl.invoices;

      return SingleChildScrollView(
        padding: EdgeInsets.all(isPhone ? 16 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bills & Invoices', style: AppTextStyles.h3),
            const SizedBox(height: 6),
            Text('Itemized medical charges, payments, and electronic receipts.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            if (invoices.isEmpty)
              const AppCard(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 48, color: AppColors.textSecondary),
                        SizedBox(height: 12),
                        Text('No billing records found.'),
                      ],
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: invoices.length,
                separatorBuilder: (_, __) => const SizedBox(height: 20),
                itemBuilder: (ctx, idx) {
                  final inv = invoices[idx];
                  return AppCard(
                    child: Padding(
                      padding: EdgeInsets.all(isPhone ? 16 : 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Text(
                                  'Invoice #${inv.invoiceId.substring(0, 8).toUpperCase()}',
                                  style: AppTextStyles.h4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: inv.isPaid
                                      ? AppColors.success.withOpacity(0.15)
                                      : AppColors.warning.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  inv.status,
                                  style: TextStyle(
                                    color: inv.isPaid
                                        ? AppColors.success
                                        : AppColors.warning,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 12),
                          ...inv.items.map((item) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                          '${item.description} (x${item.quantity})',
                                          style: AppTextStyles.bodyMedium),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('\$${item.total.toStringAsFixed(2)}',
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(
                                                fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              )),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Amount:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text('\$${inv.total.toStringAsFixed(2)}',
                                  style: AppTextStyles.h4
                                      .copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Amount Paid:',
                                  style: TextStyle(color: AppColors.success)),
                              Text('\$${inv.amountPaid.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Outstanding Balance:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text('\$${inv.balance.toStringAsFixed(2)}',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: inv.balance > 0
                                          ? AppColors.error
                                          : AppColors.success)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      );
    });
  }

  // Tab 5: Appointments
  Widget _buildAppointmentsTab(bool isPhone) {
    return Obx(() {
      final allApts = _portalCtrl.appointments.toList();
      // Active: only show SCHEDULED and CONFIRMED
      final activeApts = allApts
          .where((a) => a.status == 'SCHEDULED' || a.status == 'CONFIRMED')
          .toList();
      // History: CANCELLED or COMPLETED
      final historyApts = allApts
          .where((a) => a.status == 'CANCELLED' || a.status == 'COMPLETED')
          .toList();

      final err = _portalCtrl.errorMessage.value;

      return SingleChildScrollView(
        padding: EdgeInsets.all(isPhone ? 16 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isPhone
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Appointments', style: AppTextStyles.h3),
                      const SizedBox(height: 4),
                      Text(
                          'Book encounters with medical specialists or view upcoming schedules.',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          text: 'Book New Appointment',
                          icon: Icons.add_rounded,
                          onPressed: _showBookAppointmentDialog,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Appointments', style: AppTextStyles.h3),
                          const SizedBox(height: 4),
                          Text(
                              'Book encounters with medical specialists or view upcoming schedules.',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                      AppButton(
                        text: 'Book New Appointment',
                        icon: Icons.add_rounded,
                        onPressed: _showBookAppointmentDialog,
                      ),
                    ],
                  ),
            const SizedBox(height: 24),

            if (err.isNotEmpty && err.startsWith('Appointments error:'))
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(err,
                            style: const TextStyle(
                                color: AppColors.error, fontSize: 13))),
                  ],
                ),
              ),

            // ── Active appointments ───────────────────────────────
            if (activeApts.isEmpty)
              const AppCard(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 48, color: AppColors.textSecondary),
                        SizedBox(height: 12),
                        Text(
                            'No upcoming appointments. Tap "Book New Appointment" to schedule one.'),
                      ],
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activeApts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (ctx, idx) {
                  final apt = activeApts[idx];
                  final isConfirmed = apt.status == 'CONFIRMED';
                  return AppCard(
                    child: Padding(
                      padding: EdgeInsets.all(isPhone ? 14 : 20),
                      child: isPhone
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: (isConfirmed
                                                ? AppColors.success
                                                : AppColors.primary)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(Icons.calendar_month_rounded,
                                          color: isConfirmed
                                              ? AppColors.success
                                              : AppColors.primary,
                                          size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text('Dr. ${apt.doctorName}',
                                          style: AppTextStyles.h4),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: (isConfirmed
                                                ? AppColors.success
                                                : AppColors.primary)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(apt.status,
                                          style: TextStyle(
                                              color: isConfirmed
                                                  ? AppColors.success
                                                  : AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                    '${apt.departmentName} • ${DateFormat.yMMMd().format(apt.date)} at ${apt.timeSlot}',
                                    style: AppTextStyles.bodyMedium),
                                if (apt.reason.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text('Reason: ${apt.reason}',
                                      style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textSecondary)),
                                ],
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => _portalCtrl
                                        .cancelAppointment(apt.appointmentId),
                                    style: TextButton.styleFrom(
                                        foregroundColor: AppColors.error),
                                    child: const Text('Cancel Appointment'),
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: (isConfirmed
                                            ? AppColors.success
                                            : AppColors.primary)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.calendar_month_rounded,
                                      color: isConfirmed
                                          ? AppColors.success
                                          : AppColors.primary,
                                      size: 28),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Dr. ${apt.doctorName}',
                                              style: AppTextStyles.h4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: (isConfirmed
                                                      ? AppColors.success
                                                      : AppColors.primary)
                                                  .withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(apt.status,
                                                style: TextStyle(
                                                    color: isConfirmed
                                                        ? AppColors.success
                                                        : AppColors.primary,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                          '${apt.departmentName} • ${DateFormat.yMMMd().format(apt.date)} at ${apt.timeSlot}',
                                          style: AppTextStyles.bodyMedium),
                                      if (apt.reason.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text('Reason: ${apt.reason}',
                                            style: AppTextStyles.bodySmall.copyWith(
                                                color: AppColors.textSecondary)),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                TextButton(
                                  onPressed: () => _portalCtrl
                                      .cancelAppointment(apt.appointmentId),
                                  style: TextButton.styleFrom(
                                      foregroundColor: AppColors.error),
                                  child: const Text('Cancel'),
                                ),
                              ],
                            ),
                    ),
                  );
                },
              ),

            // ── History: Cancelled / Completed ────────────────────
            if (historyApts.isNotEmpty) ...[
              const SizedBox(height: 28),
              Text('Past & Cancelled',
                  style: AppTextStyles.h4
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: historyApts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, idx) {
                  final apt = historyApts[idx];
                  final isCancelled = apt.status == 'CANCELLED';
                  return AppCard(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: isPhone ? 12 : 20, vertical: isPhone ? 10 : 14),
                      child: Row(
                        children: [
                          Icon(
                            isCancelled
                                ? Icons.cancel_outlined
                                : Icons.check_circle_outline,
                            color: isCancelled
                                ? AppColors.error
                                : AppColors.textSecondary,
                            size: 28,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Dr. ${apt.doctorName}',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary)),
                                Text(
                                  '${apt.departmentName} • ${DateFormat.yMMMd().format(apt.date)} at ${apt.timeSlot}',
                                  style: AppTextStyles.bodySmall
                                      .copyWith(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (isCancelled
                                      ? AppColors.error
                                      : AppColors.textSecondary)
                                  .withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              apt.status,
                              style: TextStyle(
                                  color: isCancelled
                                      ? AppColors.error
                                      : AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      );
    });
  }

  // ── Tab 6: Profile & Health Info ──────────────────────────────────
  Widget _buildProfileTab(bool isPhone) {
    return Obx(() {
      final p = _portalCtrl.patient.value;
      if (p == null) return const Center(child: Text('Loading profile...'));

      return SingleChildScrollView(
        padding: EdgeInsets.all(isPhone ? 16 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('My Health Profile', style: AppTextStyles.h3),
            const SizedBox(height: 6),
            Text(
                'Your registered clinical information, emergency contacts, and identifiers.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            AppCard(
              child: Padding(
                padding: EdgeInsets.all(isPhone ? 16 : 24),
                child: Column(
                  children: [
                    _buildProfileRow(Icons.badge_outlined, 'Hospital ID Number',
                        p.hospitalNumber, isPhone: isPhone),
                    const Divider(),
                    _buildProfileRow(
                        Icons.person_outline, 'Full Name', p.fullName, isPhone: isPhone),
                    const Divider(),
                    _buildProfileRow(Icons.wc_outlined, 'Gender', p.gender, isPhone: isPhone),
                    const Divider(),
                    _buildProfileRow(
                        Icons.cake_outlined,
                        'Date of Birth',
                        p.dateOfBirth != null
                            ? DateFormat.yMMMd().format(p.dateOfBirth!)
                            : '—', isPhone: isPhone),
                    const Divider(),
                    _buildProfileRow(Icons.phone_outlined, 'Phone', p.phone, isPhone: isPhone),
                    const Divider(),
                    _buildProfileRow(
                        Icons.email_outlined, 'Email', p.email ?? '—', isPhone: isPhone),
                    const Divider(),
                    _buildProfileRow(
                        Icons.home_outlined, 'Address', p.address ?? '—', isPhone: isPhone),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Clinical Baseline', style: AppTextStyles.h4),
            const SizedBox(height: 12),
            AppCard(
              child: Padding(
                padding: EdgeInsets.all(isPhone ? 16 : 24),
                child: Column(
                  children: [
                    _buildProfileRow(Icons.bloodtype_outlined, 'Blood Group',
                        p.bloodGroup ?? '—', isPhone: isPhone),
                    const Divider(),
                    _buildProfileRow(
                        Icons.biotech_outlined, 'Genotype', p.genotype ?? '—', isPhone: isPhone),
                    const Divider(),
                    _buildProfileRow(
                        Icons.warning_amber_outlined,
                        'Allergies',
                        p.allergies.isNotEmpty
                            ? p.allergies.join(', ')
                            : 'None known', isPhone: isPhone),
                    const Divider(),
                    _buildProfileRow(
                        Icons.contact_phone_outlined,
                        'Emergency Contact',
                        '${p.emergencyContactName ?? '—'} (${p.emergencyContactPhone ?? '—'})', isPhone: isPhone),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildProfileRow(IconData icon, String label, String value,
      {bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: isPhone
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(label,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 26),
                  child: Text(value,
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600)),
                ),
              ],
            )
          : Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 14),
                SizedBox(
                  width: 180,
                  child: Text(label,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary)),
                ),
                Expanded(
                  child: Text(value,
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
    );
  }

  void _showBookAppointmentDialog() {
    final reasonCtrl = TextEditingController();
    DateTime pickedDate = DateTime.now().add(const Duration(days: 1));
    String pickedSlot = '09:00 AM';

    // Slots available for booking
    const slots = [
      '08:00 AM',
      '09:00 AM',
      '10:00 AM',
      '11:00 AM',
      '12:00 PM',
      '02:00 PM',
      '03:00 PM',
      '04:00 PM',
    ];

    // Fetch doctors from Firestore (users with role == 'doctor')
    final Future<List<Map<String, String>>> doctorsFuture = FirebaseFirestore
        .instance
        .collection('users')
        .where('role', isEqualTo: 'doctor')
        .get()
        .then((snap) => snap.docs.map((d) {
              final data = d.data();
              return {
                'uid': d.id,
                'name': (data['fullName'] as String?) ?? 'Unknown',
                'dept': (data['departmentId'] as String?) ?? '',
              };
            }).toList());

    Map<String, String>? selectedDoctor;

    Get.dialog(
      StatefulBuilder(builder: (context, setState) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Book an Appointment', style: AppTextStyles.h3),
                  const SizedBox(height: 20),

                  // Doctor selector
                  FutureBuilder<List<Map<String, String>>>(
                    future: doctorsFuture,
                    builder: (ctx, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 56,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final doctors = snap.data ?? [];
                      if (doctors.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'No doctors are currently registered in the system.',
                            style: TextStyle(color: AppColors.error),
                          ),
                        );
                      }
                      return DropdownButtonFormField<Map<String, String>>(
                        isExpanded: true,
                        initialValue: selectedDoctor,
                        decoration: const InputDecoration(
                          labelText: 'Select Doctor',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                        ),
                        hint: const Text('Choose a doctor'),
                        items: doctors.map((doc) {
                          return DropdownMenuItem(
                            value: doc,
                            child: Text(
                              '${doc['name']}  •  ${doc['dept']?.isNotEmpty == true ? doc['dept']! : 'General'}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => selectedDoctor = val),
                      );
                    },
                  ),
                  const SizedBox(height: 14),

                  // Date picker row
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: pickedDate,
                        firstDate: DateTime.now().add(const Duration(days: 1)),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (picked != null) setState(() => pickedDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Text(DateFormat.yMMMd().format(pickedDate),
                              style: AppTextStyles.bodyMedium),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Time slot selector
                  DropdownButtonFormField<String>(
                    initialValue: pickedSlot,
                    decoration: const InputDecoration(
                      labelText: 'Time Slot',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    items: slots
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => pickedSlot = v ?? pickedSlot),
                  ),
                  const SizedBox(height: 14),

                  AppTextField(
                    controller: reasonCtrl,
                    label: 'Reason for Visit',
                    hint: 'e.g. Follow-up consultation',
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                          onPressed: () => Get.back(),
                          child: const Text('Cancel')),
                      const SizedBox(width: 12),
                      AppButton(
                        text: 'Confirm Booking',
                        onPressed: selectedDoctor == null
                            ? null
                            : () {
                                Get.back();
                                _portalCtrl.bookAppointment(
                                  doctorId: selectedDoctor!['uid']!,
                                  doctorName: selectedDoctor!['name']!,
                                  departmentId: selectedDoctor!['dept'] ?? '',
                                  departmentName:
                                      selectedDoctor!['dept'] ?? 'General',
                                  date: pickedDate,
                                  timeSlot: pickedSlot,
                                  reason: reasonCtrl.text.trim(),
                                );
                              },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  void _showNotificationsDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Notifications', style: AppTextStyles.h3),
                    TextButton(
                      onPressed: () => _portalCtrl.markAllNotificationsRead(),
                      child: const Text('Mark all as read'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                Expanded(
                  child: Obx(() {
                    final notifs = _portalCtrl.notifications;
                    if (notifs.isEmpty) {
                      return const Center(child: Text('No notifications.'));
                    }
                    return ListView.separated(
                      itemCount: notifs.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (ctx, idx) {
                        final n = notifs[idx];
                        return ListTile(
                          leading: Icon(
                            n.read
                                ? Icons.notifications_none
                                : Icons.notifications_active,
                            color: n.read
                                ? AppColors.textSecondary
                                : AppColors.primary,
                          ),
                          title: Text(n.title,
                              style: TextStyle(
                                  fontWeight: n.read
                                      ? FontWeight.normal
                                      : FontWeight.bold)),
                          subtitle: Text(n.body),
                          trailing: Text(DateFormat.jm().format(n.createdAt),
                              style: AppTextStyles.caption),
                          onTap: () => _portalCtrl
                              .markNotificationRead(n.notificationId),
                        );
                      },
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                      onPressed: () => Get.back(), child: const Text('Close')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
