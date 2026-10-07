import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/registration_controller.dart';
import '../../models/queue_item_model.dart';
import '../../models/patient_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/route_constants.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/layout/app_scaffold.dart';
import '../../widgets/layout/sidebar_widget.dart';
import '../../widgets/queue/queue_item_card.dart';
import '../../core/utils/app_utils.dart';

class RegistrationDashboardView extends StatelessWidget {
  const RegistrationDashboardView({super.key});

  static const List<SidebarItem> _staffSidebar = [
    SidebarItem(
        icon: Icons.app_registration,
        label: 'Registration',
        route: AppRoutes.registrationDashboard),
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
  ];

  static List<SidebarItem> get staffSidebar => _staffSidebar;
  static List<SidebarItem> get adminSidebar => _adminSidebar;

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final isAdmin = auth.user?.isAdmin ?? false;
    return AppScaffold(
      title: 'Registration',
      sidebarItems: isAdmin ? _adminSidebar : _staffSidebar,
      activeRoute: AppRoutes.registrationDashboard,
      child: const _RegistrationBody(),
    );
  }
}

class _RegistrationBody extends StatelessWidget {
  const _RegistrationBody();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<RegistrationController>();
    final auth = Get.find<AuthController>();
    final isWide = MediaQuery.sizeOf(context).width > 900;

    return isWide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left — queue list
              SizedBox(
                width: 380,
                child: _QueuePanel(ctrl: ctrl, auth: auth),
              ),
              const VerticalDivider(width: 1),
              // Right — patient detail
              Expanded(child: _PatientPanel(ctrl: ctrl, auth: auth)),
            ],
          )
        : _MobileLayout(ctrl: ctrl, auth: auth);
  }
}

class _QueuePanel extends StatelessWidget {
  const _QueuePanel({required this.ctrl, required this.auth});
  final RegistrationController ctrl;
  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // Header
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Obx(() => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${ctrl.waitingItems.length} Waiting',
                        style: AppTextStyles.chipText
                            .copyWith(color: AppColors.queueWaiting),
                      ),
                    )),
                const Spacer(),
                Obx(() => AppButton(
                      label: 'Call Next',
                      onPressed: () =>
                          ctrl.callNextPatient(auth.user?.uid ?? ''),
                      isLoading: ctrl.isLoading.value,
                      icon: Icons.call,
                      height: 36,
                    )),
              ],
            ),
          ),
          // Queue list
          Expanded(
            child: Obx(() {
              final queue = ctrl.regQueue;
              if (queue.isEmpty) {
                return const EmptyStateWidget(
                  title: 'No Patients in Queue',
                  subtitle:
                      'Patients will appear here when Gate creates a visit.',
                  icon: Icons.queue,
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: queue.length,
                itemBuilder: (ctx, i) {
                  final item = queue[i];
                  return Obx(() => QueueItemCard(
                        item: item,
                        patientName: 'Patient ${item.queueNumber}',
                        onCall: item.status == QueueStatus.waiting
                            ? () => ctrl.callPatient(
                                item.queueId, auth.user?.uid ?? '')
                            : null,
                        onStart: item.status == QueueStatus.called
                            ? () async {
                                await ctrl.startService(item.queueId);
                                await ctrl.loadCurrentPatient(item.patientId);
                              }
                            : null,
                        onSkip: item.status == QueueStatus.waiting
                            ? () => ctrl.skipPatient(item.queueId)
                            : null,
                        onNoShow: item.status == QueueStatus.called
                            ? () => ctrl.markNoShow(item.queueId)
                            : null,
                      ));
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _PatientPanel extends StatelessWidget {
  const _PatientPanel({required this.ctrl, required this.auth});
  final RegistrationController ctrl;
  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.of(context).size.width < 600;
    return Obx(() {
      final serving = ctrl.currentlyServing.value;
      final patient = ctrl.currentPatient.value;

      if (serving == null) {
        return const EmptyStateWidget(
          title: 'No Patient Currently',
          subtitle: 'Call a patient from the queue to start registration.',
          icon: Icons.person_search,
        );
      }

      return SingleChildScrollView(
        padding: EdgeInsets.all(isPhone ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Currently serving banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.hourglass_top, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Currently Serving',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: Colors.white70,
                            )),
                        Text(serving.queueNumber,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            )),
                      ],
                    ),
                  ),
                  if (serving.isEmergency)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.emergency,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('EMERGENCY',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          )),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (ctrl.isLoading.value)
              const Center(child: CircularProgressIndicator())
            else if (patient != null)
              _PatientInfoForm(
                patient: patient,
                queueItem: serving,
                ctrl: ctrl,
                auth: auth,
              )
            else
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      );
    });
  }
}

class _PatientInfoForm extends StatefulWidget {
  const _PatientInfoForm({
    required this.patient,
    required this.queueItem,
    required this.ctrl,
    required this.auth,
  });
  final PatientModel patient;
  final QueueItemModel queueItem;
  final RegistrationController ctrl;
  final AuthController auth;

  @override
  State<_PatientInfoForm> createState() => _PatientInfoFormState();
}

class _PatientInfoFormState extends State<_PatientInfoForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _insuranceCtrl;
  late final TextEditingController _insuranceNumCtrl;

  @override
  void initState() {
    super.initState();
    final p = widget.patient;
    _phoneCtrl = TextEditingController(text: p.phone);
    _emailCtrl = TextEditingController(text: p.email ?? '');
    _addressCtrl = TextEditingController(text: p.address ?? '');
    _insuranceCtrl = TextEditingController(text: p.insuranceProvider ?? '');
    _insuranceNumCtrl = TextEditingController(text: p.insuranceNumber ?? '');
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _insuranceCtrl.dispose();
    _insuranceNumCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAndComplete() async {
    if (!_formKey.currentState!.validate()) return;
    // Update patient info
    await widget.ctrl.updatePatientInfo(widget.patient.patientId, {
      'phone': _phoneCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'insuranceProvider': _insuranceCtrl.text.trim(),
      'insuranceNumber': _insuranceNumCtrl.text.trim(),
    });
    // Complete registration → advance to Doctor queue
    await widget.ctrl.completeRegistration(
      queueItem: widget.queueItem,
      staffId: widget.auth.user?.uid ?? '',
    );
    if (widget.ctrl.errorMessage.value.isEmpty) {
      Get.snackbar('Registration Complete',
          '${widget.patient.fullName} has been sent to the Doctor queue.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient summary
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    AppUtils.getInitials(widget.patient.fullName),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.patient.fullName,
                      style: AppTextStyles.headlineSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(widget.patient.hospitalNumber,
                        style: AppTextStyles.hospitalNumber),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          const Text('Verify & Update Information',
              style: AppTextStyles.titleLarge),
          const SizedBox(height: 16),

          AppTextField(
            label: 'Phone Number',
            controller: _phoneCtrl,
            prefixIcon: Icons.phone,
            keyboardType: TextInputType.phone,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Phone is required' : null,
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Email',
            controller: _emailCtrl,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Address',
            controller: _addressCtrl,
            prefixIcon: Icons.home_outlined,
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Insurance Provider',
            controller: _insuranceCtrl,
            prefixIcon: Icons.health_and_safety_outlined,
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Insurance Number',
            controller: _insuranceNumCtrl,
            prefixIcon: Icons.badge_outlined,
          ),
          const SizedBox(height: 24),

          // Error
          Obx(() {
            if (widget.ctrl.errorMessage.value.isEmpty) {
              return const SizedBox.shrink();
            }
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(widget.ctrl.errorMessage.value,
                  style:
                      AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
            );
          }),

          Obx(() => AppButton(
                label: 'Complete Registration → Doctor Queue',
                onPressed: _saveAndComplete,
                isLoading: widget.ctrl.isSaving.value,
                width: double.infinity,
                height: 52,
                icon: Icons.send,
              )),
        ],
      ),
    );
  }
}

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({required this.ctrl, required this.auth});
  final RegistrationController ctrl;
  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(tabs: [
            Tab(text: 'Queue'),
            Tab(text: 'Patient'),
          ]),
          Expanded(
            child: TabBarView(children: [
              _QueuePanel(ctrl: ctrl, auth: auth),
              _PatientPanel(ctrl: ctrl, auth: auth),
            ]),
          ),
        ],
      ),
    );
  }
}
