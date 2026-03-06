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
import 'package:customer_app/src/common_widgets/product_card.dart';

import '../../../constants/app_strings.dart';

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
  bool _hasFetchedRelated = false;
  late ScrollController _scrollController;
  String _selectedUnit = 'Default';
  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;

    // Set default unit based on availability
    final bool hasPack = _currentProduct.packPrice != null && (double.tryParse(_currentProduct.packPrice!) ?? 0) > 0;
    final bool hasSingle = (_currentProduct.pricePerPiece != null && (double.tryParse(_currentProduct.pricePerPiece!) ?? 0) > 0) ||
                          (_currentProduct.stripPrice != null && (double.tryParse(_currentProduct.stripPrice!) ?? 0) > 0);

    if (hasPack || hasSingle) {
      if (hasSingle) {
        _selectedUnit = 'Single';
      } else {
        _selectedUnit = 'Pack';
      }
    } else {
      _selectedUnit = 'Default';
    }

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Check if content fits on screen initially
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients &&
          _scrollController.position.maxScrollExtent == 0) {
        _fetchRelatedProducts();
        _hasFetchedRelated = true;
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  String _getDisplayPrice() {
    switch (_selectedUnit) {
      case 'Pack':
        return _currentProduct.packPrice ?? _currentProduct.price;
      case 'Single':
        return _currentProduct.pricePerPiece ?? _currentProduct.stripPrice ?? _currentProduct.price;
      default:
        return _currentProduct.price;
    }
  }

  int _getMaxStock() {
    if (_selectedUnit == 'Pack') {
      final int stripsInPack = _currentProduct.stripsInPack ?? 1;
      // Prevent division by zero
      if (stripsInPack <= 0) return 0;
      // Stock is in strips for medicines with packs
      return (_currentProduct.stock / stripsInPack).floor();
    }
    
    // For Single or Default, we check directly against stock
    return _currentProduct.stock;
  }

  String _calculateTotalPrice() {
    final double unitPrice = double.tryParse(_getDisplayPrice()) ?? 0.0;
    final double total = unitPrice * _quantity;

    // Format: remove decimals if whole number
    if (total % 1 == 0) {
      return total.toInt().toString();
    }
    return total.toStringAsFixed(2);
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;

      // Fetch when user scrolls to within 300px of the bottom
      if (maxScroll - currentScroll <= 300) {
        if (!_hasFetchedRelated && !_isLoadingRelated) {
          debugPrint('SCROLL: Near bottom, triggering fetchRelatedProducts');
          _hasFetchedRelated = true;
          _fetchRelatedProducts();
        }
      }
    }
  }

  Future<void> _fetchRelatedProducts() async {
    if (!mounted) return;

    debugPrint(
      'FETCH: Starting to fetch related products for category: ${_currentProduct.category} and generic: ${_currentProduct.genericName}',
    );

    setState(() {
      _isLoadingRelated = true;
    });
    try {
      final products =
          await Provider.of<ProductProvider>(
            context,
            listen: false,
          ).fetchRelatedProducts(
            _currentProduct.category,
            genericName: _currentProduct.genericName,
          );
      if (mounted) {
        setState(() {
          _relatedProducts = products
              .where((p) => p.id != _currentProduct.id)
              .toList();
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
    int maxStock = _getMaxStock();
    if (_quantity < maxStock) {
      setState(() {
        _quantity++;
      });
    } else {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Maximum available quantity for $_selectedUnit is $maxStock",
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
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

    // Double check stock before proceeding
    if (_quantity > _getMaxStock()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Insufficient stock for the selected quantity."),
        ),
      );
      return;
    }

    try {
      final double price = double.tryParse(_getDisplayPrice()) ?? 0.0;
      final double total = price * _quantity;

      final List<Map<String, dynamic>> buyNowItem = [
        {
          'product_id': _currentProduct.id,
          'quantity': _quantity,
          'unit_type': _selectedUnit,
        },
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

  void _updateUnit(String newUnit) {
    setState(() {
      _selectedUnit = newUnit;
      _quantity = 1; // Reset quantity when unit changes
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.details),
        actions: [
          Consumer<ProductProvider>(
            builder: (context, provider, child) {
              ProductModel? liveProduct;

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
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Enhanced Product Image Section ---
            Container(
              width: double.infinity,
              height: 400,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surfaceContainerHighest.withOpacity(0.3)
                    : colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Hero(
                tag: _currentProduct.id,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child:
                      _currentProduct.image != null &&
                          _currentProduct.image!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: _currentProduct.image!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(
                              color: colorScheme.primary,
                            ),
                          ),
                          errorWidget: (context, url, error) => Center(
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
                            size: 120,
                            color: colorScheme.primary.withOpacity(0.5),
                          ),
                        ),
                ),
              ),
            ),

            // --- Product Information Card ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category and Stock Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _currentProduct.categoryName,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _currentProduct.stock > 0
                              ? colorScheme.tertiaryContainer
                              : colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _currentProduct.stock > 0
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              size: 16,
                              color: _currentProduct.stock > 0
                                  ? colorScheme.onTertiaryContainer
                                  : colorScheme.onErrorContainer,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _currentProduct.stock > 0
                                  ? "In Stock (${_currentProduct.stock})"
                                  : "Out of Stock",
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: _currentProduct.stock > 0
                                    ? colorScheme.onTertiaryContainer
                                    : colorScheme.onErrorContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Product Name
                  Text(
                    _currentProduct.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),

                  if (_currentProduct.genericName != null &&
                      _currentProduct.genericName!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      "Generic Name: ${_currentProduct.genericName!}",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],

                  if (_currentProduct.manufacturer != null &&
                      _currentProduct.manufacturer!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.business_rounded,
                          size: 16,
                          color: colorScheme.primary.withOpacity(0.7),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "Manufacturer: ${_currentProduct.manufacturer!}",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Unit Selection
                  if ((_currentProduct.packPrice != null && (double.tryParse(_currentProduct.packPrice!) ?? 0) > 0) ||
                      (_currentProduct.stripPrice != null && (double.tryParse(_currentProduct.stripPrice!) ?? 0) > 0) ||
                      (_currentProduct.pricePerPiece != null && (double.tryParse(_currentProduct.pricePerPiece!) ?? 0) > 0)) ...[
                    Text(
                      "Select Unit",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if ((_currentProduct.pricePerPiece != null && (double.tryParse(_currentProduct.pricePerPiece!) ?? 0) > 0) ||
                            (_currentProduct.stripPrice != null && (double.tryParse(_currentProduct.stripPrice!) ?? 0) > 0))
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text(_currentProduct.pricePerPiece == null && _currentProduct.stripPrice != null ? "Strip" : "Single"),
                              value: 'Single',
                              groupValue: _selectedUnit,
                              onChanged: (val) => _updateUnit(val!),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                        if (_currentProduct.packPrice != null && (double.tryParse(_currentProduct.packPrice!) ?? 0) > 0)
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text("Pack"),
                              value: 'Pack',
                              groupValue: _selectedUnit,
                              onChanged: (val) => _updateUnit(val!),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                      ],
                    ),
                    if (_selectedUnit == 'Pack' && _currentProduct.stripsInPack != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          "1 Pack contains ${_currentProduct.stripsInPack} Strips",
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    if (_selectedUnit == 'Single' && _currentProduct.tabletsInStrip != null && _currentProduct.pricePerPiece == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          "1 Strip contains ${_currentProduct.tabletsInStrip} Tablets",
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],

                  // Price and Quantity Row (Original Design)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price and Stock
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Price",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              "PKR ${_calculateTotalPrice()}",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Modern Capsule Quantity Selector (Original)
                      if (_getMaxStock() > 0)
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
                                onTap: _increment,
                                colorScheme: colorScheme,
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "Out of Stock",
                            style: TextStyle(
                              color: colorScheme.onErrorContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  Divider(color: colorScheme.outlineVariant),
                  const SizedBox(height: 16),

                  // Description Section
                  Text(
                    AppStrings.description,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final description = _currentProduct.description;
                      const int characterLimit = 150;
                      final isLongDescription = description.length > characterLimit;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isDescriptionExpanded || !isLongDescription
                                ? description
                                : '${description.substring(0, characterLimit)}...',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.6,
                            ),
                          ),
                          if (isLongDescription)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isDescriptionExpanded = !_isDescriptionExpanded;
                                  });
                                },
                                child: Text(
                                  _isDescriptionExpanded ? "Read Less" : "Read More",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 54,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: _getMaxStock() > 0
                                    ? colorScheme.primary
                                    : colorScheme.outline,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _getMaxStock() > 0
                                ? () {
                                    Provider.of<CartProvider>(
                                      context,
                                      listen: false,
                                    ).addItem(
                                      _currentProduct,
                                      _quantity,
                                      _selectedUnit,
                                    );
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
                                color: _getMaxStock() > 0
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
                              backgroundColor: _getMaxStock() > 0
                                  ? colorScheme.primary
                                  : colorScheme.surfaceContainerHighest,
                              foregroundColor: _getMaxStock() > 0
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurfaceVariant,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _getMaxStock() > 0 ? _buyNow : null,
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

                  // Related Products Section
                  if (_relatedProducts.isNotEmpty) ...[
                    Text(
                      "Related Products",
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.65,
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
