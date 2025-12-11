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
  Position? _currentPosition;
  bool _isLocationLoading = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _getLocationAndBranches();
  }

  Future<void> _getLocationAndBranches() async {
    setState(() {
      _isLocationLoading = true;
      _locationError = null;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Location permissions are denied.");
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception("Location permissions are permanently denied, we cannot request permissions.");
      }

      _currentPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      if (!mounted) return;
      final branchProvider = Provider.of<BranchProvider>(context, listen: false);
      
      // Call both list and find nearest
      await branchProvider.listBranches(); // Fetch all branches
      
      if (_currentPosition != null) {
        await branchProvider.findNearestBranch( // This will populate _foundBranches
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = e.toString();
      });
    } finally {
      setState(() {
        _isLocationLoading = false;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Our Branches"),
      ),
      body: Consumer<BranchProvider>(
        builder: (context, branchProvider, child) {
          if (_isLocationLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_locationError != null) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(AppSizes.p16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_locationError!, textAlign: TextAlign.center),
                    SizedBox(height: AppSizes.p16),
                    ElevatedButton(
                      onPressed: _getLocationAndBranches,
                      child: const Text("Retry Location"),
                    ),
                  ],
                ),
              ),
            );
          }

          // Display branches
          final displayBranches = branchProvider.foundBranches.isNotEmpty ? branchProvider.foundBranches : branchProvider.branches;

          if (branchProvider.isLoading && displayBranches.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (branchProvider.error != null) {
            return Center(child: Text(branchProvider.error!));
          }

          if (displayBranches.isEmpty) {
            return const Center(child: Text("No branches found."));
          }

          return ListView.separated(
            padding: EdgeInsets.all(AppSizes.p16),
            itemCount: displayBranches.length,
            separatorBuilder: (ctx, i) => SizedBox(height: AppSizes.p12),
            itemBuilder: (context, index) {
              final BranchModel branch = displayBranches[index];
              // First branch in foundBranches is considered nearest by API, or if no location, then just list all.
              final isNearest = branchProvider.foundBranches.isNotEmpty && index == 0; 
              
              return Card(
                elevation: isNearest ? 4 : 1,
                color: isNearest ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).cardColor,
                child: ListTile(
                  leading: Icon(Icons.location_on, color: isNearest ? Theme.of(context).colorScheme.onPrimaryContainer : Theme.of(context).colorScheme.primary),
                  title: Text(
                    branch.name,
                    style: TextStyle(fontWeight: isNearest ? FontWeight.bold : FontWeight.normal),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Lat: ${branch.latitude}, Long: ${branch.longitude}"),
                      Text("Timing: ${branch.timing}"),
                      if (branch.distanceKm != null)
                        Text("Distance: ${branch.distanceKm!.toStringAsFixed(2)} km away"),
                    ],
                  ),
                  trailing: (isNearest ? Icon(Icons.star, color: Theme.of(context).colorScheme.tertiary) : null),
                  onTap: () {
                    if (branch.googleMapsUrl != null) {
                      _launchUrl(branch.googleMapsUrl!);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Google Maps URL not available for this branch.")),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
