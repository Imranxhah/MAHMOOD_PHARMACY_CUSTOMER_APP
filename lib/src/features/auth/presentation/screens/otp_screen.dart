import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/src/providers/auth_provider.dart';
import 'package:customer_app/src/constants/app_sizes.dart';
import 'package:customer_app/src/constants/app_strings.dart';
import 'package:flutter/services.dart'; // Import for FilteringTextInputFormatter
import 'dart:async'; // Import for Timer
import 'package:customer_app/src/features/home/presentation/main_screen.dart';

class OTPScreen extends StatefulWidget {
  final String email;
  final String? password; // New optional parameter
  const OTPScreen({super.key, required this.email, this.password});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false; // New state variable
  int _countdown = 0; // New state variable for countdown
  Timer? _timer; // New state variable for timer

  @override
  void initState() {
    super.initState();
    _resendOtp(); // Automatically request OTP when screen loads
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel timer to prevent memory leaks
    _otpController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdown = 60; // Start 60-second countdown
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  Future<void> _resendOtp() async {
    if (_isResending || _countdown > 0)
      return; // Prevent multiple resend requests

    setState(() => _isResending = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.resendOtp(widget.email);
    if (!mounted) return;
    setState(() => _isResending = false);

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? AppStrings.otpSent)),
      );
      _startCountdown(); // Start countdown after successful resend
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? AppStrings.otpResendFailed),
        ),
      );
    }
  }

  Future<void> _verifyOtp() async {
    if (_formKey.currentState!.validate() && !_isLoading) {
      // Add !isLoading check
      setState(() => _isLoading = true);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.verifyOtp(
        widget.email,
        _otpController.text,
      );
      if (!mounted) return;
      setState(() => _isLoading = false); // Stop loading regardless of success

      if (result['success']) {
        // OTP verification was successful. Now, attempt to auto-login.
        if (authProvider.authStatus == AuthStatus.authenticated) {
          // If verifyOtp already logged in the user (e.g., backend returned tokens)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ?? AppStrings.verifySuccessLoggedIn,
              ),
            ),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainScreen()),
            (Route<dynamic> route) => false, // Remove all routes below
          );
        } else if (widget.password != null) {
          // If verifyOtp didn't auto-login, but we have the password, try explicit login
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ?? AppStrings.verifySuccessLoggingIn,
              ),
            ),
          );
          final loginResult = await authProvider.login(
            widget.email,
            widget.password!,
          );
          if (!mounted) return;

          if (loginResult == 'success') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(AppStrings.loginSuccess)),
            );
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainScreen()),
              (Route<dynamic> route) => false, // Remove all routes below
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(AppStrings.verifySuccessAutoLoginFailed),
              ),
            );
            Navigator.of(context).pop(); // Go back to the login screen
          }
        } else {
          // OTP successful, but no password available and verifyOtp didn't auto-login
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ?? AppStrings.verifySuccessPleaseLogin,
              ),
            ),
          );
          Navigator.of(context).pop(); // Go back to the login screen
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? AppStrings.otpVerifyFailed),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.verifyOtp)),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text('${AppStrings.otpSentTo}${widget.email}'),
              const SizedBox(height: AppSizes.p20),
              TextFormField(
                controller: _otpController,
                decoration: const InputDecoration(
                  labelText: AppStrings.otpCode,
                ),
                keyboardType: TextInputType.number,
                maxLength: 6, // Restrict to 6 digits
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ], // Only allow digits
                onChanged: (value) {
                  if (value.length == 6) {
                    _verifyOtp(); // Automatically verify when 6 digits are entered
                  }
                },
                validator: (value) => (value == null || value.length != 6)
                    ? AppStrings.enterValidOtp
                    : null,
              ),
              const SizedBox(height: AppSizes.p20),
              // Removed the ElevatedButton for manual verification as it will be automatically handled
              if (_isLoading) // Show loading indicator if verification is in progress
                const CircularProgressIndicator(),
              const SizedBox(height: AppSizes.p12),
              TextButton(
                onPressed: _countdown == 0 && !_isResending
                    ? _resendOtp
                    : null, // Disable if resending or countdown active
                child: Text(
                  _countdown > 0
                      ? '${AppStrings.resendOtpIn}$_countdown s'
                      : AppStrings.resendOtp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
