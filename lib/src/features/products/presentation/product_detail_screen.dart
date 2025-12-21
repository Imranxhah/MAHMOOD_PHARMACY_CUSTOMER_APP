import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:customer_app/src/models/product_model.dart';
import 'package:customer_app/src/providers/product_provider.dart';
import 'package:customer_app/src/providers/auth_provider.dart';
import 'package:customer_app/src/features/cart/presentation/checkout_screen.dart';
import 'package:customer_app/src/providers/cart_provider.dart';
import 'package:customer_app/src/features/auth/presentation/screens/login_screen.dart';
import 'package:customer_app/src/common_widgets/product_card.dart'; // Import ProductCard
import '../../../constants/app_sizes.dart';
import '../../../constants/app_strings.dart';
import '../../../common_widgets/custom_widgets.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  late ProductModel _currentProduct;
  List<ProductModel> _relatedProducts = [];
  bool _isLoadingRelated = false;

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
    _fetchRelatedProducts();
  }

  Future<void> _fetchRelatedProducts() async {
    setState(() {
      _isLoadingRelated = true;
    });
    try {
      final products = await Provider.of<ProductProvider>(
        context,
        listen: false,
      ).fetchRelatedProducts(_currentProduct.category);
      if (mounted) {
        setState(() {
          _relatedProducts =
              products.where((p) => p.id != _currentProduct.id).toList();
        });
      }
    } catch (e) {
      // Handle error gracefully or just show empty list
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRelated = false;
        });
      }
    }
  }

  void _increment() {
    setState(() {
      _quantity++;
    });
  }

  void _decrement() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  Future<void> _toggleFavorite(ProductModel liveProduct) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );

    if (!authProvider.isAuthenticated) {
      if (!mounted) return;
      _showLoginRequiredDialog();
      return;
    }

    try {
      await productProvider.toggleFavorite(liveProduct.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            liveProduct.isFavorite
                ? 'Added to favorites'
                : 'Removed from favorites',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    } on DioException catch (e) {
      String errorMessage = 'Failed to update favorite status.';
      if (e.response?.statusCode == 401) {
        errorMessage = 'Please login to add favorites.';
        if (!mounted) return;
        _showLoginRequiredDialog();
      } else {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: $e')),
      );
    }
  }

  Future<void> _buyNow() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated) {
      if (!mounted) return;
      _showLoginRequiredDialog(message: "Please login to place an order.");
      return;
    }

    try {
      final double price = double.tryParse(_currentProduct.price) ?? 0.0;
      final double total = price * _quantity;

      final List<Map<String, dynamic>> buyNowItem = [
        {'product_id': _currentProduct.id, 'quantity': _quantity},
      ];

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CheckoutScreen(
            cartItems: buyNowItem,
            cartTotal: total,
            isBuyNow: true,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog("Buy Now Failed", "Unable to proceed to checkout: $e");
    }
  }

  void _showLoginRequiredDialog({
    String message = "Please login to add items to your favorites.",
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Login Required"),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Login"),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text("Okay"),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.details),

        // -----------------------
        actions: [
          Consumer<ProductProvider>(
            builder: (context, provider, child) {
              ProductModel? liveProduct;

              // (Logic to find live product...)
              if (provider.products.any((p) => p.id == widget.product.id)) {
                liveProduct = provider.products.firstWhere(
                  (p) => p.id == widget.product.id,
                );
              } else if (provider.favorites.any(
                (p) => p.id == widget.product.id,
              )) {
                liveProduct = provider.favorites.firstWhere(
                  (p) => p.id == widget.product.id,
                );
              } else if (provider.homeData != null) {
                for (var section in provider.homeData!.sections) {
                  if (section.products.any((p) => p.id == widget.product.id)) {
                    liveProduct = section.products.firstWhere(
                      (p) => p.id == widget.product.id,
                    );
                    break;
                  }
                }
              }
              liveProduct ??= widget.product;

              return IconButton(
                onPressed: () => _toggleFavorite(liveProduct!),
                icon: Icon(
                  liveProduct.isFavorite
                      ? Icons.favorite
                      : Icons.favorite_border,
                  // Keep the heart red if liked, otherwise use the theme's text color
                  color: liveProduct.isFavorite
                      ? const Color.fromARGB(255, 255, 255, 255)
                      : Colors.white,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Product Image Section ---
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surfaceContainerHighest.withOpacity(0.5)
                    : colorScheme.surfaceContainerLow,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
              ),
              child: Hero(
                tag: _currentProduct.id,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child:
                      _currentProduct.image != null &&
                              _currentProduct.image!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: _currentProduct.image!,
                              fit: BoxFit.contain,
                              errorWidget: (context, url, error) =>
                                  Center(
                                    child: Icon(
                                      Icons.broken_image_rounded,
                                      size: 80,
                                      color: colorScheme.outlineVariant,
                                    ),
                                  ),
                            )
                          : Center(
                              child: Icon(
                                Icons.medication_rounded,
                                size: 100,
                                color: colorScheme.primary.withOpacity(0.5),
                              ),
                            ),
                ),
              ),
            ),

            // --- Details Section ---
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _currentProduct.categoryName,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    _currentProduct.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Price and Quantity Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price and Stock
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Price",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            "PKR ${_currentProduct.price}",
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Stock Status
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _currentProduct.stock > 0
                                  ? colorScheme.primary.withOpacity(0.1)
                                  : colorScheme.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _currentProduct.stock > 0
                                  ? "In Stock: ${_currentProduct.stock}"
                                  : "Out of Stock",
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: _currentProduct.stock > 0
                                    ? colorScheme.primary
                                    : colorScheme.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Modern Capsule Quantity Selector
                      if (_currentProduct.stock > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Row(
                            children: [
                              _QuantityButton(
                                icon: Icons.remove,
                                onTap: _decrement,
                                colorScheme: colorScheme,
                              ),
                              SizedBox(
                                width: 40,
                                child: Text(
                                  "$_quantity",
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                              _QuantityButton(
                                icon: Icons.add,
                                onTap: () {
                                  if (_quantity < _currentProduct.stock) {
                                    _increment();
                                  } else {
                                    ScaffoldMessenger.of(context)
                                        .clearSnackBars();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Reached maximum stock"),
                                      ),
                                    );
                                  }
                                },
                                colorScheme: colorScheme,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  Divider(color: colorScheme.outlineVariant),
                  const SizedBox(height: 16),

                  // Description Header
                  Text(
                    AppStrings.description,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description Body
                  Text(
                    _currentProduct.description,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // --- Buttons Section ---
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 54, // Consistent height
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: _currentProduct.stock > 0
                                    ? colorScheme.primary
                                    : colorScheme.outline,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _currentProduct.stock > 0
                                ? () {
                                    Provider.of<CartProvider>(
                                      context,
                                      listen: false,
                                    ).addItem(_currentProduct, _quantity);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(AppStrings.addedToCart),
                                      ),
                                    );
                                  }
                                : null,
                            child: Text(
                              AppStrings.addToCart,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _currentProduct.stock > 0
                                    ? colorScheme.primary
                                    : colorScheme.outline,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _currentProduct.stock > 0
                                  ? colorScheme.primary
                                  : colorScheme.surfaceContainerHighest,
                              foregroundColor: _currentProduct.stock > 0
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurfaceVariant,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed:
                                _currentProduct.stock > 0 ? _buyNow : null,
                            child: const Text(
                              "Buy Now",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                                    // --- Related Products Section ---

                                    if (_relatedProducts.isNotEmpty) ...[

                                      Text(

                                        "Related Products",

                                        style: theme.textTheme.titleLarge?.copyWith(

                                          fontWeight: FontWeight.bold,

                                        ),

                                      ),

                                      const SizedBox(height: 16),

                                      GridView.builder(

                                        shrinkWrap: true, // Important for nested scroll views

                                        physics: const NeverScrollableScrollPhysics(), // Disable GridView's own scrolling

                                        padding: EdgeInsets.zero, // Padding will be handled by the main Padding

                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(

                                          crossAxisCount: 2, // Two columns

                                          crossAxisSpacing: 16, // Spacing between columns

                                          mainAxisSpacing: 16, // Spacing between rows

                                          childAspectRatio: 0.65, // Adjust as needed to maintain aspect ratio for cards

                                        ),

                                        itemCount: _relatedProducts.length,

                                        itemBuilder: (context, index) {

                                          return ProductCard(

                                            product: _relatedProducts[index],

                                            onTap: () {

                                              Navigator.push(

                                                context,

                                                MaterialPageRoute(

                                                  builder: (context) => ProductDetailScreen(

                                                    product: _relatedProducts[index],

                                                  ),

                                                ),

                                              );

                                            },

                                          );

                                        },

                                      ),

                                      const SizedBox(height: 24),

                                    ] else if (_isLoadingRelated) ...[

                                      const Center(child: CircularProgressIndicator()),

                                      const SizedBox(height: 24),

                                    ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper widget for cleaner code in the Quantity Selector
class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _QuantityButton({
    required this.icon,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.surface,
          ),
          child: Icon(icon, size: 20, color: colorScheme.onSurface),
        ),
      ),
    );
  }
}
