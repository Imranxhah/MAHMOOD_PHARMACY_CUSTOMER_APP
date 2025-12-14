import 'dart:io';

import 'package:dio/dio.dart'; // Import Dio for exception handling
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatter
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/src/providers/prescription_provider.dart';
import '../../../../constants/app_sizes.dart';
import '../../../../common_widgets/custom_widgets.dart';

class UploadPrescriptionScreen extends StatefulWidget {
  const UploadPrescriptionScreen({super.key});

  @override
  State<UploadPrescriptionScreen> createState() =>
      _UploadPrescriptionScreenState();
}

class _UploadPrescriptionScreenState extends State<UploadPrescriptionScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isUploading = false;
  String? _contactNumberError; // To display backend validation errors

  Future<void> _pickImage(ImageSource source) async {
    final XFile? selectedImage = await _picker.pickImage(source: source);
    setState(() {
      _imageFile = selectedImage;
    });
  }

  Future<void> _uploadPrescription() async {
    // 1. Validate Image
    if (_imageFile == null) {
      _showSnackBar("Please select an image first.", Colors.red);
      return;
    }

    // 2. Validate Form (Contact Number)
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isUploading = true;
      _contactNumberError = null; // Clear previous backend errors
    });

    try {
      await Provider.of<PrescriptionProvider>(
        context,
        listen: false,
      ).uploadPrescription(
        image: File(_imageFile!.path),
        contactNumber: _contactNumberController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );
      if (!mounted) return;
      _showSnackBar("Prescription uploaded successfully!", Colors.green);
      Navigator.of(context).pop(); // Go back after successful upload
    } catch (e) {
      if (!mounted) return;

      // Handle specific errors
      if (e is DioException) {
        if (e.response?.statusCode == 400) {
          // Validation Error
          final data = e.response?.data;
          if (data is Map<String, dynamic> &&
              data.containsKey('contact_number')) {
            setState(() {
              // Extract the first error message for contact_number
              final errors = data['contact_number'];
              if (errors is List && errors.isNotEmpty) {
                _contactNumberError = errors.first.toString();
              } else {
                _contactNumberError = errors.toString();
              }
            });
            // Re-validate form to show the error under the field
            _formKey.currentState!.validate();
          } else {
            _showSnackBar("Invalid data provided.", Colors.red);
          }
        } else if (e.response?.statusCode == 413) {
          _showSnackBar(
            "Image is too large. Please upload a smaller image.",
            Colors.red,
          );
        } else {
          _showSnackBar(
            "Failed to upload prescription: ${e.response?.data['detail'] ?? e.message}",
            Colors.red,
          );
        }
      } else {
        _showSnackBar(
          "Failed to upload prescription: ${e.toString()}",
          Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    _contactNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Prescription")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: () => _showImageSourceActionSheet(context),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(AppSizes.radius12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(AppSizes.radius12),
                          child: Image.file(
                            File(_imageFile!.path),
                            fit: BoxFit.cover,
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt,
                                size: 48,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: AppSizes.p8),
                              const Text("Tap to select image"),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppSizes.p24),

              // Contact Number Field
              CustomTextField(
                controller: _contactNumberController,
                label: "Contact Number",
                hint: "03XXXXXXXXX",
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                validator: (value) {
                  // Check for backend error first
                  if (_contactNumberError != null) {
                    return _contactNumberError;
                  }
                  if (value == null || value.isEmpty) {
                    return "Contact number is required";
                  }
                  if (value.length != 11) {
                    return "Phone number must be 11 digits";
                  }
                  if (!value.startsWith("03")) {
                    return "Phone number must start with 03";
                  }
                  return null;
                },
                // Reset backend error on change
                onChanged: (value) {
                  if (_contactNumberError != null) {
                    setState(() {
                      _contactNumberError = null;
                    });
                  }
                },
              ),
              const SizedBox(height: AppSizes.p16),

              CustomTextField(
                controller: _notesController,
                label: "Notes (Optional)",
                hint: "E.g., Please deliver by evening",
                maxLines: 3,
              ),
              const SizedBox(height: AppSizes.p32),

              CustomButton(
                text: _isUploading ? "Uploading..." : "Upload Prescription",
                onPressed: _isUploading
                    ? null
                    : () {
                        _uploadPrescription();
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}