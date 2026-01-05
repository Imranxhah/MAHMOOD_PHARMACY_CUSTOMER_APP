import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:customer_app/src/providers/order_provider.dart';
import 'package:customer_app/src/constants/api_constants.dart';
import 'package:order_tracker_zen/order_tracker_zen.dart';
import '../../../constants/app_sizes.dart';
import '../../../constants/app_strings.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(
        context,
        listen: false,
      ).getOrderDetail(widget.orderId);
    });
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
          'Order Details',
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
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          if (orderProvider.isLoading) {
            return _buildLoadingState(context);
          }

          if (orderProvider.error != null) {
            return _buildErrorState(context, orderProvider.error!);
          }

          final order = orderProvider.selectedOrder;

          if (order == null) {
            return _buildNotFoundState(context);
          }

          return _buildOrderDetail(context, order, isDark);
        },
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              strokeWidth: 3.5,
              color: colorScheme.primary,
            ),
          ),
          gapH24,
          Text(
            'Loading order details...',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.errorContainer.withOpacity(0.4),
                    colorScheme.errorContainer.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 72,
                color: colorScheme.error,
              ),
            ),
            gapH24,
            Text(
              'Unable to Load Order',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            gapH12,
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            gapH32,
            FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Go Back'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 72,
                color: colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
            gapH24,
            Text(
              'Order Not Found',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            gapH12,
            Text(
              'We couldn\'t find this order.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            gapH32,
            FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Go Back'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetail(BuildContext context, dynamic order, bool isDark) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Premium Order Header Card
          _buildHeaderCard(context, order, isDark),
          gapH24,

          // Order Tracker
          if (order.status.toLowerCase() != 'cancelled') ...[
            _buildTrackerCard(context, order, isDark),
            gapH24,
          ],

          // Shipping Info
          _buildShippingCard(context, order, isDark),
          gapH20,

          // Branch Info
          if (order.branch != null) ...[
            _buildBranchCard(context, order, isDark),
            gapH20,
          ],

          // Order Items
          _buildItemsCard(context, order, isDark),

          // Action Buttons
          if (order.status == AppStrings.pending) ...[
            gapH24,
            _buildCancelButton(context, order.id, colorScheme),
          ] else if (order.status == AppStrings.cancelled) ...[
            gapH24,
            _buildDeleteButton(context, order.id, colorScheme),
          ],

          gapH32,
        ],
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, dynamic order, bool isDark) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Solid background colors based on mode for the main card
    final Color cardBackground = isDark
        ? colorScheme.surfaceContainer
        : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          // Very subtle border for structure
          color: isDark
              ? colorScheme.outline.withOpacity(0.2)
              : colorScheme.outlineVariant.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          // Soft, diffused shadow for elevation
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSizes.p24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Order ID and Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order ID',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "#${order.id}",
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface, // Solid text color
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Your previously styled badge (ensure you pass correct context/status)
              _buildModernStatusBadge(context, order.status, isDark),
            ],
          ),

          const SizedBox(height: 24),

          // Separator
          Divider(
            height: 1,
            thickness: 1,
            color: colorScheme.outlineVariant.withOpacity(0.5),
          ),

          const SizedBox(height: 24),

          // Bottom Row: Date and Amount Cards
          Row(
            children: [
              Expanded(child: _buildDateCard(context, order, isDark)),
              const SizedBox(width: 12), // Use SizedBox or gapW12
              Expanded(child: _buildAmountCard(context, order, isDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard(BuildContext context, dynamic order, bool isDark) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Use a slightly different surface tone for the inner cards
    final Color backgroundColor = isDark
        ? colorScheme.surfaceContainerHigh
        : colorScheme.surfaceContainerLow;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor, // Solid color fill
        borderRadius: BorderRadius.circular(16),
        // No border needed if the background contrast is good,
        // but a subtle one adds crispness
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_month_rounded, // Updated icon
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Order Date',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order.createdAt.toString().split(' ')[0],
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard(BuildContext context, dynamic order, bool isDark) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // For the Amount card, we make it "Primary" tinted to highlight importance
    // but keep it solid enough to read easily.
    final Color backgroundColor = isDark
        ? colorScheme.primaryContainer.withOpacity(
            0.2,
          ) // Dark mode needs transparency
        : colorScheme.primaryContainer; // Solid tint for Light mode

    final Color contentColor = isDark
        ? colorScheme
              .primaryFixedDim // Brighter for dark mode
        : colorScheme.onPrimaryContainer; // Darker for light mode

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        // Optional: Remove border if background color is distinct enough
        border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.wallet_rounded, // Updated icon
                size: 18,
                color: contentColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Total',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: contentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'PKR ${order.totalAmount.toStringAsFixed(0)}', // Removed decimal for cleaner look
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: contentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackerCard(BuildContext context, dynamic order, bool isDark) {
    final theme = Theme.of(context);

    // Modern color palette that works in both light and dark mode
    final cardBackground = isDark
        ? const Color(0xFF1E1E2E)
        : const Color(0xFFFAFAFC);
    final cardBorder = isDark
        ? const Color(0xFF2D2D44)
        : const Color(0xFFE8E8F0);

    // Vibrant accent colors
    final primaryGradient = isDark
        ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
        : [const Color(0xFF6366F1), const Color(0xFF7C3AED)];

    final iconBackground = isDark
        ? const Color(0xFF2D2D44)
        : const Color(0xFFF3F4FF);

    final iconColor = isDark
        ? const Color(0xFF818CF8)
        : const Color(0xFF6366F1);

    final textPrimary = isDark
        ? const Color(0xFFE5E5F0)
        : const Color(0xFF1E1E2E);
    final textSecondary = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF64748B);

    // Status colors for tracker
    final successColor = isDark
        ? const Color(0xFF10B981)
        : const Color(0xFF059669);
    final trackerBackground = isDark
        ? const Color(0xFF252535)
        : const Color(0xFFF8F9FB);

    return Container(
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : const Color(0xFF6366F1).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSizes.p20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient accent
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryGradient[0].withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Tracking',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Track your shipment status',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Live',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          gapH20,

          // Tracker section with colored background
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: trackerBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF2D2D44)
                    : const Color(0xFFE8E8F0),
                width: 1,
              ),
            ),
            child: OrderTrackerZen(
              success_color: successColor,
              background_color: Colors.transparent,
              screen_background_color: Colors.transparent,
              text_primary_color: textPrimary,
              text_secondary_color: textSecondary,
              tracker_data: [
                TrackerData(
                  title: "Order Placed",
                  date: order.createdAt.split(' ')[0],
                  tracker_details: [
                    TrackerDetails(
                      title: "Your order has been confirmed",
                      datetime: order.createdAt,
                    ),
                  ],
                ),
                if ([
                  'shipped',
                  'delivered',
                ].contains(order.status.toLowerCase()))
                  TrackerData(
                    title: "Out for Delivery",
                    date: "In Transit",
                    tracker_details: [
                      TrackerDetails(
                        title: "Package is on its way",
                        datetime: "En route to destination",
                      ),
                    ],
                  ),
                if (order.status.toLowerCase() == 'delivered')
                  TrackerData(
                    title: "Delivered",
                    date: "Completed",
                    tracker_details: [
                      TrackerDetails(
                        title: "Successfully delivered",
                        datetime: "Thank you for shopping with us!",
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingCard(BuildContext context, dynamic order, bool isDark) {
    return _buildModernInfoCard(
      context,
      title: 'Delivery Address',
      icon: Icons.location_on_rounded,
      iconGradient: [Colors.red.withOpacity(0.2), Colors.red.withOpacity(0.1)],
      iconColor: Colors.red.shade600,
      isDark: isDark,
      child: Column(
        children: [
          _buildModernInfoRow(
            context,
            icon: Icons.pin_drop_rounded,
            label: 'Address',
            value: order.shippingAddress ?? 'N/A',
            isDark: isDark,
          ),
          gapH16,
          _buildModernInfoRow(
            context,
            icon: Icons.phone_rounded,
            label: 'Contact Number',
            value: order.contactNumber ?? 'N/A',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildBranchCard(BuildContext context, dynamic order, bool isDark) {
    return _buildModernInfoCard(
      context,
      title: 'Fulfillment Branch',
      icon: Icons.store_rounded,
      iconGradient: [
        Colors.blue.withOpacity(0.2),
        Colors.blue.withOpacity(0.1),
      ],
      iconColor: Colors.blue.shade600,
      isDark: isDark,
      child: Column(
        children: [
          _buildModernInfoRow(
            context,
            icon: Icons.business_rounded,
            label: 'Branch Name',
            value: order.branch!.name,
            isDark: isDark,
          ),
          if (order.branch!.address != null) ...[
            gapH16,
            _buildModernInfoRow(
              context,
              icon: Icons.location_on_outlined,
              label: 'Address',
              value: order.branch!.address!,
              isDark: isDark,
            ),
          ],
          if (order.branch!.phone != null) ...[
            gapH16,
            _buildModernInfoRow(
              context,
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: order.branch!.phone!,
              isDark: isDark,
            ),
          ],
          if (order.branch!.timing != null) ...[
            gapH16,
            _buildModernInfoRow(
              context,
              icon: Icons.access_time_rounded,
              label: 'Operating Hours',
              value: order.branch!.timing!,
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsCard(BuildContext context, dynamic order, bool isDark) {
    final theme = Theme.of(context);

    return _buildModernInfoCard(
      context,
      title: 'Order Items',
      subtitle:
          '${order.items.length} ${order.items.length == 1 ? 'item' : 'items'}',
      icon: Icons.shopping_bag_rounded,
      iconGradient: [
        Colors.purple.withOpacity(0.2),
        Colors.purple.withOpacity(0.1),
      ],
      iconColor: Colors.purple.shade600,
      isDark: isDark,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: order.items.length,
        separatorBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Divider(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withOpacity(0.5),
            height: 1,
          ),
        ),
        itemBuilder: (context, index) {
          final item = order.items[index];
          return _buildModernOrderItem(context, item, isDark);
        },
      ),
    );
  }

  Widget _buildModernInfoCard(
    BuildContext context, {
    required String title,
    String? subtitle,
    required IconData icon,
    required List<Color> iconGradient,
    required Color iconColor,
    required Widget child,
    required bool isDark,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSizes.p20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: iconGradient),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              gapW12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          gapH20,
          child,
        ],
      ),
    );
  }

  Widget _buildModernInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surface.withOpacity(0.5)
            : colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: colorScheme.primary),
          ),
          gapW12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernOrderItem(
    BuildContext context,
    dynamic item,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String imageUrl = item.productImage ?? "";
    if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      imageUrl = "${ApiConstants.mediaBaseUrl}$imageUrl";
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surface.withOpacity(0.3)
            : colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surfaceContainer
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outlineVariant.withOpacity(0.5),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: item.productImage != null && imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Icon(
                        Icons.image_not_supported_outlined,
                        color: colorScheme.onSurfaceVariant,
                        size: 28,
                      ),
                    )
                  : Icon(
                      Icons.inventory_2_outlined,
                      color: colorScheme.onSurfaceVariant,
                      size: 28,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.productName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary.withOpacity(0.2),
                            colorScheme.primary.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        'Qty: ${item.quantity}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Text(
                      ' PKR ${item.priceAtPurchase.toStringAsFixed(2)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Total Price
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withOpacity(0.2),
                  colorScheme.primary.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'PKR',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  (item.priceAtPurchase * item.quantity).toStringAsFixed(0),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatusBadge(
    BuildContext context,
    String status,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    // Variables for the solid look
    Color backgroundColor;
    Color contentColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'pending':
      case 'processing':
        // Amber/Orange: Warmth for waiting
        backgroundColor = isDark
            ? Colors.orange.shade900
            : Colors.orange.shade100;
        contentColor = isDark ? Colors.orange.shade100 : Colors.orange.shade900;
        icon = Icons.hourglass_top_rounded; // More modern than 'pending'
        break;

      case 'cancelled':
        // Red: Alert/Stop
        backgroundColor = isDark
            ? const Color(0xFF450a0a)
            : Colors.red.shade100;
        contentColor = isDark ? Colors.red.shade100 : Colors.red.shade900;
        icon = Icons.close_rounded;
        break;

      case 'delivered':
        // Green: Success/Go
        backgroundColor = isDark
            ? const Color(0xFF052e16)
            : Colors.green.shade100;
        contentColor = isDark ? Colors.green.shade100 : Colors.green.shade900;
        icon = Icons.check_circle_rounded;
        break;

      case 'shipped':
      case 'out for delivery':
        // Indigo/Blue: Professional/Transit
        backgroundColor = isDark
            ? Colors.indigo.shade900
            : Colors.indigo.shade100;
        contentColor = isDark ? Colors.indigo.shade100 : Colors.indigo.shade900;
        icon = Icons.local_shipping_rounded;
        break;

      default:
        // Grey/Neutral
        backgroundColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
        contentColor = isDark ? Colors.grey.shade300 : Colors.grey.shade800;
        icon = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        // Pill shape is trendier than standard rounded corners
        borderRadius: BorderRadius.circular(30),
        // Subtle border for Dark Mode definition, clean for Light Mode
        border: isDark
            ? Border.all(color: contentColor.withOpacity(0.2), width: 1)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: contentColor),
          const SizedBox(width: 8),
          Text(
            status.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: contentColor,
              fontWeight: FontWeight.w700, // Thicker text for "Solid" feel
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton(
    BuildContext context,
    int orderId,
    ColorScheme colorScheme,
  ) {
    return Center(
      // 1. Prevents the button from taking full width
      child: Container(
        height: 50, // 2. Fixed professional height
        width: 500, // 3. Set a specific width (or remove for content-hugging)
        decoration: BoxDecoration(
          // The Gradient
          gradient: LinearGradient(
            colors: [colorScheme.error, colorScheme.error.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25), // Matches StadiumBorder
          // Softer, more modern shadow
          boxShadow: [
            BoxShadow(
              color: colorScheme.error.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: FilledButton(
          onPressed: () => _showCancelDialog(context, orderId),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent, // Transparent to show gradient
            shadowColor: Colors.transparent, // Remove built-in button shadow
            shape: const StadiumBorder(), // "Pill" shape
            padding: EdgeInsets.zero, // Remove padding to center text perfectly
          ),
          child: const Text(
            'Cancel Order',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5, // Makes caps looking text cleaner
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(
    BuildContext context,
    int orderId,
    ColorScheme colorScheme,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.error, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: FilledButton.icon(
        onPressed: () => _confirmDeleteOrder(context, orderId),
        icon: const Icon(Icons.delete_outline_rounded),
        label: const Text('Delete Order'),
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.errorContainer,
          foregroundColor: colorScheme.error,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, int orderId) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.errorContainer.withOpacity(0.6),
                colorScheme.errorContainer.withOpacity(0.3),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.warning_amber_rounded,
            size: 48,
            color: colorScheme.error,
          ),
        ),
        title: Text(
          "Cancel Order",
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "Are you sure you want to cancel this order? This action cannot be undone.",
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: theme.brightness == Brightness.dark
                        ? colorScheme.surfaceContainerHighest
                        : Colors.grey[200],
                    foregroundColor: colorScheme.onSurface,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Keep Order",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Provider.of<OrderProvider>(
                      context,
                      listen: false,
                    ).cancelOrder(orderId);
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Cancel Order",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      ),
    );
  }

  void _confirmDeleteOrder(BuildContext context, int orderId) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.errorContainer.withOpacity(0.6),
                colorScheme.errorContainer.withOpacity(0.3),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.delete_forever_rounded,
            size: 48,
            color: colorScheme.error,
          ),
        ),
        title: Text(
          "Delete Order",
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "Are you sure you want to permanently delete this cancelled order? This action cannot be undone.",
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = Provider.of<OrderProvider>(
                context,
                listen: false,
              );
              await provider.deleteOrder(orderId);
              if (context.mounted && provider.error == null) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Order deleted successfully"),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else if (context.mounted && provider.error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(provider.error!),
                    backgroundColor: colorScheme.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Delete"),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      ),
    );
  }
}
