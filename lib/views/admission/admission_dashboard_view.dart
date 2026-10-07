import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/admission_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/route_constants.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/layout/app_scaffold.dart';
import '../../widgets/layout/sidebar_widget.dart';

class AdmissionDashboardView extends StatelessWidget {
  const AdmissionDashboardView({super.key});

  static const List<SidebarItem> _sidebar = [
    SidebarItem(
        icon: Icons.hotel,
        label: 'Wards & Admissions',
        route: AppRoutes.admissionDashboard),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final isAdmin = auth.user?.isAdmin ?? false;
    return AppScaffold(
      title: 'In-Patient Admission & Ward Management',
      sidebarItems: isAdmin ? AppScaffold.adminSidebarItems : _sidebar,
      activeRoute: AppRoutes.admissionDashboard,
      child: const _AdmissionBody(),
    );
  }
}

class _AdmissionBody extends StatefulWidget {
  const _AdmissionBody();

  @override
  State<_AdmissionBody> createState() => _AdmissionBodyState();
}

class _AdmissionBodyState extends State<_AdmissionBody> {
  late final AdmissionController _ctrl;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<AdmissionController>()) {
      _ctrl = Get.find<AdmissionController>();
    } else {
      _ctrl = Get.put(AdmissionController(Get.find(), Get.find(),
          notificationRepo: Get.find()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: const TabBar(
              labelColor: AppColors.primary,
              tabs: [
                Tab(
                    icon: Icon(Icons.assignment_ind_outlined),
                    text: 'Admission Requests'),
                Tab(
                    icon: Icon(Icons.single_bed_outlined),
                    text: 'Wards & Bed Map'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildRequestsView(),
                _buildBedMapView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsView() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth > 900;
    final listWidth =
        screenWidth > 1300 ? 420.0 : (screenWidth > 1100 ? 360.0 : 310.0);
    return Obx(() {
      final hasSelected = _ctrl.selectedRequest.value != null;
      if (isWide) {
        return Row(
          children: [
            SizedBox(width: listWidth, child: _buildRequestList()),
            const VerticalDivider(width: 1),
            Expanded(child: _buildAssignmentPanel()),
          ],
        );
      }
      if (hasSelected) {
        return Column(
          children: [
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _ctrl.selectedRequest.value = null,
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Back to Requests'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: _buildAssignmentPanel()),
          ],
        );
      }
      return _buildRequestList();
    });
  }

  Widget _buildRequestList() {
    return Obx(() {
      final reqs = _ctrl.admissionRequests;

      if (reqs.isEmpty) {
        return const Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 48, color: AppColors.textSecondary),
                SizedBox(height: 12),
                Text('No active admission requests.'),
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
          final isSelected = _ctrl.selectedRequest.value?.admissionRequestId ==
              req.admissionRequestId;

          return Card(
            elevation: isSelected ? 3 : 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isSelected
                  ? const BorderSide(color: AppColors.primary, width: 2)
                  : BorderSide.none,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      req.patientName.isNotEmpty ? req.patientName : 'Patient',
                      style: AppTextStyles.h4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: req.priority == 'EMERGENCY'
                          ? AppColors.emergency.withOpacity(0.15)
                          : AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      req.priority,
                      style: TextStyle(
                        color: req.priority == 'EMERGENCY'
                            ? AppColors.emergency
                            : AppColors.primary,
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
                  const SizedBox(height: 4),
                  Text('Reason: ${req.reason}',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text('Dr. ${req.doctorName} • Status: ${req.status}',
                      style: AppTextStyles.caption),
                  if (req.assignedBedNumber != null)
                    Text(
                        'Bed: ${req.assignedBedNumber} (${req.assignedWardName})',
                        style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold)),
                ],
              ),
              trailing: AppButton(
                height: 36,
                text: isSelected
                    ? 'Active'
                    : (req.isAdmitted ? 'Admitted' : 'Assign Bed'),
                onPressed: req.isAdmitted
                    ? null
                    : () => _ctrl.selectAdmissionRequest(req),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildAssignmentPanel() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isPhone = screenWidth < 600;

    return Obx(() {
      final req = _ctrl.selectedRequest.value;
      final availableBeds = _ctrl.availableBeds;
      final selectedBed = _ctrl.selectedBed.value;

      if (req == null) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hotel_outlined,
                  size: 54, color: AppColors.textSecondary),
              SizedBox(height: 12),
              Text(
                  'Select an admission order to assign an available ward bed.'),
            ],
          ),
        );
      }

      return SingleChildScrollView(
        padding: EdgeInsets.all(isPhone ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              child: Padding(
                padding: EdgeInsets.all(isPhone ? 16 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(req.patientName, style: AppTextStyles.h3),
                    const SizedBox(height: 4),
                    Text('Admission Order by Dr. ${req.doctorName}',
                        style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 8),
                    Text('Clinical Reason: ${req.reason}',
                        style: AppTextStyles.bodySmall
                            .copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Select Available Bed', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            const Text(
                'Choose an available bed in the target ward for this patient.',
                style: AppTextStyles.caption),
            const SizedBox(height: 16),
            if (availableBeds.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: AppColors.warning, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                        child: Text(
                            'No beds currently available. Please check the Wards & Bed Map tab or release a discharged bed.')),
                  ],
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final colCount = constraints.maxWidth < 500
                      ? 1
                      : (constraints.maxWidth < 800 ? 2 : 3);
                  final ratio = constraints.maxWidth < 500
                      ? 3.2
                      : (constraints.maxWidth < 800 ? 2.6 : 2.2);

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: colCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: ratio,
                    ),
                    itemCount: availableBeds.length,
                    itemBuilder: (ctx, idx) {
                      final bed = availableBeds[idx];
                      final isBedSelected = selectedBed?.bedId == bed.bedId;

                      return InkWell(
                        onTap: () => _ctrl.selectBed(bed),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isBedSelected
                                ? AppColors.primary.withOpacity(0.12)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isBedSelected
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: isBedSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.hotel_rounded,
                                  color: isBedSelected
                                      ? AppColors.primary
                                      : AppColors.success),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Bed ${bed.bedNumber}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Text(
                                        bed.wardName.isNotEmpty
                                            ? bed.wardName
                                            : 'Ward',
                                        style: AppTextStyles.caption),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            const SizedBox(height: 28),
            Obx(() {
              if (_ctrl.errorMessage.value.isEmpty)
                return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(8)),
                child: Text(_ctrl.errorMessage.value,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.error)),
              );
            }),
            Obx(() => AppButton(
                  text: selectedBed != null
                      ? 'Confirm & Admit to Bed ${selectedBed.bedNumber}'
                      : 'Select an Available Bed Above',
                  onPressed: selectedBed != null
                      ? () => _ctrl.assignBedToPatient()
                      : null,
                  isLoading: _ctrl.isLoading.value,
                  isFullWidth: true,
                  icon: Icons.check_circle_rounded,
                )),
          ],
        ),
      );
    });
  }

  Widget _buildBedMapView() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isPhone = screenWidth < 600;

    return Obx(() {
      final wards = _ctrl.wards;
      final beds = _ctrl.beds;

      return SingleChildScrollView(
        padding: EdgeInsets.all(isPhone ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                const Text('Hospital Wards & Bed Map', style: AppTextStyles.h3),
                Text(
                    '${_ctrl.occupiedBeds.length} / ${beds.length} beds occupied',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            if (beds.isEmpty)
              const Center(
                  child: Text(
                      'No beds initialized. Run database seed to populate sample wards.'))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: wards.length,
                separatorBuilder: (_, __) => const SizedBox(height: 24),
                itemBuilder: (ctx, wIdx) {
                  final ward = wards[wIdx];
                  final wardBeds =
                      beds.where((b) => b.wardId == ward.wardId).toList();

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
                            runSpacing: 4,
                            children: [
                              Text('${ward.name} (${ward.type})',
                                  style: AppTextStyles.h4),
                              Text(
                                  '${wardBeds.where((b) => b.isAvailable).length} available',
                                  style: const TextStyle(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: wardBeds.map((bed) {
                              final isOcc = bed.isOccupied;
                              return Container(
                                width: 140,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isOcc
                                      ? AppColors.primary.withOpacity(0.08)
                                      : AppColors.success.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: isOcc
                                          ? AppColors.primary.withOpacity(0.3)
                                          : AppColors.success.withOpacity(0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Bed ${bed.bedNumber}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        Icon(Icons.hotel_rounded,
                                            size: 16,
                                            color: isOcc
                                                ? AppColors.primary
                                                : AppColors.success),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isOcc
                                          ? (bed.currentPatientName ??
                                              'Occupied')
                                          : 'Available',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isOcc
                                            ? AppColors.primary
                                            : AppColors.success,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (isOcc) ...[
                                      const SizedBox(height: 6),
                                      InkWell(
                                        onTap: () =>
                                            _ctrl.releaseBed(bed.bedId),
                                        child: const Text('Release Bed',
                                            style: TextStyle(
                                                color: AppColors.error,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),
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
}
