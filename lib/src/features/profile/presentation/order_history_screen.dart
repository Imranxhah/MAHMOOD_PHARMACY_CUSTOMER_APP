import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/src/providers/order_provider.dart';
import 'package:customer_app/src/features/profile/presentation/order_detail_screen.dart';
import '../../../constants/app_sizes.dart';
import '../../../constants/app_strings.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false).listOrders();
    });
  }

  Future<void> _refresh() async {
    await Provider.of<OrderProvider>(
      context,
      listen: false,
    ).listOrders(forceRefresh: true);
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
          AppStrings.orderHistory,
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
          // Loading State
          if (orderProvider.isLoading && orderProvider.orders.isEmpty) {
            return _buildLoadingState(context);
          }

          // Error State
          if (orderProvider.error != null && orderProvider.orders.isEmpty) {
            return _buildErrorState(context, orderProvider);
          }

          // Empty State
          if (orderProvider.orders.isEmpty) {
            return _buildEmptyState(context);
          }

          // Success State
          return RefreshIndicator(
            onRefresh: _refresh,
            color: colorScheme.primary,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSizes.p16),
              itemCount: orderProvider.orders.length,
              separatorBuilder: (_, __) => gapH12,
              itemBuilder: (context, index) {
                final order = orderProvider.orders[index];
                return _buildOrderCard(context, order, isDark);
              },
            ),
          );
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
            'Loading your orders...',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, OrderProvider provider) {
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
                      'Unable to Load Orders',
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
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        size: 80,
                        color: colorScheme.primary,
                      ),
                    ),
                    gapH24,
                    Text(
                      'No Orders Yet',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    gapH12,
                    Text(
                      'Start shopping to see your orders here',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    gapH32,
                    FilledButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.shopping_cart_outlined),
                      label: const Text('Start Shopping'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
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

  Widget _buildOrderCard(BuildContext context, dynamic order, bool isDark) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderDetailScreen(orderId: order.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    gapW12,
                    Expanded(
                      child: Text(
                        "${AppStrings.orderPrefix}${order.id}",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildStatusBadge(context, order.status),
                    if (order.status == AppStrings.cancelled) ...[
                      gapW8, // Add some space
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert,
                            color: colorScheme.onSurfaceVariant),
                        onSelected: (value) {
                          if (value == 'delete') {
                            _confirmDeleteOrder(context, order.id);
                          }
                        },
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded,
                                    size: 20, color: colorScheme.error),
                                gapW12,
                                Text('Delete Order',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                        color: colorScheme.error)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                gapH16,
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    gapW8,
                    Text(
                      order.createdAt.split(' ')[0],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (order.items.isNotEmpty) ...[
                  gapH12,
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? colorScheme.surface.withOpacity(0.5)
                          : colorScheme.surfaceContainerHighest.withOpacity(
                              0.3,
                            ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        gapW8,
                        Expanded(
                          child: Text(
                            order.items
                                .map((e) => "${e.quantity}x ${e.productName}")
                                .join(", "),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                gapH16,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${order.items.length}${AppStrings.itemsSuffix}",
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      "\$${order.totalAmount.toStringAsFixed(2)}",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                if (order.status == AppStrings.pending) ...[
                  gapH16,
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showCancelDialog(context, order.id),
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('Cancel Order'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        side: BorderSide(color: colorScheme.error),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
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

  void _confirmDeleteOrder(BuildContext context, int orderId) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Icon(
          Icons.delete_forever_rounded,
          size: 48,
          color: colorScheme.error,
        ),
        title: const Text("Delete Order", textAlign: TextAlign.center),
        content: const Text(
          "Are you sure you want to permanently delete this cancelled order? This action cannot be undone.",
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Provider.of<OrderProvider>(context, listen: false)
                  .deleteOrder(orderId);
            },
            style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
            child: const Text("Delete Permanently"),
          ),
        ],
        actionsPadding: const EdgeInsets.all(16),
      ),
    );
  }
}
