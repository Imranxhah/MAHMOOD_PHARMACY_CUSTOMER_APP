import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/src/providers/auth_provider.dart';
import 'package:customer_app/src/constants/app_sizes.dart';
import 'package:customer_app/src/constants/app_strings.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _mobileController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _mobileController.text = user.mobile;
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      Map<String, String> dataToUpdate = {};
      if(_firstNameController.text != authProvider.user?.firstName) {
        dataToUpdate['first_name'] = _firstNameController.text;
      }
      if(_lastNameController.text != authProvider.user?.lastName) {
        dataToUpdate['last_name'] = _lastNameController.text;
      }
       if(_mobileController.text != authProvider.user?.mobile) {
        dataToUpdate['mobile'] = _mobileController.text;
      }

      if (dataToUpdate.isNotEmpty) {
        final success = await authProvider.updateProfile(dataToUpdate);
        if (!mounted) return;
        if (success) {
          Navigator.of(context).pop();
        } else {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.updateFailed)),
          );
        }
      } else {
        Navigator.of(context).pop();
      }
      
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.editProfile)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: AppStrings.firstName),
                validator: (value) =>
                    (value == null || value.isEmpty) ? AppStrings.enterFirstName : null,
              ),
              const SizedBox(height: AppSizes.p12),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: AppStrings.lastName),
                validator: (value) =>
                    (value == null || value.isEmpty) ? AppStrings.enterLastName : null,
              ),
              const SizedBox(height: AppSizes.p12),
               TextFormField(
                controller: _mobileController,
                decoration: const InputDecoration(labelText: AppStrings.mobile),
                validator: (value) =>
                    (value == null || value.isEmpty) ? AppStrings.enterMobile : null,
              ),
              const SizedBox(height: AppSizes.p20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _updateProfile,
                      child: const Text(AppStrings.save),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
