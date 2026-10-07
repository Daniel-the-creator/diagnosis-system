import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _auth = Get.find<AuthController>();
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _auth.clearError();
    await _auth.sendPasswordReset(_emailCtrl.text.trim());
    if (_auth.errorMessage.value.isEmpty) {
      setState(() => _sent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: const Text('Forgot Password'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width < 600 ? 20 : 32,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: _sent
                ? _SuccessPanel(email: _emailCtrl.text)
                : _Form(
                    formKey: _formKey,
                    emailCtrl: _emailCtrl,
                    auth: _auth,
                    onSubmit: _submit,
                  ),
          ),
        ),
      ),
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({
    required this.formKey,
    required this.emailCtrl,
    required this.auth,
    required this.onSubmit,
  });
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final AuthController auth;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_reset, size: 48, color: AppColors.primary),
          const SizedBox(height: 20),
          const Text('Reset Password', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Enter your work email address and we\'ll send you a link to reset your password.',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          AppTextField(
            label: 'Email Address',
            controller: emailCtrl,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email is required';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (auth.errorMessage.value.isEmpty) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(auth.errorMessage.value,
                  style:
                      AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
            );
          }),
          Obx(() => AppButton(
                label: 'Send Reset Link',
                onPressed: onSubmit,
                isLoading: auth.isLoading.value,
                width: double.infinity,
                height: 52,
                icon: Icons.send,
              )),
        ],
      ),
    );
  }
}

class _SuccessPanel extends StatelessWidget {
  const _SuccessPanel({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: AppColors.successLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.mark_email_read,
              color: AppColors.success, size: 40),
        ),
        const SizedBox(height: 24),
        const Text('Email Sent!', style: AppTextStyles.headlineMedium),
        const SizedBox(height: 12),
        Text(
          'We\'ve sent password reset instructions to\n$email',
          textAlign: TextAlign.center,
          style:
              AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 32),
        AppButton(
          label: 'Back to Login',
          onPressed: () => Get.back(),
          width: double.infinity,
          height: 52,
          variant: AppButtonVariant.outlined,
          icon: Icons.arrow_back,
        ),
      ],
    );
  }
}
