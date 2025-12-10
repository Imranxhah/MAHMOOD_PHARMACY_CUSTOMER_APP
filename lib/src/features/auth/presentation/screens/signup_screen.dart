import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/src/providers/auth_provider.dart';
import 'package:customer_app/src/constants/app_sizes.dart';
import 'package:customer_app/src/constants/app_strings.dart';
import 'package:customer_app/src/features/auth/presentation/screens/otp_screen.dart';
import 'package:customer_app/src/constants/app_decorations.dart';
import 'package:customer_app/src/features/auth/presentation/screens/login_screen.dart';
import 'package:customer_app/src/common_widgets/app_text_form_field.dart';
import 'package:customer_app/src/common_widgets/app_primary_button.dart';
import 'package:customer_app/src/common_widgets/auth_footer.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _signup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.register(
        _emailController.text,
        _passwordController.text,
        _firstNameController.text,
        _lastNameController.text,
        _phoneNumberController.text,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OTPScreen(
              email: _emailController.text,
              password: _passwordController.text,
            ),
          ),
        );
      } else if (result['status'] == 'unverified') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['data']?['message'] ?? AppStrings.accountNotVerified,
            ),
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OTPScreen(
              email: _emailController.text,
              password: _passwordController.text,
            ),
          ),
        );
      } else if (result['status'] == 'validation_error') {
        final errors = result['data'] as Map<String, dynamic>;
        String errorMessage = AppStrings.pleaseCorrectErrors;
        errors.forEach((field, messages) {
          errorMessage +=
              '${(field.replaceAll('_', ' ').capitalizeFirst() ?? field)}: ${(messages is List ? messages.join(', ') : messages.toString())}\n';
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppStrings.signupFailed}${result['data']?.toString() ?? ''}',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                  AppStrings.createAccount,
                  style: AppDecorations.modernHeaderStyle(context),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: AppSizes.p8),
                Text(
                  "Join us today",
                  style: AppDecorations.modernSubtitleStyle(context),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: AppSizes.p32),
                // First Name
                AppTextFormField(
                  controller: _firstNameController,
                  labelText: AppStrings.firstName,
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: (value) => (value == null || value.isEmpty)
                      ? AppStrings.enterFirstName
                      : null,
                ),
                const SizedBox(height: AppSizes.p16),
                // Last Name
                AppTextFormField(
                  controller: _lastNameController,
                  labelText: AppStrings.lastName,
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: (value) => (value == null || value.isEmpty)
                      ? AppStrings.enterLastName
                      : null,
                ),
                const SizedBox(height: AppSizes.p16),
                // Email
                AppTextFormField(
                  controller: _emailController,
                  labelText: AppStrings.emailAddress,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                  validator: (value) => (value == null || !value.contains('@'))
                      ? AppStrings.enterValidEmail
                      : null,
                ),
                const SizedBox(height: AppSizes.p16),
                // Password
                AppTextFormField(
                  controller: _passwordController,
                  labelText: AppStrings.password,
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
                  validator: (value) => (value == null || value.length < 8)
                      ? AppStrings.passwordMinLength
                      : null,
                ),
                const SizedBox(height: AppSizes.p16),
                // Confirm Password
                AppTextFormField(
                  controller: _confirmPasswordController,
                  labelText: AppStrings.confirmPassword,
                  obscureText: _obscureConfirmPassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppStrings.confirmPasswordRequired;
                    }
                    if (value != _passwordController.text) {
                      return AppStrings.passwordsDoNotMatch;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.p16),
                // Phone Number
                AppTextFormField(
                  controller: _phoneNumberController,
                  labelText: AppStrings.phoneNumber,
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_outlined),
                  validator: (value) => (value == null || value.isEmpty)
                      ? AppStrings.enterPhoneNumber
                      : null,
                ),
                const SizedBox(height: AppSizes.p24),
                // Sign Up Button
                AppPrimaryButton(
                  text: AppStrings.signUp,
                  onPressed: _signup,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: AppSizes.p32),
                // Auth Footer
                AuthFooter(
                  mainText: AppStrings.alreadyHaveAnAccount,
                  linkText: AppStrings.signIn,
                  onLinkPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
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

extension StringExtension on String {
  String? capitalizeFirst() {
    if (isEmpty) return null;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
