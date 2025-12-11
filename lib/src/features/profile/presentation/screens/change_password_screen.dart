import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:customer_app/src/providers/auth_provider.dart';
import 'package:customer_app/src/constants/app_sizes.dart';
import 'package:customer_app/src/common_widgets/custom_widgets.dart';
import 'package:customer_app/src/features/auth/presentation/screens/password_reset_screen.dart'; // For forgot password

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        await Provider.of<AuthProvider>(context, listen: false).changePassword(
          _oldPasswordController.text,
          _newPasswordController.text,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Password changed successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Go back to settings
      } on DioException catch (e) {
        String errorMessage = "Failed to change password. Please try again.";
        if (e.response?.data != null && e.response?.data['detail'] != null) {
          errorMessage = e.response!.data['detail'];
        } else if (e.response?.data != null && e.response?.data['old_password'] != null) {
          errorMessage = e.response!.data['old_password'][0]; // E.g., "Wrong password."
        } else if (e.response?.data != null && e.response?.data['new_password'] != null) {
          errorMessage = e.response!.data['new_password'][0]; // E.g., "Password is too weak."
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("An unexpected error occurred: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Change Password"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomPasswordField(
                controller: _oldPasswordController,
                label: "Old Password",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your old password";
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.p16),
              CustomPasswordField(
                controller: _newPasswordController,
                label: "New Password",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter a new password";
                  }
                  if (value.length < 6) {
                    return "Password must be at least 6 characters long";
                  }
                  if (value == _oldPasswordController.text) {
                    return "New password cannot be the same as old password";
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.p16),
              CustomPasswordField(
                controller: _confirmNewPasswordController,
                label: "Confirm New Password",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please confirm your new password";
                  }
                  if (value != _newPasswordController.text) {
                    return "Passwords do not match";
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.p24),
              CustomButton(
                text: _isLoading ? "Changing..." : "Change Password",
                onPressed: _isLoading ? null : _changePassword,
                isLoading: _isLoading,
              ),
              const SizedBox(height: AppSizes.p16),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PasswordResetScreen(),
                      ),
                    );
                  },
                  child: const Text("Forgot your password?"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}