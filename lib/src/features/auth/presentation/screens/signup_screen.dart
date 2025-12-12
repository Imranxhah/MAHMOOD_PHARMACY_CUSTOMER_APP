import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/src/providers/auth_provider.dart';
import 'package:customer_app/src/constants/app_sizes.dart';
import 'package:customer_app/src/constants/app_strings.dart';
import 'package:customer_app/src/features/auth/presentation/screens/otp_screen.dart';
import 'package:customer_app/src/constants/app_decorations.dart';
import 'package:customer_app/src/features/auth/presentation/screens/login_screen.dart';
import 'package:customer_app/src/common_widgets/custom_widgets.dart';
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
                CustomTextField(
                  controller: _firstNameController,
                  label: AppStrings.firstName,
                  prefixIcon: Icons.person_outline,
                  validator: (value) => (value == null || value.isEmpty)
                      ? AppStrings.enterFirstName
                      : null,
                ),
                const SizedBox(height: AppSizes.p16),
                // Last Name
                CustomTextField(
                  controller: _lastNameController,
                  label: AppStrings.lastName,
                  prefixIcon: Icons.person_outline,
                  validator: (value) => (value == null || value.isEmpty)
                      ? AppStrings.enterLastName
                      : null,
                ),
                const SizedBox(height: AppSizes.p16),
                // Email
                CustomTextField(
                  controller: _emailController,
                  label: AppStrings.emailAddress,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (value) => (value == null || !value.contains('@'))
                      ? AppStrings.enterValidEmail
                      : null,
                ),
                const SizedBox(height: AppSizes.p16),
                // Password
                CustomPasswordField(
                  controller: _passwordController,
                  label: AppStrings.password,
                  validator: (value) => (value == null || value.length < 8)
                      ? AppStrings.passwordMinLength
                      : null,
                ),
                const SizedBox(height: AppSizes.p16),
                // Confirm Password
                CustomPasswordField(
                  controller: _confirmPasswordController,
                  label: AppStrings.confirmPassword,
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
                CustomTextField(
                  controller: _phoneNumberController,
                  label: AppStrings.phoneNumber,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  validator: (value) => (value == null || value.isEmpty)
                      ? AppStrings.enterPhoneNumber
                      : null,
                ),
                const SizedBox(height: AppSizes.p24),
                // Sign Up Button
                CustomButton(
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
