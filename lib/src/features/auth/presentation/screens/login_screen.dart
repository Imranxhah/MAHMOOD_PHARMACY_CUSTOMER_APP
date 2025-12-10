import 'package:customer_app/src/features/auth/presentation/screens/otp_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/src/providers/auth_provider.dart';
import 'package:customer_app/src/constants/app_sizes.dart';
import 'package:customer_app/src/constants/app_strings.dart';
import 'package:customer_app/src/features/home/presentation/main_screen.dart';
import 'package:customer_app/src/features/auth/presentation/screens/password_reset_screen.dart';
import 'package:customer_app/src/constants/app_decorations.dart';
import 'package:customer_app/src/features/auth/presentation/screens/signup_screen.dart';
import 'package:customer_app/src/common_widgets/app_text_form_field.dart';
import 'package:customer_app/src/common_widgets/app_primary_button.dart';
import 'package:customer_app/src/common_widgets/app_text_button.dart';
import 'package:customer_app/src/common_widgets/auth_footer.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.login(
        _emailController.text,
        _passwordController.text,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);

      switch (result) {
        case 'success':
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
          break;
        case 'unverified':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.accountNotVerified)),
          );
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OTPScreen(email: _emailController.text),
            ),
          );
          break;
        case 'authentication_failed':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.invalidCredentials)),
          );
          break;
        case 'failed':
        default:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.unknownError)),
          );
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(
        context,
      ).scaffoldBackgroundColor, // Theme-aware background
      body: SafeArea(
        child: SingleChildScrollView(
          // Removed Center widget
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: AppSizes.p20),
                Text(
                  AppStrings.welcomeBack,
                  style: AppDecorations.modernHeaderStyle(context),
                  textAlign: TextAlign.left, // Changed to left align
                ),
                const SizedBox(height: AppSizes.p8),
                Text(
                  AppStrings.signInToContinue,
                  style: AppDecorations.modernSubtitleStyle(context),
                  textAlign: TextAlign.left, // Changed to left align
                ),
                const SizedBox(height: AppSizes.p48),
                AppTextFormField(
                  controller: _emailController,
                  labelText: AppStrings.emailAddress,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                  validator: (value) => (value == null || !value.contains('@'))
                      ? AppStrings.enterValidEmail
                      : null,
                ),
                const SizedBox(height: AppSizes.p20),
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
                  validator: (value) => (value == null || value.length < 6)
                      ? AppStrings.passwordTooShort
                      : null,
                ),
                const SizedBox(height: AppSizes.p12),
                Align(
                  alignment: Alignment.centerRight,
                  child: AppTextButton(
                    text: AppStrings.forgotPassword,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PasswordResetScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSizes.p24),
                AppPrimaryButton(
                  text: AppStrings.signIn,
                  onPressed: _login,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: AppSizes.p32),
                AuthFooter(
                  mainText: AppStrings.dontHaveAnAccount,
                  linkText: AppStrings.signUp,
                  onLinkPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
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
