import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher
import 'package:customer_app/src/providers/branch_provider.dart';
import 'package:customer_app/src/models/branch_model.dart';
import '../../../../constants/app_sizes.dart';

class BranchesScreen extends StatefulWidget {
  const BranchesScreen({super.key});

  @override
  State<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<BranchesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final branchProvider = Provider.of<BranchProvider>(
        context,
        listen: false,
      );
      branchProvider.fetchLocationAndData();
    });
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!await launchUrl(uri)) {
        throw Exception('Could not launch $url');
      }
    }
  }

  Future<void> _refresh() async {
    final branchProvider = Provider.of<BranchProvider>(context, listen: false);
    await branchProvider.fetchLocationAndData(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Our Branches")),
      body: Consumer<BranchProvider>(
        builder: (context, branchProvider, child) {
          if (branchProvider.isLocationLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (branchProvider.locationError != null) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(AppSizes.p16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      branchProvider.locationError!,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppSizes.p16),
                    ElevatedButton(
                      onPressed: () => branchProvider.fetchLocationAndData(),
                      child: const Text("Retry Location"),
                    ),
                  ],
                ),
              ),
            );
          }

          // Display branches
          final displayBranches = branchProvider.foundBranches.isNotEmpty
              ? branchProvider.foundBranches
              : branchProvider.branches;

          if (branchProvider.isLoading && displayBranches.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (branchProvider.error != null) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: Center(child: Text(branchProvider.error!)),
                ),
              ),
            );
          }

          if (displayBranches.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: const Center(child: Text("No branches found.")),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(AppSizes.p16),
              itemCount: displayBranches.length,
              separatorBuilder: (ctx, i) => SizedBox(height: AppSizes.p12),
              itemBuilder: (context, index) {
                final BranchModel branch = displayBranches[index];
                // First branch in foundBranches is considered nearest by API, or if no location, then just list all.
                final isNearest =
                    branchProvider.foundBranches.isNotEmpty && index == 0;

                return Card(
                  elevation: isNearest ? 4 : 1,
                  color: isNearest
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).cardColor,
                  child: ListTile(
                    leading: Icon(
                      Icons.location_on,
                      color: isNearest
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      branch.name,
                      style: TextStyle(
                        fontWeight: isNearest
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Lat: ${branch.latitude}, Long: ${branch.longitude}",
                        ),
                        Text("Timing: ${branch.timing}"),
                        if (branch.distanceKm != null)
                          Text(
                            "Distance: ${branch.distanceKm!.toStringAsFixed(2)} km away",
                          ),
                      ],
                    ),
                    trailing: (isNearest
                        ? Icon(
                            Icons.star,
                            color: Theme.of(context).colorScheme.tertiary,
                          )
                        : null),
                    onTap: () {
                      String url;
                      if (branchProvider.currentPosition != null) {
                        url =
                            'https://www.google.com/maps/dir/?api=1&origin=${branchProvider.currentPosition!.latitude},${branchProvider.currentPosition!.longitude}&destination=${branch.latitude},${branch.longitude}';
                      } else {
                        url =
                            'https://www.google.com/maps/dir/?api=1&destination=${branch.latitude},${branch.longitude}';
                      }
                      _launchUrl(url);
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
