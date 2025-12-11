import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/src/models/product_model.dart';
import 'package:customer_app/src/providers/auth_provider.dart';
import 'package:customer_app/src/providers/cart_provider.dart';
import 'package:customer_app/src/providers/product_provider.dart';
import '../constants/app_sizes.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppSizes.radius12),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image & Favorite Icon
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppSizes.radius12),
                      ),
                      image: product.image != null
                          ? DecorationImage(
                              image: NetworkImage(product.image!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: product.image == null
                        ? Center(
                            child: Icon(
                              Icons.medication,
                              size: 48,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          )
                        : null,
                  ),
                  // Favorite Button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Consumer2<AuthProvider, ProductProvider>(
                      builder: (context, auth, productProvider, _) {
                        return Material(
                          color: Theme.of(context).cardColor.withValues(alpha: 0.9),
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          elevation: 2,
                          child: InkWell(
                            onTap: () async {
                              if (!auth.isAuthenticated) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text("Please login to add favorites."),
                                    action: SnackBarAction(
                                      label: "Login",
                                      onPressed: () {
                                        // Navigation logic would go here
                                      },
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }
                              try {
                                await productProvider.toggleFavorite(product.id);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Failed: ${e.toString()}")),
                                  );
                                }
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Icon(
                                product.isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: product.isFavorite ? Colors.red : Colors.grey,
                                size: 20,
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
            
            // Details & Cart Button
            Padding(
              padding: const EdgeInsets.all(AppSizes.p8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 40, // Fixed height for title to align rows
                    child: Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.p8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "\$ ${product.price}",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Consumer<CartProvider>(
                        builder: (context, cart, _) {
                          final isInCart = cart.items.containsKey(product.id);
                          
                          return Material(
                            color: isInCart 
                                ? Theme.of(context).colorScheme.errorContainer 
                                : Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                if (isInCart) {
                                  cart.removeItem(product.id);
                                } else {
                                  cart.addItem(product);
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Icon(
                                  isInCart ? Icons.remove : Icons.add,
                                  size: 20,
                                  color: isInCart 
                                      ? Theme.of(context).colorScheme.onErrorContainer 
                                      : Theme.of(context).colorScheme.onPrimaryContainer,
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
          ],
        ),
      ),
    );
  }
}
