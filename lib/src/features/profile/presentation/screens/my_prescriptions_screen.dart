import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/src/providers/prescription_provider.dart';
import 'package:customer_app/src/providers/auth_provider.dart';
import 'package:customer_app/src/features/auth/presentation/screens/login_screen.dart';
import 'package:customer_app/src/models/prescription_model.dart';
import '../../../../constants/app_sizes.dart';
import 'upload_prescription_screen.dart';

class MyPrescriptionsScreen extends StatefulWidget {
  const MyPrescriptionsScreen({super.key});

  @override
  State<MyPrescriptionsScreen> createState() => _MyPrescriptionsScreenState();
}

class _MyPrescriptionsScreenState extends State<MyPrescriptionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated) {
        Provider.of<PrescriptionProvider>(
          context,
          listen: false,
        ).listPrescriptions();
      }
    });
  }

  Future<void> _refresh() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated) {
      await Provider.of<PrescriptionProvider>(
        context,
        listen: false,
      ).listPrescriptions(refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    // 1. Unauthenticated State
    if (!authProvider.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text("My Prescriptions")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.p24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_person_outlined,
                  size: 80,
                  color: theme.colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: AppSizes.p24),
                Text(
                  "Access Restricted",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSizes.p8),
                Text(
                  "Please login to manage your prescriptions.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSizes.p32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text("Login Now"),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 2. Main Authenticated Content
    return Scaffold(
      appBar: AppBar(title: const Text("My Prescriptions")),
      body: Consumer<PrescriptionProvider>(
        builder: (context, prescriptionProvider, child) {
          // Loading State
          if (prescriptionProvider.isLoading &&
              prescriptionProvider.prescriptions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error State
          if (prescriptionProvider.error != null &&
              prescriptionProvider.prescriptions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.p24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 60,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: AppSizes.p16),
                    Text(
                      "Something went wrong",
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSizes.p8),
                    Text(
                      prescriptionProvider.error!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSizes.p16),
                    OutlinedButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Try Again"),
                    ),
                  ],
                ),
              ),
            );
          }

          // Empty List State
          if (prescriptionProvider.prescriptions.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 80,
                          color: theme.colorScheme.secondary.withOpacity(0.4),
                        ),
                        const SizedBox(height: AppSizes.p16),
                        Text(
                          "No prescriptions yet",
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSizes.p8),
                        Text(
                          "Tap the + button to upload one.",
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          // List of Prescriptions
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSizes.p16),
              itemCount: prescriptionProvider.prescriptions.length,
              separatorBuilder: (ctx, i) =>
                  const SizedBox(height: AppSizes.p20),
              itemBuilder: (context, index) {
                final prescription = prescriptionProvider.prescriptions[index];
                return _buildPrescriptionCard(context, prescription);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const UploadPrescriptionScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text("Upload New"),
      ),
    );
  }

  Widget _buildPrescriptionCard(
    BuildContext context,
    PrescriptionModel prescription,
  ) {
    final theme = Theme.of(context);
    const double cardRadius = 16.0;

    return Card(
      elevation: 2,
      shadowColor: theme.shadowColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Header
          Stack(
            children: [
              Container(
                height: 180,
                width: double.infinity,
                color: theme.colorScheme.surfaceContainerHighest,
                child: prescription.imageUrl.isNotEmpty
                    ? Image.network(
                        prescription.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildImagePlaceholder(theme),
                      )
                    : _buildImagePlaceholder(theme),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(prescription.status, context),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(prescription.status),
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        prescription.status.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.9),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Text(
                    prescription.createdAt.toLocal().toString().split(' ')[0],
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (prescription.notes != null &&
                    prescription.notes!.isNotEmpty) ...[
                  Text(
                    "Your Notes",
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    prescription.notes!,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.p16),
                ],
                if (prescription.adminFeedback != null &&
                    prescription.adminFeedback!.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: AppSizes.p12),
                    padding: const EdgeInsets.all(AppSizes.p12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer.withOpacity(0.15),
                      border: Border.all(
                        color: theme.colorScheme.error.withOpacity(0.2),
                      ),
                      borderRadius: BorderRadius.circular(AppSizes.radius8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Pharmacist Feedback:",
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          prescription.adminFeedback!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (prescription.status.toLowerCase() == 'pending') ...[
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _showEditSheet(context, prescription),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text("Edit"),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () =>
                            _showDeleteConfirmation(context, prescription.id),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text("Delete"),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.errorContainer,
                          foregroundColor: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            size: 32,
          ),
          const SizedBox(height: 4),
          Text(
            "No Image",
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  // REPLACED: AlertDialog with ModalBottomSheet to fix keyboard overflow
  void _showEditSheet(BuildContext context, PrescriptionModel prescription) {
    final theme = Theme.of(context);
    final notesController = TextEditingController(text: prescription.notes);
    final contactController = TextEditingController(
      text: prescription.contactNumber,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Enables full height & keyboard avoidance
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom, // Avoid keyboard
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Title
                Text(
                  "Edit Prescription",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Update your prescription details below.",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),

                // Form Fields
                TextField(
                  controller: contactController,
                  decoration: const InputDecoration(
                    labelText: "Contact Number",
                    hintText: "Enter your phone number",
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: "Notes",
                    hintText: "Add any additional details...",
                    prefixIcon: Icon(Icons.sticky_note_2_outlined),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 32),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          try {
                            await Provider.of<PrescriptionProvider>(
                              context,
                              listen: false,
                            ).updatePrescription(
                              prescription.id,
                              notes: notesController.text,
                              contactNumber: contactController.text,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    "Details updated successfully",
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: theme.colorScheme.primary,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Failed to update: $e"),
                                  backgroundColor: theme.colorScheme.error,
                                ),
                              );
                            }
                          }
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Save Changes"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, int prescriptionId) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          icon: Icon(
            Icons.warning_amber_rounded,
            color: theme.colorScheme.error,
            size: 32,
          ),
          title: const Text("Delete Prescription?"),
          content: const Text(
            "This action cannot be undone. Are you sure you want to proceed?",
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                try {
                  await Provider.of<PrescriptionProvider>(
                    context,
                    listen: false,
                  ).deletePrescription(prescriptionId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Deleted successfully"),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to delete: $e")),
                    );
                  }
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
              ),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(String status, BuildContext context) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade700;
      case 'approved':
        return Colors.green.shade600;
      case 'rejected':
        return Theme.of(context).colorScheme.error;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.access_time_filled;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }
}
