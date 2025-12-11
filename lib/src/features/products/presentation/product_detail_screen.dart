import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:customer_app/src/models/product_model.dart';
import 'package:customer_app/src/providers/product_provider.dart';
import 'package:customer_app/src/providers/auth_provider.dart';
import 'package:customer_app/src/providers/cart_provider.dart'; // Import CartProvider
import 'package:customer_app/src/providers/order_provider.dart'; // Import OrderProvider
import 'package:customer_app/src/features/auth/presentation/screens/login_screen.dart';
import '../../../constants/app_sizes.dart';
import '../../../constants/app_strings.dart';
import '../../../common_widgets/primary_button.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  late ProductModel _currentProduct;

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
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

  Future<void> _toggleFavorite() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    if (!authProvider.isAuthenticated) {
      if (!mounted) return;
      _showLoginRequiredDialog();
      return;
    }

    try {
      await productProvider.toggleFavorite(_currentProduct.id);
      if (!mounted) return;
      setState(() {
        _currentProduct.isFavorite = !_currentProduct.isFavorite; // Update UI immediately
      });
      // Optionally, show a snackbar
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_currentProduct.isFavorite ? 'Added to favorites' : 'Removed from favorites'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: $e')),
      );
    }
  }

  Future<void> _quickOrder() async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated) {
      if (!mounted) return;
      _showLoginRequiredDialog();
      return;
    }

    try {
      // For quick order, we'll use a placeholder address and contact number
      // In a real app, you might fetch user's default address or prompt them.
      await orderProvider.quickOrder(
        productId: _currentProduct.id,
        quantity: _quantity,
        shippingAddress: "Default Quick Order Address", // Placeholder
        contactNumber: "00000000000", // Placeholder
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Quick Order Placed Successfully!")),
      );
      // Navigate to order details or home screen
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on DioException catch (e) {
      String errorMessage = e.response?.data['error'] ?? 'Failed to place quick order.';
      if (!mounted) return;
      _showErrorDialog("Quick Order Failed", errorMessage);
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog("Quick Order Failed", e.toString());
    }
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Login Required"),
          content: const Text("Please login to add items to your favorites."),
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
                  MaterialPageRoute(builder: (context) => const LoginScreen()), // Redirect to Login
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
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.details),
        actions: [
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(
              _currentProduct.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _currentProduct.isFavorite ? Colors.red : null,
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.share)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  Container(
                    height: 250,
                    width: double.infinity,
                    color: Theme.of(context).cardColor,
                    child: _currentProduct.image != null && _currentProduct.image!.isNotEmpty
                        ? Image.network(
                            _currentProduct.image!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 100,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.medication,
                              size: 100,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(AppSizes.p24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentProduct.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Category: ${_currentProduct.categoryName}", // Assuming category name is sufficient
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "\$ ${_currentProduct.price}",
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radius8,
                                ),
                                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 18),
                                    onPressed: _decrement,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  Text(
                                    "$_quantity",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 18),
                                    onPressed: _increment,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          AppStrings.description,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentProduct.description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                height: 1.5,
                              ),
                        ),
                        const SizedBox(height: 24),
                        // Related products would go here
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSizes.p16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row( // Changed to Row to include Buy Now button
              children: [
                Expanded(
                  child: PrimaryButton(
                    text: AppStrings.addToCart,
                    onPressed: () {
                      Provider.of<CartProvider>(context, listen: false).addItem(_currentProduct, _quantity);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text(AppStrings.addedToCart)),
                      );
                    },
                  ),
                ),
                const SizedBox(width: AppSizes.p16),
                Expanded(
                  child: PrimaryButton(
                    text: "Buy Now", // Assuming "Buy Now" string or similar
                    onPressed: _quickOrder,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
