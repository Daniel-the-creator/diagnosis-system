import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/gate_controller.dart';
import '../../models/patient_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/route_constants.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/layout/app_scaffold.dart';
import '../../widgets/layout/sidebar_widget.dart';
import '../../widgets/patient/patient_card_widget.dart';
import '../../core/utils/app_utils.dart';

class GateDashboardView extends StatelessWidget {
  const GateDashboardView({super.key});

  static const List<SidebarItem> _staffSidebar = [
    SidebarItem(
        icon: Icons.meeting_room,
        label: 'Gate',
        route: AppRoutes.gateDashboard),
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
      title: 'Gate Entry',
      sidebarItems: isAdmin ? _adminSidebar : _staffSidebar,
      activeRoute: AppRoutes.gateDashboard,
      child: const _GateBody(),
    );
  }
}

class _GateBody extends StatefulWidget {
  const _GateBody();

  @override
  State<_GateBody> createState() => _GateBodyState();
}

class _GateBodyState extends State<_GateBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _ctrl = Get.find<GateController>();
  final _auth = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _tabs,
            tabs: const [
              Tab(icon: Icon(Icons.search), text: 'Find Patient'),
              Tab(icon: Icon(Icons.person_add), text: 'New Patient'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _SearchTab(ctrl: _ctrl, auth: _auth),
              _RegisterTab(
                ctrl: _ctrl,
                auth: _auth,
                onSwitchTab: () => _tabs.animateTo(0),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Search Tab ─────────────────────────────────────────────────────────────

class _SearchTab extends StatefulWidget {
  const _SearchTab({required this.ctrl, required this.auth});
  final GateController ctrl;
  final AuthController auth;

  @override
  State<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<_SearchTab> {
  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;
    final auth = widget.auth;
    final isPhone = MediaQuery.of(context).size.width < 600;
    return SingleChildScrollView(
      padding: EdgeInsets.all(isPhone ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search
          PatientSearchWidget(
            onSearch: ctrl.searchPatients,
            results: ctrl.searchResults,
            isSearching: ctrl.isSearching.value,
            onSelect: ctrl.selectPatient,
          ),

          // Selected patient panel
          Obx(() {
            final patient = ctrl.selectedPatient.value;
            if (patient == null) {
              if (ctrl.searchResults.isEmpty &&
                  ctrl.isSearching.value == false) {
                return const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: EmptyStateWidget(
                    title: 'Search for a Patient',
                    subtitle:
                        'Enter a name, hospital number, or phone number to find an existing patient record.',
                    icon: Icons.search,
                  ),
                );
              }
              return const SizedBox.shrink();
            }
            return _SelectedPatientPanel(
                patient: patient, ctrl: ctrl, auth: auth);
          }),
        ],
      ),
    );
  }
}

class _SelectedPatientPanel extends StatelessWidget {
  const _SelectedPatientPanel({
    required this.patient,
    required this.ctrl,
    required this.auth,
  });
  final PatientModel patient;
  final GateController ctrl;
  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final queueItem = ctrl.generatedQueueItem.value;
      if (queueItem != null) {
        // Success state — show queue ticket
        return _QueueTicket(
          patient: patient,
          queueNumber: queueItem.queueNumber,
          patientType: ctrl.selectedPatientType.value,
          onDone: ctrl.reset,
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          // Patient info card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          AppUtils.getInitials(patient.fullName),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patient.fullName,
                            style: AppTextStyles.headlineSmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.badge_outlined,
                                  size: 14, color: AppColors.textHint),
                              const SizedBox(width: 4),
                              Text(patient.hospitalNumber,
                                  style: AppTextStyles.hospitalNumber),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: ctrl.reset,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                _InfoRow(label: 'Phone', value: patient.phone),
                _InfoRow(
                    label: 'Gender',
                    value: AppUtils.toTitleCase(patient.gender)),
                if (patient.dateOfBirth != null)
                  _InfoRow(label: 'Age', value: patient.displayAge),
                if (patient.bloodGroup != null)
                  _InfoRow(label: 'Blood Group', value: patient.bloodGroup!),
              ],
            ),
          ),

          const SizedBox(height: 20),
          // Patient type selector
          const Text('Patient Type', style: AppTextStyles.titleMedium),
          const SizedBox(height: 12),
          Obx(() => Row(
                children: [
                  _TypeButton(
                    label: 'Regular',
                    icon: Icons.person,
                    color: AppColors.primary,
                    isSelected: ctrl.selectedPatientType.value == 'REGULAR',
                    onTap: () => ctrl.setPatientType('REGULAR'),
                  ),
                  const SizedBox(width: 12),
                  _TypeButton(
                    label: 'Emergency',
                    icon: Icons.emergency,
                    color: AppColors.emergency,
                    isSelected: ctrl.selectedPatientType.value == 'EMERGENCY',
                    onTap: () => ctrl.setPatientType('EMERGENCY'),
                  ),
                ],
              )),

          const SizedBox(height: 20),
          // Error
          Obx(() {
            if (ctrl.errorMessage.value.isEmpty) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(ctrl.errorMessage.value,
                  style:
                      AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
            );
          }),

          // Create visit button
          Obx(() => AppButton(
                label: 'Generate Queue Number',
                onPressed: () => ctrl.createVisit(staffId: auth.user!.uid),
                isLoading: ctrl.isCreatingVisit.value,
                width: double.infinity,
                height: 52,
                icon: Icons.confirmation_number,
              )),
        ],
      );
    });
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: AppTextStyles.labelMedium),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.12)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: isSelected ? color : AppColors.textSecondary,
                  size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.titleSmall.copyWith(
                  color: isSelected ? color : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QueueTicket extends StatelessWidget {
  const _QueueTicket({
    required this.patient,
    required this.queueNumber,
    required this.patientType,
    required this.onDone,
  });
  final PatientModel patient;
  final String queueNumber;
  final String patientType;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final isEmergency = patientType == 'EMERGENCY';
    final isPhone = MediaQuery.of(context).size.width < 600;
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: EdgeInsets.all(isPhone ? 20 : 28),
      decoration: BoxDecoration(
        gradient: isEmergency
            ? AppColors.emergencyGradient
            : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isEmergency ? AppColors.emergency : AppColors.primary)
                .withValues(alpha: 0.4),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 48),
          const SizedBox(height: 12),
          const Text('Queue Number Generated',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Colors.white70,
                letterSpacing: 1,
              )),
          const SizedBox(height: 8),
          Text(
            queueNumber,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${patient.fullName}  •  ${isEmergency ? '🚨 Emergency' : 'Regular'}',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: onDone,
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Next Patient',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Register Tab ───────────────────────────────────────────────────────────

class _RegisterTab extends StatefulWidget {
  const _RegisterTab({
    required this.ctrl,
    required this.auth,
    required this.onSwitchTab,
  });
  final GateController ctrl;
  final AuthController auth;
  final VoidCallback onSwitchTab;

  @override
  State<_RegisterTab> createState() => _RegisterTabState();
}

class _RegisterTabState extends State<_RegisterTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _ecNameCtrl = TextEditingController();
  final _ecPhoneCtrl = TextEditingController();
  String _gender = 'Male';
  DateTime? _dob;
  String? _bloodGroup;
  final _dobCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _ecNameCtrl.dispose();
    _ecPhoneCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final patient = await widget.ctrl.registerNewPatient(
      fullName: _nameCtrl.text.trim(),
      gender: _gender,
      phone: _phoneCtrl.text.trim(),
      dateOfBirth: _dob,
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      address:
          _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      emergencyContactName:
          _ecNameCtrl.text.trim().isEmpty ? null : _ecNameCtrl.text.trim(),
      emergencyContactPhone:
          _ecPhoneCtrl.text.trim().isEmpty ? null : _ecPhoneCtrl.text.trim(),
      bloodGroup: _bloodGroup,
    );
    if (patient != null) widget.onSwitchTab();
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.of(context).size.width < 600;
    final genderField = DropdownButtonFormField<String>(
      initialValue: _gender,
      decoration: InputDecoration(
        labelText: 'Gender *',
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
      items: ['Male', 'Female', 'Other']
          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
          .toList(),
      onChanged: (v) => setState(() => _gender = v!),
    );

    final dobField = AppTextField(
      label: 'Date of Birth',
      readOnly: true,
      controller: _dobCtrl,
      prefixIcon: Icons.calendar_today,
      hint: 'DD MMM YYYY',
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: DateTime(1990),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (d != null) {
          setState(() {
            _dob = d;
            _dobCtrl.text = AppUtils.formatDate(_dob);
          });
        }
      },
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(isPhone ? 16 : 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New Patient Registration',
                style: AppTextStyles.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Fill in the patient\'s basic information to create a new record.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // Name
            AppTextField(
              label: 'Full Name *',
              controller: _nameCtrl,
              prefixIcon: Icons.person_outline,
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Full name is required'
                  : null,
            ),
            const SizedBox(height: 16),

            // Gender + DOB
            if (isPhone) ...[
              genderField,
              const SizedBox(height: 16),
              dobField,
            ] else ...[
              Row(
                children: [
                  Expanded(child: genderField),
                  const SizedBox(width: 12),
                  Expanded(child: dobField),
                ],
              ),
            ],
            const SizedBox(height: 16),

            // Phone
            AppTextField(
              label: 'Phone Number *',
              controller: _phoneCtrl,
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Phone is required';
                if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(v.trim())) {
                  return 'Enter a valid phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email
            AppTextField(
              label: 'Email (optional)',
              controller: _emailCtrl,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Blood group
            DropdownButtonFormField<String?>(
              initialValue: _bloodGroup,
              decoration: InputDecoration(
                labelText: 'Blood Group',
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
              items: [null, 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                  .map((g) =>
                      DropdownMenuItem(value: g, child: Text(g ?? 'Unknown')))
                  .toList(),
              onChanged: (v) => setState(() => _bloodGroup = v),
            ),
            const SizedBox(height: 16),

            // Address
            AppTextField(
              label: 'Address',
              controller: _addressCtrl,
              prefixIcon: Icons.home_outlined,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),

            const Text('Emergency Contact', style: AppTextStyles.titleMedium),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Contact Name',
              controller: _ecNameCtrl,
              prefixIcon: Icons.contact_phone_outlined,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Contact Phone',
              controller: _ecPhoneCtrl,
              prefixIcon: Icons.phone_callback_outlined,
              keyboardType: TextInputType.phone,
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
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.error)),
              );
            }),

            // Submit
            Obx(() => AppButton(
                  label: 'Register Patient',
                  onPressed: _submit,
                  isLoading: widget.ctrl.isSavingPatient.value,
                  width: double.infinity,
                  height: 52,
                  icon: Icons.person_add,
                )),
          ],
        ),
      ),
    );
  }
}
