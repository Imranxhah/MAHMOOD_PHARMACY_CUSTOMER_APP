import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open maps'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _refresh() async {
    final branchProvider = Provider.of<BranchProvider>(context, listen: false);
    await branchProvider.fetchLocationAndData(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Our Branches',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? colorScheme.onSurface : Colors.white,
          ),
        ),
        backgroundColor: isDark ? colorScheme.surface : colorScheme.primary,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? colorScheme.onSurface : Colors.white,
        ),
      ),
      body: Consumer<BranchProvider>(
        builder: (context, branchProvider, child) {
          // Location Loading
          if (branchProvider.isLocationLoading) {
            return _buildLocationLoadingState(context);
          }

          // Location Error
          if (branchProvider.locationError != null) {
            return _buildLocationErrorState(context, branchProvider);
          }

          final displayBranches = branchProvider.foundBranches.isNotEmpty
              ? branchProvider.foundBranches
              : branchProvider.branches;

          // Data Loading
          if (branchProvider.isLoading && displayBranches.isEmpty) {
            return _buildDataLoadingState(context);
          }

          // Data Error
          if (branchProvider.error != null) {
            return _buildDataErrorState(context, branchProvider);
          }

          // Empty State
          if (displayBranches.isEmpty) {
            return _buildEmptyState(context);
          }

          // Success State
          return _buildBranchesList(
            context,
            branchProvider,
            displayBranches,
            isDark,
          );
        },
      ),
    );
  }

  // ============================================
  // Loading States
  // ============================================
  Widget _buildLocationLoadingState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.my_location_rounded,
              size: 48,
              color: colorScheme.primary,
            ),
          ),
          gapH24,
          CircularProgressIndicator(strokeWidth: 3, color: colorScheme.primary),
          gapH16,
          Text(
            'Getting your location...',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          gapH8,
          Text(
            'Finding branches near you',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataLoadingState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(strokeWidth: 3, color: colorScheme.primary),
          gapH16,
          Text(
            'Loading branches...',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // Error States
  // ============================================
  Widget _buildLocationErrorState(
    BuildContext context,
    BranchProvider provider,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_off_rounded,
                size: 64,
                color: colorScheme.error,
              ),
            ),
            gapH24,
            Text(
              'Location Access Required',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            gapH12,
            Text(
              provider.locationError!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            gapH32,
            FilledButton.icon(
              onPressed: () => provider.fetchLocationAndData(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Enable Location'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            gapH12,
            TextButton(
              onPressed: () async {
                await Geolocator.openLocationSettings();
              },
              child: const Text('Open Location Settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataErrorState(BuildContext context, BranchProvider provider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return RefreshIndicator(
      onRefresh: _refresh,
      color: colorScheme.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: 64,
                        color: colorScheme.error,
                      ),
                    ),
                    gapH24,
                    Text(
                      'Unable to Load Branches',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    gapH12,
                    Text(
                      provider.error!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    gapH24,
                    Text(
                      'Pull down to refresh',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // Empty State
  // ============================================
  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return RefreshIndicator(
      onRefresh: _refresh,
      color: colorScheme.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.store_rounded,
                      size: 80,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                    gapH24,
                    Text(
                      'No Branches Found',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    gapH12,
                    Text(
                      'We couldn\'t find any branches at the moment.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    gapH24,
                    Text(
                      'Pull down to refresh',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // Branches List
  // ============================================
  Widget _buildBranchesList(
    BuildContext context,
    BranchProvider branchProvider,
    List<BranchModel> branches,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasLocation = branchProvider.currentPosition != null;

    return RefreshIndicator(
      onRefresh: _refresh,
      color: colorScheme.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Header Section
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(AppSizes.p16),
              padding: const EdgeInsets.all(AppSizes.p20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          colorScheme.primaryContainer,
                          colorScheme.primaryContainer.withOpacity(0.6),
                        ]
                      : [
                          colorScheme.primary.withOpacity(0.1),
                          colorScheme.primary.withOpacity(0.05),
                        ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.store_rounded,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      gapW16,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${branches.length} ${branches.length == 1 ? 'Branch' : 'Branches'} Found',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (hasLocation) ...[
                              gapH4,
                              Row(
                                children: [
                                  Icon(
                                    Icons.my_location_rounded,
                                    size: 14,
                                    color: colorScheme.primary,
                                  ),
                                  gapW4,
                                  Text(
                                    'Sorted by distance',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
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
                ],
              ),
            ),
          ),

          // Branches List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final branch = branches[index];
                final isNearest =
                    branchProvider.foundBranches.isNotEmpty && index == 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.p12),
                  child: _buildBranchCard(
                    context,
                    branch,
                    branchProvider,
                    isNearest,
                    isDark,
                  ),
                );
              }, childCount: branches.length),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  // ============================================
  // Branch Card
  // ============================================
  Widget _buildBranchCard(
    BuildContext context,
    BranchModel branch,
    BranchProvider branchProvider,
    bool isNearest,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: isNearest
            ? (isDark
                  ? colorScheme.primaryContainer.withOpacity(0.3)
                  : colorScheme.primaryContainer.withOpacity(0.5))
            : (isDark ? colorScheme.surfaceContainerHighest : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNearest
              ? colorScheme.primary.withOpacity(0.5)
              : colorScheme.outlineVariant.withOpacity(0.5),
          width: isNearest ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isNearest
                ? colorScheme.primary.withOpacity(0.15)
                : Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: isNearest ? 12 : 6,
            offset: Offset(0, isNearest ? 6 : 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openInMaps(branch, branchProvider),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isNearest
                            ? colorScheme.primary
                            : colorScheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: isNearest ? Colors.white : colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    gapW12,
                    // Branch Name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            branch.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isNearest) ...[
                            gapH4,
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  gapW4,
                                  Text(
                                    'Nearest',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Direction Icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.directions_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ),
                  ],
                ),

                gapH16,

                // Details
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? colorScheme.surface.withOpacity(0.5)
                        : colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Timing
                      _buildInfoRow(
                        context,
                        icon: Icons.access_time_rounded,
                        label: 'Timing',
                        value: branch.timing,
                        isDark: isDark,
                      ),

                      // Distance (if available)
                      if (branch.distanceKm != null) ...[
                        gapH8,
                        Divider(
                          height: 1,
                          color: colorScheme.outlineVariant.withOpacity(0.5),
                        ),
                        gapH8,
                        _buildInfoRow(
                          context,
                          icon: Icons.route_rounded,
                          label: 'Distance',
                          value:
                              '${branch.distanceKm!.toStringAsFixed(2)} km away',
                          isDark: isDark,
                          highlight: isNearest,
                        ),
                      ],
                    ],
                  ),
                ),

                gapH12,

                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _openInMaps(branch, branchProvider),
                    icon: Icon(Icons.map_rounded, size: 18),
                    label: const Text('Get Directions'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      side: BorderSide(color: colorScheme.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    bool highlight = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: highlight ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
        gapW8,
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
              color: highlight ? colorScheme.primary : null,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ============================================
  // Helper Methods
  // ============================================
  void _openInMaps(BranchModel branch, BranchProvider provider) {
    String url;
    if (provider.currentPosition != null) {
      url =
          'https://www.google.com/maps/dir/?api=1&origin='
          '${provider.currentPosition!.latitude},'
          '${provider.currentPosition!.longitude}&destination='
          '${branch.latitude},${branch.longitude}';
    } else {
      url =
          'https://www.google.com/maps/dir/?api=1&destination='
          '${branch.latitude},${branch.longitude}';
    }
    _launchUrl(url);
  }
}
