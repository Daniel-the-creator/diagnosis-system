import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/doctor_controller.dart';
import '../../models/patient_model.dart';
import '../../models/visit_model.dart';
import '../../models/queue_item_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/route_constants.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/layout/app_scaffold.dart';
import '../../widgets/layout/sidebar_widget.dart';
import '../../widgets/queue/queue_item_card.dart';
import '../../widgets/common/app_text_field.dart';
import '../../core/utils/app_utils.dart';

class DoctorDashboardView extends StatelessWidget {
  const DoctorDashboardView({super.key});

  static const List<SidebarItem> _staffSidebar = [
    SidebarItem(
        icon: Icons.medical_services,
        label: 'Consultation Queue',
        route: AppRoutes.doctorDashboard),
  ];

  static const List<SidebarItem> _adminSidebar = [
    SidebarItem(
        icon: Icons.dashboard,
        label: 'Dashboard',
        route: AppRoutes.adminDashboard),
    SidebarItem(
        icon: Icons.meeting_room,
        label: 'Gate',
        route: AppRoutes.gateDashboard),
    SidebarItem(
        icon: Icons.app_registration,
        label: 'Registration',
        route: AppRoutes.registrationDashboard),
    SidebarItem(
        icon: Icons.medical_services,
        label: 'Consultation Queue',
        route: AppRoutes.doctorDashboard),
    SidebarItem(
        icon: Icons.biotech,
        label: 'Diagnostics',
        route: AppRoutes.diagnosticDashboard),
    SidebarItem(
        icon: Icons.receipt_long,
        label: 'Billing & Cashier',
        route: AppRoutes.accountDashboard),
    SidebarItem(
        icon: Icons.medication,
        label: 'Pharmacy',
        route: AppRoutes.pharmacyDashboard),
    SidebarItem(
        icon: Icons.hotel,
        label: 'Admissions',
        route: AppRoutes.admissionDashboard),
  ];

  static List<SidebarItem> get staffSidebar => _staffSidebar;
  static List<SidebarItem> get adminSidebar => _adminSidebar;

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final isAdmin = auth.user?.isAdmin ?? false;
    return AppScaffold(
      title: 'Doctor Clinical Workspace',
      sidebarItems: isAdmin ? _adminSidebar : _staffSidebar,
      activeRoute: AppRoutes.doctorDashboard,
      child: const _DoctorBody(),
    );
  }
}

class _DoctorBody extends StatelessWidget {
  const _DoctorBody();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<DoctorController>();
    final auth = Get.find<AuthController>();
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth > 900;
    final queueWidth = screenWidth > 1300 ? 380.0 : (screenWidth > 1050 ? 330.0 : 300.0);

    // Wire up appointment stream with doctor's UID immediately and post-frame
    final currentUid = auth.user?.uid ?? '';
    final isAdmin = auth.isAdmin;
    if (currentUid.isNotEmpty || isAdmin) {
      ctrl.setDoctorId(currentUid, isAdmin: isAdmin);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = auth.user?.uid ?? '';
      final adm = auth.isAdmin;
      if (uid.isNotEmpty || adm) {
        ctrl.setDoctorId(uid, isAdmin: adm);
      }
    });

    return isWide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: queueWidth,
                child: Column(
                  children: [
                    Expanded(
                      flex: 5,
                      child: _QueuePanel(ctrl: ctrl, auth: auth),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      flex: 4,
                      child: SingleChildScrollView(
                        child: _AppointmentsPanel(ctrl: ctrl),
                      ),
                    ),
                  ],
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: _ConsultationPanel(ctrl: ctrl, auth: auth)),
            ],
          )
        : _MobileLayout(ctrl: ctrl, auth: auth);
  }
}

class _QueuePanel extends StatelessWidget {
  const _QueuePanel({required this.ctrl, required this.auth});
  final DoctorController ctrl;
  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Queue', style: AppTextStyles.h4),
                      Obx(() {
                        final count = ctrl.doctorQueue.where((i) => i.status == QueueStatus.waiting).length;
                        return Text(
                          '$count waiting',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                        );
                      }),
                    ],
                  ),
                ),
                Obx(() {
                  final isServing = ctrl.currentlyServing.value != null;
                  return Tooltip(
                    message: isServing
                        ? 'Consultation in progress. Complete current patient first.'
                        : 'Call next patient in queue',
                    child: AppButton(
                      label: 'Call Next',
                      onPressed: isServing
                          ? null
                          : () => ctrl.callNextPatient(auth.user?.uid ?? ctrl.doctorId),
                      isLoading: ctrl.isLoading.value,
                      icon: Icons.campaign,
                    ),
                  );
                }),
              ],
            ),
          ),
          Obx(() {
            final isAdm = ctrl.isAdmin.value;
            final currentDept = ctrl.currentDeptCode.value;
            if (!isAdm) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.surface,
              child: Row(
                children: [
                  const Text('Dept:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String>(
                      value: currentDept,
                      isDense: true,
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
                      items: const [
                        DropdownMenuItem(value: 'ALL', child: Text('All Departments (Hospital)')),
                        DropdownMenuItem(value: 'GEN', child: Text('General Medicine')),
                        DropdownMenuItem(value: 'CARD', child: Text('Cardiology')),
                        DropdownMenuItem(value: 'PEDS', child: Text('Pediatrics')),
                        DropdownMenuItem(value: 'DENT', child: Text('Dental')),
                        DropdownMenuItem(value: 'ORTHO', child: Text('Orthopedics')),
                        DropdownMenuItem(value: 'ENT', child: Text('ENT / Otorhinolaryngology')),
                      ],
                      onChanged: (val) {
                        if (val != null) ctrl.setDepartmentCode(val);
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(height: 1),
          Expanded(
            child: Obx(() {
              final queue = ctrl.doctorQueue;
              if (queue.isEmpty) {
                return const EmptyStateWidget(
                  icon: Icons.people_outline,
                  title: 'No Patients',
                  message: 'Queue is currently empty.',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: queue.length,
                itemBuilder: (context, i) {
                  final item = queue[i];
                  return QueueItemCard(
                    item: item,
                    onCall: () => ctrl.callPatient(
                        item.queueId, auth.user?.uid ?? ''),
                    onStart: () => ctrl.startConsultation(item),
                    onSkip: () => ctrl.skipPatient(item.queueId),
                    onNoShow: () => ctrl.markNoShow(item.queueId),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ConsultationPanel extends StatefulWidget {
  const _ConsultationPanel({required this.ctrl, required this.auth});
  final DoctorController ctrl;
  final AuthController auth;

  @override
  State<_ConsultationPanel> createState() => _ConsultationPanelState();
}

class _ConsultationPanelState extends State<_ConsultationPanel> {
  // Diagnostic order builder fields
  String _selectedDiagType = 'LAB';
  final _diagTestNameCtrl = TextEditingController();
  final _diagInstructionsCtrl = TextEditingController();
  String _diagPriority = 'ROUTINE';

  // Prescription builder fields
  final _rxDrugCtrl = TextEditingController();
  final _rxDosageCtrl = TextEditingController();
  final _rxFreqCtrl = TextEditingController(text: 'TDS (3x daily)');
  final _rxDurationCtrl = TextEditingController(text: '5 days');
  final _rxQtyCtrl = TextEditingController(text: '15');
  final _rxInstructionsCtrl = TextEditingController(text: 'After meals');

  // Admission fields
  final _admissionReasonCtrl = TextEditingController();

  // Discharge fields
  final _dischargeSummaryCtrl = TextEditingController();

  @override
  void dispose() {
    _diagTestNameCtrl.dispose();
    _diagInstructionsCtrl.dispose();
    _rxDrugCtrl.dispose();
    _rxDosageCtrl.dispose();
    _rxFreqCtrl.dispose();
    _rxDurationCtrl.dispose();
    _rxQtyCtrl.dispose();
    _rxInstructionsCtrl.dispose();
    _admissionReasonCtrl.dispose();
    _dischargeSummaryCtrl.dispose();
    super.dispose();
  }

  void _addDiagnostic() {
    if (_diagTestNameCtrl.text.trim().isEmpty) {
      Get.snackbar('Validation', 'Please enter a diagnostic test name.');
      return;
    }
    widget.ctrl.addDiagnosticOrder(
      diagnosticType: _selectedDiagType,
      testName: _diagTestNameCtrl.text.trim(),
      priority: _diagPriority,
      instructions: _diagInstructionsCtrl.text.trim(),
    );
    _diagTestNameCtrl.clear();
    _diagInstructionsCtrl.clear();
  }

  void _addPrescription() {
    if (_rxDrugCtrl.text.trim().isEmpty || _rxDosageCtrl.text.trim().isEmpty) {
      Get.snackbar('Validation', 'Medication name and dosage are required.');
      return;
    }
    widget.ctrl.addPrescriptionOrder(
      medicationName: _rxDrugCtrl.text.trim(),
      dosage: _rxDosageCtrl.text.trim(),
      frequency: _rxFreqCtrl.text.trim(),
      duration: _rxDurationCtrl.text.trim(),
      quantity: int.tryParse(_rxQtyCtrl.text.trim()) ?? 1,
      instructions: _rxInstructionsCtrl.text.trim(),
    );
    _rxDrugCtrl.clear();
    _rxDosageCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;
    final auth = widget.auth;

    return Obx(() {
      final serving = ctrl.currentlyServing.value;
      final patient = ctrl.currentPatient.value;
      final visit = ctrl.currentVisit.value;

      if (serving == null) {
        return const EmptyStateWidget(
          icon: Icons.medical_services_outlined,
          title: 'No Patient in Consultation',
          message:
              'Select a patient from the queue and tap "Start" to begin clinical consultation.',
        );
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: serving.isEmergency
                    ? AppColors.emergencyGradient
                    : AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.medical_services, color: Colors.white, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Consultation in Progress',
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text(serving.queueNumber,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            )),
                      ],
                    ),
                  ),
                  Text(
                    AppUtils.waitingTime(serving.createdAt),
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (ctrl.isLoading.value)
              const Center(child: CircularProgressIndicator())
            else ...[
              if (patient != null) _PatientSummary(patient: patient),
              const SizedBox(height: 20),
              if (visit != null) _VisitSummary(visit: visit),
              const SizedBox(height: 24),

              // ── Clinical Vitals ──────────────────────────────────────────
              Text('Clinical Observations & Vitals', style: AppTextStyles.h4),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (ctx, constraints) {
                  final isCompact = constraints.maxWidth < 620;
                  final bp = AppTextField(
                    label: 'Blood Pressure',
                    hint: '120/80 mmHg',
                    prefixIcon: const Icon(Icons.favorite_outline),
                    onChanged: (v) => ctrl.vitals['bloodPressure'] = v,
                  );
                  final pulse = AppTextField(
                    label: 'Pulse Rate',
                    hint: '72 bpm',
                    prefixIcon: const Icon(Icons.timeline),
                    onChanged: (v) => ctrl.vitals['pulseRate'] = v,
                  );
                  final temp = AppTextField(
                    label: 'Temperature',
                    hint: '36.8 °C',
                    prefixIcon: const Icon(Icons.thermostat_outlined),
                    onChanged: (v) => ctrl.vitals['temperature'] = v,
                  );
                  final weight = AppTextField(
                    label: 'Weight',
                    hint: '70 kg',
                    prefixIcon: const Icon(Icons.monitor_weight_outlined),
                    onChanged: (v) => ctrl.vitals['weight'] = v,
                  );

                  if (isCompact) {
                    return Column(
                      children: [
                        Row(children: [Expanded(child: bp), const SizedBox(width: 12), Expanded(child: pulse)]),
                        const SizedBox(height: 12),
                        Row(children: [Expanded(child: temp), const SizedBox(width: 12), Expanded(child: weight)]),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: bp),
                      const SizedBox(width: 12),
                      Expanded(child: pulse),
                      const SizedBox(width: 12),
                      Expanded(child: temp),
                      const SizedBox(width: 12),
                      Expanded(child: weight),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // Symptoms & Diagnosis
              AppTextField(
                label: 'Chief Symptoms & Complaints',
                hint: 'e.g. Persistent fever for 3 days, dry cough, body aches',
                maxLines: 2,
                onChanged: (v) => ctrl.symptoms.value = v,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Clinical Observations / Examination',
                hint: 'e.g. Chest clear on auscultation, throat mildly congested',
                maxLines: 2,
                onChanged: (v) => ctrl.observations.value = v,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Diagnosis (Provisional / Confirmed) *',
                hint: 'e.g. Acute Viral Bronchitis',
                onChanged: (v) => ctrl.diagnosis.value = v,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Clinical Notes & Treatment Plan',
                hint: 'General notes, lifestyle advice, follow-up timeline',
                maxLines: 2,
                onChanged: (v) => ctrl.treatmentPlan.value = v,
              ),
              const SizedBox(height: 28),

              // ── Multi-Diagnostic Orders Section ─────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Diagnostic Orders (Lab / X-Ray / Scan)', style: AppTextStyles.h4),
                  Text('${ctrl.pendingDiagnostics.length} orders added',
                      style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    LayoutBuilder(
                      builder: (ctx, constraints) {
                        final isNarrow = constraints.maxWidth < 620;
                        final typeDropdown = DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _selectedDiagType,
                          decoration: const InputDecoration(labelText: 'Type'),
                          items: const [
                            DropdownMenuItem(value: 'LAB', child: Text('Laboratory', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'XR', child: Text('X-Ray', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'SCAN', child: Text('Ultrasound', overflow: TextOverflow.ellipsis)),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedDiagType = v);
                          },
                        );
                        final priorityDropdown = DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _diagPriority,
                          decoration: const InputDecoration(labelText: 'Priority'),
                          items: const [
                            DropdownMenuItem(value: 'ROUTINE', child: Text('Routine', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'URGENT', child: Text('Urgent', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'EMERGENCY', child: Text('Emergency', overflow: TextOverflow.ellipsis)),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _diagPriority = v);
                          },
                        );
                        final testNameField = AppTextField(
                          controller: _diagTestNameCtrl,
                          label: 'Test Name',
                          hint: 'e.g. Full Blood Count, Chest PA X-Ray',
                        );
                        final addButton = IconButton.filled(
                          onPressed: _addDiagnostic,
                          icon: const Icon(Icons.add),
                          tooltip: 'Add Diagnostic Test',
                        );

                        if (isNarrow) {
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(child: typeDropdown),
                                  const SizedBox(width: 12),
                                  Expanded(child: priorityDropdown),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: testNameField),
                                  const SizedBox(width: 10),
                                  addButton,
                                ],
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Flexible(
                              flex: 3,
                              child: typeDropdown,
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              flex: 5,
                              child: testNameField,
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              flex: 3,
                              child: priorityDropdown,
                            ),
                            const SizedBox(width: 12),
                            addButton,
                          ],
                        );
                      },
                    ),
                    if (ctrl.pendingDiagnostics.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: ctrl.pendingDiagnostics.length,
                        itemBuilder: (ctx, idx) {
                          final d = ctrl.pendingDiagnostics[idx];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 6),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(d.diagnosticType, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                              title: Text(d.testName),
                              subtitle: Text('Priority: ${d.priority} • Est. Fee: \$${d.fee.toStringAsFixed(2)}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                onPressed: () => ctrl.removeDiagnosticOrder(idx),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Prescriptions Section ───────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Prescription & Medication', style: AppTextStyles.h4),
                  Text('${ctrl.pendingPrescriptions.length} items added',
                      style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    LayoutBuilder(
                      builder: (ctx, constraints) {
                        final isNarrow = constraints.maxWidth < 620;
                        final drugField = AppTextField(
                          controller: _rxDrugCtrl,
                          label: 'Drug / Generic Name',
                          hint: 'e.g. Amoxicillin',
                        );
                        final dosageField = AppTextField(
                          controller: _rxDosageCtrl,
                          label: 'Dosage',
                          hint: '500mg',
                        );
                        final freqField = AppTextField(
                          controller: _rxFreqCtrl,
                          label: 'Frequency',
                          hint: 'TDS (3x/day)',
                        );
                        final qtyField = AppTextField(
                          controller: _rxQtyCtrl,
                          label: 'Qty',
                          keyboardType: TextInputType.number,
                        );
                        final addButton = IconButton.filled(
                          onPressed: _addPrescription,
                          icon: const Icon(Icons.add),
                          tooltip: 'Add Prescription Item',
                        );

                        if (isNarrow) {
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(flex: 3, child: drugField),
                                  const SizedBox(width: 10),
                                  Expanded(flex: 2, child: dosageField),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(flex: 3, child: freqField),
                                  const SizedBox(width: 10),
                                  Expanded(flex: 2, child: qtyField),
                                  const SizedBox(width: 10),
                                  addButton,
                                ],
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Flexible(flex: 4, child: drugField),
                            const SizedBox(width: 10),
                            Flexible(flex: 2, child: dosageField),
                            const SizedBox(width: 10),
                            Flexible(flex: 3, child: freqField),
                            const SizedBox(width: 10),
                            Flexible(flex: 2, child: qtyField),
                            const SizedBox(width: 10),
                            addButton,
                          ],
                        );
                      },
                    ),
                    if (ctrl.pendingPrescriptions.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: ctrl.pendingPrescriptions.length,
                        itemBuilder: (ctx, idx) {
                          final rx = ctrl.pendingPrescriptions[idx];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 6),
                            child: ListTile(
                              leading: const Icon(Icons.medication_rounded, color: AppColors.primary),
                              title: Text('${rx.medicationName} (${rx.dosage})'),
                              subtitle: Text('${rx.frequency} for ${rx.duration} • Total Qty: ${rx.quantity}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                onPressed: () => ctrl.removePrescriptionOrder(idx),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Admission / Discharge Actions ───────────────────────────
              LayoutBuilder(
                builder: (ctx, constraints) {
                  final isNarrow = constraints.maxWidth < 650;
                  final admissionBox = Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: ctrl.admissionRequested.value,
                              onChanged: (v) => ctrl.admissionRequested.value = v ?? false,
                            ),
                            const Expanded(
                              child: Text('Request In-Patient Admission',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        if (ctrl.admissionRequested.value) ...[
                          const SizedBox(height: 8),
                          AppTextField(
                            controller: _admissionReasonCtrl,
                            label: 'Admission Clinical Reason',
                            hint: 'e.g. Acute severe asthma exacerbation requiring nebulization',
                            onChanged: (v) => ctrl.admissionReason.value = v,
                          ),
                        ],
                      ],
                    ),
                  );

                  final dischargeBox = Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: ctrl.dischargeRecommended.value,
                              onChanged: (v) => ctrl.dischargeRecommended.value = v ?? false,
                            ),
                            const Expanded(
                              child: Text('Recommend Discharge',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        if (ctrl.dischargeRecommended.value) ...[
                          const SizedBox(height: 8),
                          AppTextField(
                            controller: _dischargeSummaryCtrl,
                            label: 'Discharge Summary & Instructions',
                            hint: 'e.g. Patient stable, continue oral medications at home',
                            onChanged: (v) => ctrl.dischargeSummary.value = v,
                          ),
                        ],
                      ],
                    ),
                  );

                  if (isNarrow) {
                    return Column(
                      children: [
                        admissionBox,
                        const SizedBox(height: 16),
                        dischargeBox,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: admissionBox),
                      const SizedBox(width: 16),
                      Expanded(child: dischargeBox),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),

              // Error notification
              Obx(() {
                if (ctrl.errorMessage.value.isEmpty) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(ctrl.errorMessage.value, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
                );
              }),

              // Complete Consultation Button
              Obx(() => AppButton(
                    label: 'Finalize & Complete Consultation',
                    onPressed: () async {
                      if (ctrl.diagnosis.value.trim().isEmpty) {
                        Get.snackbar('Diagnosis Required', 'Please enter a diagnosis before finalizing.');
                        return;
                      }
                      final ok = await ctrl.completeConsultation(
                        queueId: serving.queueId,
                        visitId: serving.visitId,
                        doctorId: auth.user?.uid ?? '',
                        doctorName: auth.userName,
                      );
                      if (ok) {
                        Get.snackbar(
                          'Consultation Completed',
                          'Clinical records, orders, and billing finalized.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppColors.success,
                          colorText: Colors.white,
                        );
                      }
                    },
                    isLoading: ctrl.isLoading.value,
                    width: double.infinity,
                    height: 54,
                    icon: Icons.check_circle_rounded,
                  )),
            ],
          ],
        ),
      );
    });
  }
}

class _PatientSummary extends StatelessWidget {
  const _PatientSummary({required this.patient});
  final PatientModel patient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Patient', style: AppTextStyles.labelMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    patient.fullName.isNotEmpty ? patient.fullName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(patient.fullName, style: AppTextStyles.h4),
                    Text(
                      '${patient.hospitalNumber} • ${patient.gender} • ${patient.displayAge}',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (patient.bloodGroup != null)
                Chip(
                  label: Text('Blood: ${patient.bloodGroup}'),
                  backgroundColor: AppColors.primary.withOpacity(0.08),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VisitSummary extends StatelessWidget {
  const _VisitSummary({required this.visit});
  final VisitModel visit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runAlignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: [
          Text('Visit Type: ${visit.patientType}', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          Text('Priority: ${visit.priority.label}', style: TextStyle(color: visit.isEmergency ? AppColors.emergency : AppColors.primary, fontWeight: FontWeight.bold)),
          Text('Care Stage: ${visit.careStage ?? visit.status}', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({required this.ctrl, required this.auth});
  final DoctorController ctrl;
  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final serving = ctrl.currentlyServing.value;
      return DefaultTabController(
        length: 3,
        initialIndex: serving != null ? 1 : 0,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Queue'),
                Tab(text: 'Consultation'),
                Tab(text: 'Appointments'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _QueuePanel(ctrl: ctrl, auth: auth),
                  _ConsultationPanel(ctrl: ctrl, auth: auth),
                  SingleChildScrollView(child: _AppointmentsPanel(ctrl: ctrl)),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ── Appointments Panel ────────────────────────────────────────────────────────

class _AppointmentsPanel extends StatelessWidget {
  const _AppointmentsPanel({required this.ctrl});
  final DoctorController ctrl;

  Color _statusColor(String status) {
    switch (status) {
      case 'CONFIRMED':
        return AppColors.success;
      case 'CANCELLED':
        return AppColors.error;
      case 'COMPLETED':
        return AppColors.textSecondary;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final today = ctrl.todayAppointments.toList();
      final all = ctrl.allAppointments.toList()
          .where((a) => a.status == 'SCHEDULED' || a.status == 'CONFIRMED')
          .toList();
      final err = ctrl.errorMessage.value;

      return Container(
        color: AppColors.background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ────────────────────────────────────────────
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ctrl.isAdmin.value ? 'Appointments (All Doctors)' : 'Appointments',
                          style: AppTextStyles.h4,
                        ),
                        Text(
                          'Today: ${today.length} • Upcoming: ${all.length}',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: ctrl.isAppointmentsLoading.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh, size: 20),
                    tooltip: 'Refresh appointments',
                    onPressed: () => ctrl.refreshAppointments(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            if (err.isNotEmpty && err.contains('appointments'))
              Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.error_outline, size: 16, color: AppColors.error),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'Failed to load appointments',
                            style: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => ctrl.refreshAppointments(),
                          child: const Text('Retry', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(err, style: const TextStyle(color: AppColors.error, fontSize: 11)),
                  ],
                ),
              ),

            // ── Today's Appointments ──────────────────────────────
            if (today.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.event_available_outlined,
                        size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text('No appointments today.',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              )
            else
              ...today.map((apt) => _AppointmentTile(
                    apt: apt,
                    statusColor: _statusColor(apt.status),
                    onStart: apt.status != 'CANCELLED' && apt.status != 'COMPLETED'
                        ? () => ctrl.startAppointmentConsultation(
                            apt, Get.find<AuthController>().user?.uid ?? '')
                        : null,
                    onConfirm: apt.status == 'SCHEDULED'
                        ? () => ctrl.confirmAppointment(apt.appointmentId)
                        : null,
                    onCancel: apt.status != 'CANCELLED' && apt.status != 'COMPLETED'
                        ? () => ctrl.cancelAppointmentByDoctor(apt.appointmentId)
                        : null,
                  )),

            // ── Upcoming (non-today) ───────────────────────────────
            if (all.any((a) {
              final today = DateTime.now();
              return !(a.date.year == today.year &&
                  a.date.month == today.month &&
                  a.date.day == today.day);
            })) ...[
              const Divider(height: 1),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('Upcoming',
                    style: AppTextStyles.labelMedium
                        .copyWith(color: AppColors.textSecondary)),
              ),
              ...all.where((a) {
                final t = DateTime.now();
                return !(a.date.year == t.year &&
                    a.date.month == t.month &&
                    a.date.day == t.day);
              }).map((apt) => _AppointmentTile(
                    apt: apt,
                    statusColor: _statusColor(apt.status),
                    onStart: apt.status != 'CANCELLED' && apt.status != 'COMPLETED'
                        ? () => ctrl.startAppointmentConsultation(
                            apt, Get.find<AuthController>().user?.uid ?? '')
                        : null,
                    onConfirm: apt.status == 'SCHEDULED'
                        ? () => ctrl.confirmAppointment(apt.appointmentId)
                        : null,
                    onCancel: () =>
                        ctrl.cancelAppointmentByDoctor(apt.appointmentId),
                    compact: false,
                  )),
            ],
          ],
        ),
      );
    });
  }
}

class _AppointmentTile extends StatelessWidget {
  const _AppointmentTile({
    required this.apt,
    required this.statusColor,
    this.onStart,
    this.onConfirm,
    this.onCancel,
    this.compact = false,
  });

  final dynamic apt;
  final Color statusColor;
  final VoidCallback? onStart;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  apt.patientName.isNotEmpty ? apt.patientName : 'Patient',
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  apt.status,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (apt.doctorName.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.person_pin_rounded, size: 13, color: AppColors.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${apt.doctorName.trim().toLowerCase().startsWith("dr") ? apt.doctorName.trim() : "Dr. ${apt.doctorName.trim()}"}${apt.departmentName.isNotEmpty ? " • ${apt.departmentName}" : ""}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
          ],
          Text(
            '${DateFormat.yMMMd().format(apt.date)}  •  ${apt.timeSlot}',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
          if (apt.reason.isNotEmpty && !compact) ...[
            const SizedBox(height: 2),
            Text(
              apt.reason,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (!compact && (onStart != null || onConfirm != null || onCancel != null)) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onStart != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ElevatedButton.icon(
                      onPressed: onStart,
                      icon: const Icon(Icons.play_arrow_rounded, size: 15),
                      label: const Text('Start', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                if (onConfirm != null)
                  TextButton.icon(
                    onPressed: onConfirm,
                    icon: const Icon(Icons.check_circle_outline, size: 15),
                    label: const Text('Confirm', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 8)),
                  ),
                if (onCancel != null)
                  TextButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.cancel_outlined, size: 15),
                    label: const Text('Cancel', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(horizontal: 8)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

