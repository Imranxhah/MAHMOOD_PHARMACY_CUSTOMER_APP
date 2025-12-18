import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/src/providers/order_provider.dart';
import 'package:customer_app/src/constants/api_constants.dart';
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
          CircularProgressIndicator(strokeWidth: 3, color: colorScheme.primary),
          gapH16,
          Text(
            'Loading order details...',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
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
              'Unable to Load Order',
              style: theme.textTheme.titleLarge?.copyWith(
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
            gapH24,
            FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Go Back'),
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
            Icon(
              Icons.search_off_rounded,
              size: 80,
              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            gapH24,
            Text(
              'Order Not Found',
              style: theme.textTheme.titleLarge?.copyWith(
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
            gapH24,
            FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Go Back'),
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
          // Order Header Card
          Container(
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
              border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: colorScheme.primary,
                        size: 32,
                      ),
                    ),
                    gapW16,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${AppStrings.orderPrefix}${order.id}",
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          gapH4,
                          _buildStatusBadge(context, order.status),
                        ],
                      ),
                    ),
                  ],
                ),
                gapH20,
                Divider(color: colorScheme.outlineVariant),
                gapH16,
                _buildInfoRow(
                  context,
                  icon: Icons.calendar_today_rounded,
                  label: 'Ordered On',
                  value: order.createdAt.split(' ')[0],
                ),
                gapH12,
                _buildInfoRow(
                  context,
                  icon: Icons.payments_rounded,
                  label: 'Total Amount',
                  value: 'PKR ${order.totalAmount.toStringAsFixed(2)}',
                  highlight: true,
                ),
              ],
            ),
          ),

          gapH24,

          // Shipping Information
          _buildSection(
            context,
            title: 'Shipping Information',
            icon: Icons.local_shipping_rounded,
            isDark: isDark,
            child: Column(
              children: [
                _buildInfoRow(
                  context,
                  icon: Icons.location_on_rounded,
                  label: 'Address',
                  value: order.shippingAddress ?? 'N/A',
                ),
                gapH12,
                _buildInfoRow(
                  context,
                  icon: Icons.phone_rounded,
                  label: 'Contact',
                  value: order.contactNumber ?? 'N/A',
                ),
              ],
            ),
          ),

          gapH24,

          // Branch Information
          if (order.branch != null) ...[
            _buildSection(
              context,
              title: 'Fulfillment Branch',
              icon: Icons.store_mall_directory_rounded,
              isDark: isDark,
              child: Column(
                children: [
                  _buildInfoRow(
                    context,
                    icon: Icons.business_rounded,
                    label: 'Branch Name',
                    value: order.branch!.name,
                  ),
                  if (order.branch!.address != null) ...[
                    gapH12,
                    _buildInfoRow(
                      context,
                      icon: Icons.location_on_rounded,
                      label: 'Address',
                      value: order.branch!.address!,
                    ),
                  ],
                  if (order.branch!.phone != null) ...[
                    gapH12,
                    _buildInfoRow(
                      context,
                      icon: Icons.phone_rounded,
                      label: 'Phone',
                      value: order.branch!.phone!,
                    ),
                  ],
                  if (order.branch!.timing != null) ...[
                    gapH12,
                    _buildInfoRow(
                      context,
                      icon: Icons.access_time_rounded,
                      label: 'Timing',
                      value: order.branch!.timing!,
                    ),
                  ],
                ],
              ),
            ),
            gapH24,
          ],

          // Order Items
          _buildSection(
            context,
            title: 'Order Items (${order.items.length})',
            icon: Icons.inventory_2_rounded,
            isDark: isDark,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: order.items.length,
              separatorBuilder: (_, __) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: colorScheme.outlineVariant),
              ),
              itemBuilder: (context, index) {
                final item = order.items[index];
                return _buildOrderItem(context, item, isDark);
              },
            ),
          ),

          // Cancel Button for Pending Orders
          if (order.status == AppStrings.pending) ...[
            gapH32,
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _showCancelDialog(context, order.id),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel Order'),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],

          gapH32,
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
    required bool isDark,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colorScheme.primary, size: 20),
              gapW8,
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          gapH16,
          child,
        ],
      ),
    );
  }

  Widget _buildOrderItem(BuildContext context, dynamic item, bool isDark) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Image
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surfaceContainerHighest
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: item.productImage != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    "${ApiConstants.mediaBaseUrl}${item.productImage}",
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.image_not_supported_outlined,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : Icon(Icons.image_outlined, color: colorScheme.onSurfaceVariant),
        ),
        gapW12,
        // Product Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              gapH8,
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Qty: ${item.quantity}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  gapW8,
                  Text(
                    'PKR ${item.priceAtPurchase.toStringAsFixed(2)} each',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        gapW8,
        // Total Price
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'PKR ${(item.priceAtPurchase * item.quantity).toStringAsFixed(2)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            gapH4,
            Text(
              'Total',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool highlight = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: highlight ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
        gapW8,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
                  color: highlight ? colorScheme.primary : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'pending':
      case 'processing':
        bgColor = Colors.orange.withOpacity(0.15);
        textColor = Colors.orange.shade700;
        icon = Icons.pending_outlined;
        break;
      case 'cancelled':
        bgColor = colorScheme.errorContainer.withOpacity(0.5);
        textColor = colorScheme.error;
        icon = Icons.cancel_outlined;
        break;
      case 'delivered':
        bgColor = Colors.green.withOpacity(0.15);
        textColor = Colors.green.shade700;
        icon = Icons.check_circle_outline_rounded;
        break;
      default:
        bgColor = colorScheme.surfaceContainerHighest;
        textColor = colorScheme.onSurfaceVariant;
        icon = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            status,
            style: theme.textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, int orderId) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Icon(
          Icons.warning_amber_rounded,
          size: 48,
          color: colorScheme.error,
        ),
        title: const Text("Cancel Order", textAlign: TextAlign.center),
        content: const Text(
          "Are you sure you want to cancel this order? This action cannot be undone.",
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Keep Order"),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Provider.of<OrderProvider>(
                context,
                listen: false,
              ).cancelOrder(orderId);
            },
            style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
            child: const Text("Cancel Order"),
          ),
        ],
        actionsPadding: const EdgeInsets.all(16),
      ),
    );
  }
}
