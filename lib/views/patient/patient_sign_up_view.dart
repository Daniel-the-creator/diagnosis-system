import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/route_constants.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class PatientSignUpView extends StatefulWidget {
  const PatientSignUpView({super.key});

  @override
  State<PatientSignUpView> createState() => _PatientSignUpViewState();
}

class _PatientSignUpViewState extends State<PatientSignUpView> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _emergencyNameCtrl = TextEditingController();
  final _emergencyPhoneCtrl = TextEditingController();
  final _allergiesCtrl = TextEditingController();
  final _medHistoryCtrl = TextEditingController();
  final _insuranceProviderCtrl = TextEditingController();
  final _insuranceNumCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  String _gender = 'Male';
  String? _bloodGroup;
  String? _genotype;
  DateTime? _dob;
  bool _obscure = true;
  bool _obscureConfirm = true;

  final _auth = Get.find<AuthController>();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    _allergiesCtrl.dispose();
    _medHistoryCtrl.dispose();
    _insuranceProviderCtrl.dispose();
    _insuranceNumCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dob = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _auth.clearError();

    final rawAllergies = _allergiesCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    await _auth.signUpPatient(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      fullName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      gender: _gender,
      dateOfBirth: _dob,
      address: _addressCtrl.text.trim().isNotEmpty ? _addressCtrl.text.trim() : null,
      emergencyContactName:
          _emergencyNameCtrl.text.trim().isNotEmpty ? _emergencyNameCtrl.text.trim() : null,
      emergencyContactPhone:
          _emergencyPhoneCtrl.text.trim().isNotEmpty ? _emergencyPhoneCtrl.text.trim() : null,
      bloodGroup: _bloodGroup,
      genotype: _genotype,
      allergies: rawAllergies,
      medicalHistory: _medHistoryCtrl.text.trim().isNotEmpty ? _medHistoryCtrl.text.trim() : null,
      insuranceProvider:
          _insuranceProviderCtrl.text.trim().isNotEmpty ? _insuranceProviderCtrl.text.trim() : null,
      insuranceNumber:
          _insuranceNumCtrl.text.trim().isNotEmpty ? _insuranceNumCtrl.text.trim() : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Patient Registration'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.person_add_rounded, color: AppColors.primary, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Create Patient Account', style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold)),
                              Text(
                                'Register to access live queue tracking, test results & digital health records',
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),

                      Obx(() {
                        final error = _auth.errorMessage.value;
                        if (error.isEmpty) return const SizedBox.shrink();
                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.error.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(error, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
                              ),
                            ],
                          ),
                        );
                      }),

                      // ── Personal Info ──────────────────────────
                      Text('Personal Information', style: AppTextStyles.h4.copyWith(color: AppColors.primary)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _nameCtrl,
                              label: 'Full Name *',
                              hint: 'e.g. Sarah Connor',
                              prefixIcon: const Icon(Icons.person_outline),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _gender,
                              decoration: const InputDecoration(
                                labelText: 'Gender *',
                                prefixIcon: Icon(Icons.wc_outlined),
                              ),
                              items: ['Male', 'Female', 'Other']
                                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _gender = v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _pickDob,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Date of Birth',
                                  prefixIcon: Icon(Icons.cake_outlined),
                                ),
                                child: Text(
                                  _dob == null ? 'Select Date of Birth' : DateFormat.yMMMd().format(_dob!),
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: _dob == null ? AppColors.textSecondary : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppTextField(
                              controller: _phoneCtrl,
                              label: 'Phone Number *',
                              hint: 'e.g. +1 555-0199',
                              keyboardType: TextInputType.phone,
                              prefixIcon: const Icon(Icons.phone_outlined),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Phone number is required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _addressCtrl,
                        label: 'Residential Address',
                        hint: 'Street, City, State',
                        prefixIcon: const Icon(Icons.home_outlined),
                      ),

                      const SizedBox(height: 24),
                      Text('Emergency Contact', style: AppTextStyles.h4.copyWith(color: AppColors.primary)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _emergencyNameCtrl,
                              label: 'Contact Name',
                              hint: 'e.g. John Connor (Spouse)',
                              prefixIcon: const Icon(Icons.contact_phone_outlined),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppTextField(
                              controller: _emergencyPhoneCtrl,
                              label: 'Contact Phone',
                              hint: 'e.g. +1 555-0200',
                              keyboardType: TextInputType.phone,
                              prefixIcon: const Icon(Icons.phone_in_talk_outlined),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      Text('Medical Information', style: AppTextStyles.h4.copyWith(color: AppColors.primary)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _bloodGroup,
                              decoration: const InputDecoration(
                                labelText: 'Blood Group',
                                prefixIcon: Icon(Icons.bloodtype_outlined),
                              ),
                              items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                                  .map((bg) => DropdownMenuItem(value: bg, child: Text(bg)))
                                  .toList(),
                              onChanged: (v) => setState(() => _bloodGroup = v),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _genotype,
                              decoration: const InputDecoration(
                                labelText: 'Genotype',
                                prefixIcon: Icon(Icons.biotech_outlined),
                              ),
                              items: ['AA', 'AS', 'SS', 'AC']
                                  .map((gt) => DropdownMenuItem(value: gt, child: Text(gt)))
                                  .toList(),
                              onChanged: (v) => setState(() => _genotype = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _allergiesCtrl,
                        label: 'Allergies (comma separated)',
                        hint: 'e.g. Penicillin, Peanuts, Latex',
                        prefixIcon: const Icon(Icons.warning_amber_outlined),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _medHistoryCtrl,
                        label: 'Pre-existing Medical History / Notes',
                        hint: 'e.g. Hypertension, Asthma',
                        prefixIcon: const Icon(Icons.notes_outlined),
                      ),

                      const SizedBox(height: 24),
                      Text('Account Security', style: AppTextStyles.h4.copyWith(color: AppColors.primary)),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _emailCtrl,
                        label: 'Email Address *',
                        hint: 'name@example.com',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email_outlined),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Email is required';
                          if (!GetUtils.isEmail(v.trim())) return 'Enter a valid email address';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _passCtrl,
                              label: 'Password *',
                              hint: 'Minimum 6 characters',
                              obscureText: _obscure,
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                              validator: (v) {
                                if (v == null || v.length < 6) return 'Password must be at least 6 chars';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppTextField(
                              controller: _confirmPassCtrl,
                              label: 'Confirm Password *',
                              hint: 'Re-enter password',
                              obscureText: _obscureConfirm,
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                              ),
                              validator: (v) {
                                if (v != _passCtrl.text) return 'Passwords do not match';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),
                      Obx(() => AppButton(
                            text: 'Create Patient Account',
                            onPressed: _submit,
                            isLoading: _auth.isLoading.value,
                            isFullWidth: true,
                          )),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Already registered? ', style: AppTextStyles.bodySmall),
                          GestureDetector(
                            onTap: () => Get.toNamed(AppRoutes.patientLogin),
                            child: Text(
                              'Sign in here',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
