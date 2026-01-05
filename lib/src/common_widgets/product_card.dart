import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:customer_app/src/models/product_model.dart';
import 'package:customer_app/src/features/auth/presentation/screens/login_screen.dart';
import 'package:customer_app/src/providers/auth_provider.dart';
import 'package:customer_app/src/providers/cart_provider.dart';
import 'package:customer_app/src/providers/product_provider.dart';

class ProductCard extends StatefulWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () => _controller.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isHovered
                    ? colorScheme.primary.withOpacity(0.4)
                    : colorScheme.outlineVariant.withOpacity(0.15),
                width: _isHovered ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? colorScheme.primary.withOpacity(0.2)
                      : (isDark
                            ? Colors.black.withOpacity(0.3)
                            : Colors.black.withOpacity(0.08)),
                  blurRadius: _isHovered ? 16 : 10,
                  spreadRadius: _isHovered ? 2 : 0,
                  offset: Offset(0, _isHovered ? 6 : 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section with improved aspect ratio
                AspectRatio(
                  aspectRatio: 1.1,
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark
                              ? colorScheme.surfaceContainerHighest.withOpacity(
                                  0.3,
                                )
                              : colorScheme.surfaceContainerHighest.withOpacity(
                                  0.15,
                                ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          image:
                              (widget.product.image != null &&
                                  widget.product.image!.startsWith('http'))
                              ? DecorationImage(
                                  image: CachedNetworkImageProvider(
                                    widget.product.image!,
                                  ),
                                  fit: BoxFit.cover,
                                  colorFilter: widget.product.stock <= 0
                                      ? ColorFilter.mode(
                                          Colors.grey.withOpacity(0.5),
                                          BlendMode.saturation,
                                        )
                                      : null,
                                )
                              : null,
                        ),
                        child:
                            (widget.product.image == null ||
                                !widget.product.image!.startsWith('http'))
                            ? Center(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer
                                        .withOpacity(0.4),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.medication_rounded,
                                    size: 36,
                                    color: colorScheme.primary.withOpacity(0.7),
                                  ),
                                ),
                              )
                            : null,
                      ),

                      // Out of Stock Overlay
                      if (widget.product.stock <= 0)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.error,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  "OUT OF STOCK",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Subtle gradient overlay
                      if (widget.product.image != null &&
                          widget.product.stock > 0)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                          ),
                        ),

                      // Favorite Button with improved styling
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Consumer2<AuthProvider, ProductProvider>(
                          builder: (context, auth, productProvider, _) {
                            return Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (isDark ? Colors.black : Colors.white)
                                    .withOpacity(0.85),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                shape: const CircleBorder(),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () async {
                                    if (!auth.isAuthenticated) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          backgroundColor:
                                              colorScheme.errorContainer,
                                          content: Text(
                                            "Please login to add favorites.",
                                            style: TextStyle(
                                              color:
                                                  colorScheme.onErrorContainer,
                                            ),
                                          ),
                                          action: SnackBarAction(
                                            label: "Login",
                                            textColor: colorScheme.primary,
                                            onPressed: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const LoginScreen(),
                                                ),
                                              );
                                            },
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                      return;
                                    }
                                    try {
                                      await productProvider.toggleFavorite(
                                        widget.product.id,
                                      );
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            backgroundColor:
                                                colorScheme.errorContainer,
                                            content: Text(
                                              "Failed: ${e.toString()}",
                                              style: TextStyle(
                                                color: colorScheme
                                                    .onErrorContainer,
                                              ),
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(
                                      widget.product.isFavorite
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: widget.product.isFavorite
                                          ? Colors.pink
                                          : colorScheme.onSurfaceVariant
                                                .withOpacity(0.7),
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Content Section with fixed spacing to prevent overflow
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Product Name with 2 line limit and ellipsis
                        Flexible(
                          child: Text(
                            widget.product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                              height: 1.3,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Price and Cart Button Row with fixed height
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Price Container with flexible width and ellipsis
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      colorScheme.primaryContainer,
                                      colorScheme.primaryContainer.withOpacity(
                                        0.8,
                                      ),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "PKR ${widget.product.price}",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    letterSpacing: 0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Cart Button with fixed size
                            Consumer<CartProvider>(
                              builder: (context, cart, _) {
                                final isInCart = cart.items.containsKey(
                                  widget.product.id,
                                );

                                return Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    gradient: LinearGradient(
                                      colors: widget.product.stock <= 0
                                          ? [
                                              colorScheme
                                                  .surfaceContainerHighest,
                                              colorScheme
                                                  .surfaceContainerHighest,
                                            ]
                                          : (isInCart
                                                ? [
                                                    colorScheme.errorContainer,
                                                    colorScheme.errorContainer
                                                        .withOpacity(0.9),
                                                  ]
                                                : [
                                                    colorScheme.primary,
                                                    colorScheme.primary
                                                        .withOpacity(0.9),
                                                  ]),
                                    ),
                                    boxShadow: widget.product.stock <= 0
                                        ? null
                                        : [
                                            BoxShadow(
                                              color:
                                                  (isInCart
                                                          ? colorScheme.error
                                                          : colorScheme.primary)
                                                      .withOpacity(0.3),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: widget.product.stock <= 0
                                          ? null
                                          : () {
                                              if (isInCart) {
                                                cart.removeItem(
                                                  widget.product.id,
                                                );
                                              } else {
                                                cart.addItem(widget.product);
                                              }
                                            },
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Icon(
                                          widget.product.stock <= 0
                                              ? Icons.block_flipped
                                              : (isInCart
                                                    ? Icons
                                                          .remove_shopping_cart_rounded
                                                    : Icons
                                                          .add_shopping_cart_rounded),
                                          size: 18,
                                          color: widget.product.stock <= 0
                                              ? colorScheme.outline
                                              : (isInCart
                                                    ? colorScheme
                                                          .onErrorContainer
                                                    : Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
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
}
