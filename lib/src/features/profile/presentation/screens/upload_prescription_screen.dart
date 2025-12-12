import 'dart:io';

import 'package:flutter/material.dart';
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
  bool _isUploading = false;

  Future<void> _pickImage(ImageSource source) async {
    final XFile? selectedImage = await _picker.pickImage(source: source);
    setState(() {
      _imageFile = selectedImage;
    });
  }

  Future<void> _uploadPrescription() async {
    if (_imageFile == null) {
      _showSnackBar("Please select an image first.", Colors.red);
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      await Provider.of<PrescriptionProvider>(
        context,
        listen: false,
      ).uploadPrescription(
        image: File(_imageFile!.path),
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );
      if (!mounted) return;
      _showSnackBar("Prescription uploaded successfully!", Colors.green);
      Navigator.of(context).pop(); // Go back after successful upload
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        "Failed to upload prescription: ${e.toString()}",
        Colors.red,
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Prescription")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizes.p16),
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
                    ? Image.file(File(_imageFile!.path), fit: BoxFit.cover)
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
            SizedBox(height: AppSizes.p24),
            CustomTextField(
              controller: _notesController,
              hint: "Optional notes for the pharmacist",
              maxLines: 3,
            ),
            SizedBox(height: AppSizes.p32),
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
