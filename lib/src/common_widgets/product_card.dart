import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/src/models/product_model.dart';
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
      end: 0.98,
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
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [theme.cardColor, theme.cardColor.withOpacity(0.95)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isHovered
                    ? colorScheme.primary.withOpacity(0.3)
                    : colorScheme.outlineVariant.withOpacity(0.2),
                width: _isHovered ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? colorScheme.primary.withOpacity(0.15)
                      : theme.shadowColor.withOpacity(0.08),
                  blurRadius: _isHovered ? 12 : 8,
                  spreadRadius: _isHovered ? 1 : 0,
                  offset: Offset(0, _isHovered ? 4 : 2),
                ),
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Square Image with 1:1 aspect ratio & Favorite Icon
                AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              colorScheme.surfaceContainerHighest.withOpacity(
                                0.3,
                              ),
                              colorScheme.surfaceContainerHighest.withOpacity(
                                0.1,
                              ),
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          image:
                              (widget.product.image != null &&
                                  widget.product.image!.startsWith('http'))
                              ? DecorationImage(
                                  image: NetworkImage(widget.product.image!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child:
                            (widget.product.image == null ||
                                !widget.product.image!.startsWith('http'))
                            ? Center(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer
                                        .withOpacity(0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.medication,
                                    size: 32,
                                    color: colorScheme.primary.withOpacity(0.6),
                                  ),
                                ),
                              )
                            : null,
                      ),
                      // Gradient overlay for better icon visibility
                      if (widget.product.image != null)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topRight,
                                end: Alignment.bottomLeft,
                                colors: [
                                  Colors.black.withOpacity(0.1),
                                  Colors.transparent,
                                ],
                              ),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      // Favorite Button
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Consumer2<AuthProvider, ProductProvider>(
                          builder: (context, auth, productProvider, _) {
                            return Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: theme.cardColor.withOpacity(0.95),
                                shape: const CircleBorder(),
                                clipBehavior: Clip.antiAlias,
                                elevation: 0,
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
                                              // Navigation logic would go here
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
                                    padding: const EdgeInsets.all(6),
                                    child: Icon(
                                      widget.product.isFavorite
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: widget.product.isFavorite
                                          ? colorScheme.primary
                                          : colorScheme.onSurfaceVariant
                                                .withValues(alpha: 0.6),
                                      size: 18,
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

                // Details & Cart Button - Compact layout
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.cardColor,
                        theme.cardColor.withOpacity(0.98),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            height: 1.1,
                            letterSpacing: 0.1,
                            color: theme.textTheme.titleSmall?.color
                                ?.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "\$${widget.product.price}",
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    letterSpacing: 0.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Consumer<CartProvider>(
                              builder: (context, cart, _) {
                                final isInCart = cart.items.containsKey(
                                  widget.product.id,
                                );

                                return Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            (isInCart
                                                    ? colorScheme.error
                                                    : colorScheme.primary)
                                                .withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: isInCart
                                        ? colorScheme.errorContainer
                                        : colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(6),
                                      onTap: () {
                                        if (isInCart) {
                                          cart.removeItem(widget.product.id);
                                        } else {
                                          cart.addItem(widget.product);
                                        }
                                      },
                                      splashColor:
                                          (isInCart
                                                  ? colorScheme.error
                                                  : colorScheme.primary)
                                              .withOpacity(0.2),
                                      highlightColor:
                                          (isInCart
                                                  ? colorScheme.error
                                                  : colorScheme.primary)
                                              .withOpacity(0.1),
                                      child: Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: Icon(
                                          isInCart
                                              ? Icons.remove_shopping_cart
                                              : Icons.add_shopping_cart,
                                          size: 16,
                                          color: isInCart
                                              ? colorScheme.onErrorContainer
                                              : colorScheme.onPrimaryContainer,
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
