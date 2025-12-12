import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/src/providers/auth_provider.dart';
import 'package:customer_app/src/constants/app_sizes.dart';
import 'package:customer_app/src/constants/app_strings.dart';
import 'package:customer_app/src/features/auth/presentation/screens/password_reset_confirm_screen.dart';
import 'package:customer_app/src/common_widgets/custom_widgets.dart';
import 'package:customer_app/src/constants/app_decorations.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _requestReset() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.requestPasswordReset(
        _emailController.text,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        // Here, instead of pushReplacement, we might want to push a new screen
        // that informs the user the OTP has been sent, and guides them to the confirmation screen.
        // For now, matching the original logic but with new UI.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                PasswordResetConfirmScreen(email: _emailController.text),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.resetEmailFailed)),
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
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurface,
        ),
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
                  AppStrings.resetPassword,
                  style: AppDecorations.modernHeaderStyle(context),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: AppSizes.p8),
                Text(
                  "Enter your email to receive a password reset OTP.",
                  style: AppDecorations.modernSubtitleStyle(context),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: AppSizes.p48),
                CustomTextField(
                  controller: _emailController,
                  label: AppStrings.emailAddress,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (value) => (value == null || !value.contains('@'))
                      ? AppStrings.enterValidEmail
                      : null,
                ),
                const SizedBox(height: AppSizes.p24),
                CustomButton(
                  text: AppStrings.sendResetOtp,
                  onPressed: _requestReset,
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
