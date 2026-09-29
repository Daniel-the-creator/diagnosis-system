import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/route_constants.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  String _selectedRole = 'doctor';
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  final _auth = Get.find<AuthController>();

  static const _roles = [
    {
      'value': 'doctor',
      'label': 'Doctor / Consultant',
      'icon': Icons.medical_services_outlined
    },
    {
      'value': 'gate_officer',
      'label': 'Gate / Triage Officer',
      'icon': Icons.meeting_room_outlined
    },
    {
      'value': 'registration_officer',
      'label': 'Registration Officer',
      'icon': Icons.how_to_reg_outlined
    },
    {
      'value': 'hospital_admin',
      'label': 'Hospital Administrator',
      'icon': Icons.admin_panel_settings_outlined
    },
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_auth.isLoading.value) return;
    if (!_formKey.currentState!.validate()) return;
    _auth.clearError();
    final user = await _auth.signUp(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      fullName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      role: _selectedRole,
    );

    if (user != null && !user.active && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.hourglass_top_rounded,
                  color: AppColors.primary, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text('Registration Submitted',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${user.fullName}!\n\nYour staff account has been created. For security and compliance, new staff accounts must be reviewed and activated by a Hospital Administrator before access is granted.\n\nPlease contact your hospital administrator to activate your account.',
                style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                Get.offAllNamed(AppRoutes.login);
              },
              child: const Text('Back to Sign In'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width > 800;

    return Scaffold(
      backgroundColor: AppColors.sidebarBackground,
      body: Row(
        children: [
          // ── Left panel (desktop only) ──────────────────────────
          if (isWide)
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.sidebarGradient,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 40,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.local_hospital,
                          color: Colors.white, size: 52),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'MediFlow HMS',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Hospital & Diagnostic Centre\nStaff Registration & Portal',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        color: AppColors.sidebarText,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 50),
                    const _FeatureRow(
                        icon: Icons.security,
                        text: 'Verified role-based departmental access'),
                    const SizedBox(height: 16),
                    const _FeatureRow(
                        icon: Icons.sync,
                        text: 'Real-time patient queues & vitals'),
                    const SizedBox(height: 16),
                    const _FeatureRow(
                        icon: Icons.verified_user,
                        text: 'Cloud Firestore encrypted clinical records'),
                  ],
                ),
              ),
            ),

          // ── Right panel (Sign Up form) ─────────────────────────
          Container(
            width: isWide ? 500 : size.width,
            decoration: const BoxDecoration(
              color: AppColors.background,
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isWide) ...[
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.local_hospital,
                                color: Colors.white, size: 26),
                          ),
                          const SizedBox(height: 20),
                        ],
                        const Text('Create Staff Account',
                            style: AppTextStyles.headlineLarge),
                        const SizedBox(height: 8),
                        Text(
                          'Register to access your clinical or administrative station',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 28),

                        // Full Name
                        AppTextField(
                          label: 'Full Name',
                          controller: _nameCtrl,
                          prefixIcon: Icons.person_outline,
                          hint: 'Dr. Daniel Ilesanmi',
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Full name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Email
                        AppTextField(
                          label: 'Email Address',
                          controller: _emailCtrl,
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          hint: 'staff@hospital.com',
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Email is required';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(v.trim())) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Phone
                        AppTextField(
                          label: 'Phone Number',
                          controller: _phoneCtrl,
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          hint: '+234 801 234 5678',
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Phone number is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Staff Role Dropdown
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Staff Role / Designation',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedRole,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.badge_outlined,
                                    color: AppColors.primary, size: 20),
                                filled: true,
                                fillColor: AppColors.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: AppColors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: AppColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: AppColors.primary, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                              ),
                              items: _roles.map((r) {
                                return DropdownMenuItem<String>(
                                  value: r['value'] as String,
                                  child: Row(
                                    children: [
                                      Icon(r['icon'] as IconData,
                                          size: 18, color: AppColors.primary),
                                      const SizedBox(width: 10),
                                      Text(r['label'] as String,
                                          style: AppTextStyles.bodyMedium),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedRole = val);
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Password
                        AppTextField(
                          label: 'Password',
                          controller: _passCtrl,
                          prefixIcon: Icons.lock_outline,
                          obscureText: _obscurePass,
                          hint: '••••••••',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePass
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePass = !_obscurePass),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Password is required';
                            }
                            if (v.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Confirm Password
                        AppTextField(
                          label: 'Confirm Password',
                          controller: _confirmPassCtrl,
                          prefixIcon: Icons.lock_outline,
                          obscureText: _obscureConfirm,
                          hint: '••••••••',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (v != _passCtrl.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                          onSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 20),

                        // Error message
                        Obx(() {
                          final err = _auth.errorMessage.value;
                          if (err.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          final isExistingAccount = err.toLowerCase().contains('already exists') ||
                              err.toLowerCase().contains('sign in');
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.errorLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color:
                                      AppColors.error.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.error_outline,
                                        color: AppColors.error, size: 18),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        err,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (isExistingAccount) ...[
                                  const SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        backgroundColor: AppColors.primary
                                            .withValues(alpha: 0.1),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                      ),
                                      icon: const Icon(Icons.login,
                                          size: 16, color: AppColors.primary),
                                      label: const Text(
                                        'Sign In to Account',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      onPressed: () {
                                        _auth.clearError();
                                        Get.offNamed(AppRoutes.login);
                                      },
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),

                        // Sign Up button
                        Obx(() => AppButton(
                              label: 'Create Account',
                              onPressed: _submit,
                              isLoading: _auth.isLoading.value,
                              width: double.infinity,
                              height: 52,
                              icon: Icons.person_add,
                            )),

                        const SizedBox(height: 24),

                        // Already have an account link
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              TextButton(
                                onPressed: () => Get.offNamed(AppRoutes.login),
                                child: Text(
                                  'Sign In',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.sidebarText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
