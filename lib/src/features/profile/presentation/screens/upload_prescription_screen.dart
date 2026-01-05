import 'dart:io';

import 'package:dio/dio.dart'; // Import Dio for exception handling
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatter
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/src/providers/prescription_provider.dart';
import 'package:customer_app/src/providers/branch_provider.dart';
import 'package:customer_app/src/providers/address_provider.dart'; // Import AddressProvider
import 'package:customer_app/src/models/branch_model.dart';
import 'package:customer_app/src/models/address_model.dart'; // Import AddressModel
import 'package:customer_app/src/features/profile/presentation/screens/address_list_screen.dart'; // Import AddressListScreen
import '../../../../constants/app_sizes.dart';
import '../../../../common_widgets/custom_widgets.dart';
import '../../../../common_widgets/pharmacy_loader_with_background.dart';

class UploadPrescriptionScreen extends StatefulWidget {
  const UploadPrescriptionScreen({super.key});

  @override
  State<UploadPrescriptionScreen> createState() =>
      _UploadPrescriptionScreenState();
}

class _UploadPrescriptionScreenState extends State<UploadPrescriptionScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _shippingAddressController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isUploading = false;
  String? _contactNumberError; // To display backend validation errors
  BranchModel? _selectedBranch;
  AddressModel? _selectedAddress; // For address dropdown

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BranchProvider>(context, listen: false).fetchLocationAndData();
      Provider.of<AddressProvider>(context, listen: false).fetchAddresses();
    });
  }

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

    // 2. Validate Form (Contact Number and Address)
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // 3. Validate Address manually if controller is empty (though validator should catch it)
    if (_shippingAddressController.text.isEmpty) {
        _showSnackBar("Address is required.", Colors.red);
        return;
    }

    // 4. Validate Branch
    if (_selectedBranch == null) {
      _showSnackBar("Please select a branch.", Colors.red);
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
        branchId: _selectedBranch!.id,
        address: _shippingAddressController.text,
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
    _contactNumberController.dispose();
    _shippingAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Prescription")),
      body: Stack(
        children: [
          SingleChildScrollView(
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
                  const SizedBox(height: AppSizes.p24),

                  // Saved Addresses Dropdown
                  Text(
                    "Select Saved Address",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSizes.p12),
                  Consumer<AddressProvider>(
                    builder: (context, addressProvider, child) {
                      if (addressProvider.isLoading) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      
                      // Check if addresses are empty and not loading
                      if (addressProvider.addresses.isEmpty &&
                          !addressProvider.isLoading) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "No saved addresses found.",
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                            const SizedBox(height: AppSizes.p8),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const AddressListScreen()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppSizes.radius8),
                                ),
                              ),
                              child: const Text("Add New Address"),
                            ),
                            const SizedBox(height: AppSizes.p16),
                          ],
                        );
                      }

                      return DropdownButtonFormField<AddressModel>(
                        value: _selectedAddress,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          hintText: "Choose from saved addresses",
                        ),
                        isExpanded: true,
                        items: addressProvider.addresses.map((address) {
                          return DropdownMenuItem<AddressModel>(
                            value: address,
                            child: Text(
                              address.address,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedAddress = value;
                            if (value != null) {
                              _shippingAddressController.text = value.address;
                            }
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: AppSizes.p24),

                  // Address Section
                  Text(
                    "Enter your shipping address",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSizes.p12),
                  CustomTextField(
                    controller: _shippingAddressController,
                    hint: "e.g., House No. 123, Street 45, City",
                    maxLines: 3,
                    validator: (value) =>
                        value!.isEmpty ? "Address cannot be empty" : null,
                  ),
                  const SizedBox(height: AppSizes.p24),

                  // Branch Section
                  Text(
                    "Select Nearest Branch",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppSizes.p12),
                  Consumer<BranchProvider>(
                    builder: (context, branchProvider, child) {
                      if (branchProvider.isLoading ||
                          branchProvider.isLocationLoading) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (branchProvider.locationError != null) {
                        return Text(
                          "Location Error: ${branchProvider.locationError!}",
                          style: const TextStyle(color: Colors.red),
                        );
                      }
                      if (branchProvider.error != null) {
                        return Text(
                          "Branch Error: ${branchProvider.error!}",
                          style: const TextStyle(color: Colors.red),
                        );
                      }
                      if (branchProvider.foundBranches.isEmpty) {
                        return const Text("No branches found near your location.");
                      }

                      // Auto-select the first nearest branch if none is selected
                      if (_selectedBranch == null &&
                          branchProvider.foundBranches.isNotEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          setState(() {
                            _selectedBranch = branchProvider.foundBranches.first;
                          });
                        });
                      }

                      return DropdownButtonFormField<BranchModel>(
                        value: _selectedBranch,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        hint: const Text("Choose a branch"),
                        isExpanded: true, // Prevent overflow
                        items: branchProvider.foundBranches.map((branch) {
                          return DropdownMenuItem<BranchModel>(
                            value: branch,
                            child: Text(
                              "${branch.name} (${branch.distanceKm?.toStringAsFixed(1)} km)",
                              overflow: TextOverflow.ellipsis, // Handle text overflow
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedBranch = value;
                          });
                        },
                      );
                    },
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
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const PharmacyLoaderWithBackground(),
            ),
        ],
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
