import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/src/providers/auth_provider.dart';
import 'package:customer_app/src/constants/app_sizes.dart';
import 'package:customer_app/src/constants/app_strings.dart';
import 'package:customer_app/src/features/home/presentation/main_screen.dart';
import 'package:customer_app/src/common_widgets/app_text_form_field.dart';
import 'package:customer_app/src/common_widgets/app_primary_button.dart';
import 'package:customer_app/src/constants/app_decorations.dart';

class PasswordResetConfirmScreen extends StatefulWidget {
  final String email;
  const PasswordResetConfirmScreen({super.key, required this.email});

  @override
  State<PasswordResetConfirmScreen> createState() => _PasswordResetConfirmScreenState();
}

class _PasswordResetConfirmScreenState extends State<PasswordResetConfirmScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _confirmReset() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.confirmPasswordReset(
        widget.email,
        _otpController.text,
        _passwordController.text,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.passwordResetSuccess)),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.passwordResetFailed)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: AppSizes.p20),
                Text(
                  AppStrings.confirmReset,
                  style: AppDecorations.modernHeaderStyle(context),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: AppSizes.p8),
                Text(
                  "Enter the OTP sent to your email and your new password.",
                  style: AppDecorations.modernSubtitleStyle(context),
                   textAlign: TextAlign.left,
                ),
                const SizedBox(height: AppSizes.p48),
                AppTextFormField(
                  controller: _otpController,
                  labelText: AppStrings.otp,
                  prefixIcon: const Icon(Icons.password_outlined),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? AppStrings.enterOtp : null,
                ),
                const SizedBox(height: AppSizes.p20),
                AppTextFormField(
                  controller: _passwordController,
                  labelText: AppStrings.newPassword,
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                   suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (value) =>
                      (value == null || value.length < 8) ? AppStrings.passwordMinLength : null,
                ),
                const SizedBox(height: AppSizes.p24),
                AppPrimaryButton(
                      text: AppStrings.resetPassword,
                      onPressed: _confirmReset,
                      isLoading: _isLoading,
                    ),
                const SizedBox(height: AppSizes.p20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}