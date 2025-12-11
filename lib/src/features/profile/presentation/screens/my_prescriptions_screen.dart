import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/src/providers/prescription_provider.dart';
import 'package:customer_app/src/models/prescription_model.dart';
import '../../../../constants/app_sizes.dart';
import 'upload_prescription_screen.dart'; // Import UploadPrescriptionScreen

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
      Provider.of<PrescriptionProvider>(context, listen: false).listPrescriptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Prescriptions"),
      ),
      body: Consumer<PrescriptionProvider>(
        builder: (context, prescriptionProvider, child) {
          if (prescriptionProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (prescriptionProvider.error != null) {
            return Center(child: Text(prescriptionProvider.error!));
          }

          if (prescriptionProvider.prescriptions.isEmpty) {
            return const Center(child: Text("No prescriptions uploaded yet."));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSizes.p16),
            itemCount: prescriptionProvider.prescriptions.length,
            separatorBuilder: (ctx, i) => SizedBox(height: AppSizes.p16),
            itemBuilder: (context, index) {
              final PrescriptionModel prescription = prescriptionProvider.prescriptions[index];
              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radius12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(AppSizes.p16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      prescription.imageUrl.isNotEmpty
                          ? Image.network(
                              prescription.imageUrl,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 150,
                                color: Theme.of(context).colorScheme.errorContainer,
                                child: Center(
                                  child: Icon(Icons.broken_image, color: Theme.of(context).colorScheme.onErrorContainer),
                                ),
                              ),
                            )
                          : Container(
                              height: 150,
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: Icon(Icons.receipt_long, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ),
                            ),
                      SizedBox(height: AppSizes.p12),

                      // Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Status:", style: Theme.of(context).textTheme.titleSmall),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: AppSizes.p8, vertical: AppSizes.p4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(prescription.status, context).withAlpha((255 * 0.2).round()),
                              borderRadius: BorderRadius.circular(AppSizes.radius8),
                            ),
                            child: Text(
                              prescription.status,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: _getStatusColor(prescription.status, context),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSizes.p8),

                      // Upload Date
                      Text(
                        "Uploaded on: ${prescription.createdAt.toLocal().toString().split(' ')[0]}",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      SizedBox(height: AppSizes.p8),

                      // Notes
                      if (prescription.notes != null && prescription.notes!.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Your Notes:", style: Theme.of(context).textTheme.titleSmall),
                            Text(prescription.notes!),
                            SizedBox(height: AppSizes.p8),
                          ],
                        ),

                      // Admin Feedback
                      if (prescription.adminFeedback != null && prescription.adminFeedback!.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Admin Feedback:", style: Theme.of(context).textTheme.titleSmall),
                            Text(
                              prescription.adminFeedback!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UploadPrescriptionScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getStatusColor(String status, BuildContext context) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }
}
