import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/diagnostic_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/route_constants.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/layout/app_scaffold.dart';
import '../../widgets/layout/sidebar_widget.dart';

class DiagnosticDashboardView extends StatelessWidget {
  const DiagnosticDashboardView({super.key});

  static const List<SidebarItem> _sidebar = [
    SidebarItem(icon: Icons.biotech, label: 'Diagnostics Workspace', route: AppRoutes.diagnosticDashboard),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final isAdmin = auth.user?.isAdmin ?? false;
    return AppScaffold(
      title: 'Diagnostics Workspace (Lab / X-Ray / Scan)',
      sidebarItems: isAdmin ? AppScaffold.adminSidebarItems : _sidebar,
      activeRoute: AppRoutes.diagnosticDashboard,
      child: const _DiagnosticBody(),
    );
  }
}

class _DiagnosticBody extends StatefulWidget {
  const _DiagnosticBody();

  @override
  State<_DiagnosticBody> createState() => _DiagnosticBodyState();
}

class _DiagnosticBodyState extends State<_DiagnosticBody> {
  late final DiagnosticController _ctrl;
  final _auth = Get.find<AuthController>();
  final _attachmentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<DiagnosticController>()) {
      _ctrl = Get.find<DiagnosticController>();
    } else {
      _ctrl = Get.put(
        DiagnosticController(Get.find(), Get.find(), notificationRepo: Get.find()),
      );
    }
  }

  @override
  void dispose() {
    _attachmentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth > 900;
    final queueWidth = screenWidth > 1300 ? 420.0 : (screenWidth > 1100 ? 360.0 : 310.0);

    return Obx(() {
      final hasSelected = _ctrl.currentRequest.value != null;
      return Column(
        children: [
          _buildDepartmentFilter(),
          const Divider(height: 1),
          Expanded(
            child: isWide
                ? Row(
                    children: [
                      SizedBox(width: queueWidth, child: _buildQueueList()),
                      const VerticalDivider(width: 1),
                      Expanded(child: _buildProcessingPanel()),
                    ],
                  )
                : (!hasSelected
                    ? _buildQueueList()
                    : Column(
                        children: [
                          Container(
                            color: AppColors.surface,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                TextButton.icon(
                                  onPressed: () => _ctrl.currentRequest.value = null,
                                  icon: const Icon(Icons.arrow_back),
                                  label: const Text('Back to Diagnostic Queue'),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(child: _buildProcessingPanel()),
                        ],
                      )),
          ),
        ],
      );
    });
  }

  Widget _buildDepartmentFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Text('Diagnostic Unit: ', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            Obx(() {
              return SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'ALL', label: Text('All Units'), icon: Icon(Icons.grid_view_rounded)),
                  ButtonSegment(value: 'LAB', label: Text('Laboratory'), icon: Icon(Icons.biotech)),
                  ButtonSegment(value: 'XR', label: Text('X-Ray & Radiology'), icon: Icon(Icons.photo_camera_front)),
                  ButtonSegment(value: 'SCAN', label: Text('Ultrasound & Scan'), icon: Icon(Icons.radar)),
                ],
                selected: {_ctrl.selectedType.value},
                onSelectionChanged: (set) => _ctrl.setDiagnosticType(set.first),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueList() {
    return Obx(() {
      final reqs = _ctrl.activeRequests;

      if (reqs.isEmpty) {
        return const Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 48, color: AppColors.textSecondary),
                SizedBox(height: 12),
                Text('No pending diagnostic requests for this unit.'),
              ],
            ),
          ),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: reqs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, idx) {
          final req = reqs[idx];
          final isSelected = _ctrl.currentRequest.value?.diagnosticRequestId == req.diagnosticRequestId;

          return Card(
            elevation: isSelected ? 3 : 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isSelected ? const BorderSide(color: AppColors.primary, width: 2) : BorderSide.none,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(req.patientName.isNotEmpty ? req.patientName : 'Patient', style: AppTextStyles.h4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: req.priority == 'EMERGENCY' ? AppColors.emergency.withOpacity(0.15) : AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      req.priority,
                      style: TextStyle(
                        color: req.priority == 'EMERGENCY' ? AppColors.emergency : AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text('Test: ${req.testName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('Dr. ${req.doctorName} • Status: ${req.status}', style: AppTextStyles.caption),
                  if (req.instructions.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Instructions: ${req.instructions}', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                  ],
                ],
              ),
              trailing: AppButton(
                text: isSelected ? 'Active' : 'Start Test',
                onPressed: () => _ctrl.startProcessing(req),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildProcessingPanel() {
    return Obx(() {
      final req = _ctrl.currentRequest.value;

      if (req == null) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_turned_in_outlined, size: 54, color: AppColors.textSecondary),
              SizedBox(height: 12),
              Text('Select a test from the queue to record findings and release reports.'),
            ],
          ),
        );
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.science_rounded, color: AppColors.primary, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${req.diagnosticTypeLabel}: ${req.testName}', style: AppTextStyles.h3),
                          const SizedBox(height: 4),
                          Text('Patient: ${req.patientName} • Ordered by: Dr. ${req.doctorName}', style: AppTextStyles.bodyMedium),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _ctrl.clearCurrent,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text('Test Findings & Laboratory Data *', style: AppTextStyles.h4),
            const SizedBox(height: 8),
            AppTextField(
              label: 'Detailed Findings',
              hint: 'e.g. Hemoglobin: 13.5 g/dL, WBC: 6,500 /mcL, Platelets: 250,000 /mcL (Normal limits)',
              maxLines: 4,
              onChanged: (v) => _ctrl.findings.value = v,
            ),
            const SizedBox(height: 16),

            Text('Clinical Interpretation & Impressions', style: AppTextStyles.h4),
            const SizedBox(height: 8),
            AppTextField(
              label: 'Interpretation',
              hint: 'e.g. Normal complete blood count profile. No acute abnormalities.',
              maxLines: 2,
              onChanged: (v) => _ctrl.interpretation.value = v,
            ),
            const SizedBox(height: 16),

            Text('Specialist Notes', style: AppTextStyles.h4),
            const SizedBox(height: 8),
            AppTextField(
              label: 'Notes & Recommendations',
              hint: 'Optional notes for consulting physician',
              onChanged: (v) => _ctrl.notes.value = v,
            ),
            const SizedBox(height: 20),

            // Attachment link
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _attachmentCtrl,
                    label: 'Image / Document Attachment URL',
                    hint: 'https://storage.../xray_chest.png',
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  icon: const Icon(Icons.add_link),
                  onPressed: () {
                    if (_attachmentCtrl.text.trim().isNotEmpty) {
                      _ctrl.addAttachment(_attachmentCtrl.text.trim());
                      _attachmentCtrl.clear();
                    }
                  },
                ),
              ],
            ),
            if (_ctrl.attachments.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _ctrl.attachments.asMap().entries.map((e) {
                  return Chip(
                    label: Text('File ${e.key + 1}', style: const TextStyle(fontSize: 12)),
                    onDeleted: () => _ctrl.removeAttachment(e.key),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 20),

            // Release to Patient toggle
            SwitchListTile(
              title: const Text('Release Report to Patient Portal', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('When enabled, the patient can view this report immediately in their mobile / web portal.'),
              value: _ctrl.releaseToPatient.value,
              onChanged: (v) => _ctrl.releaseToPatient.value = v,
            ),
            const SizedBox(height: 24),

            Obx(() {
              if (_ctrl.errorMessage.value.isEmpty) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(8)),
                child: Text(_ctrl.errorMessage.value, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
              );
            }),

            Obx(() => AppButton(
                  text: 'Submit & Release Diagnostic Report',
                  onPressed: () => _ctrl.submitResult(
                    staffId: _auth.user?.uid ?? '',
                    staffName: _auth.userName,
                  ),
                  isLoading: _ctrl.isLoading.value,
                  isFullWidth: true,
                  icon: Icons.check_circle_rounded,
                )),
          ],
        ),
      );
    });
  }
}
