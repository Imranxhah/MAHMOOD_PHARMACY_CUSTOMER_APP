import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/src/providers/product_provider.dart';
import 'package:customer_app/src/providers/cart_provider.dart';
import 'package:customer_app/src/features/products/presentation/product_detail_screen.dart';
import 'package:customer_app/src/features/cart/presentation/cart_screen.dart';
import '../../../constants/app_sizes.dart';
import '../../../constants/app_strings.dart';
import '../../../common_widgets/custom_text_field.dart';
import '../../../common_widgets/product_card.dart';
import '../../products/presentation/product_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      provider.fetchHomeData();
    });
  }

  Future<void> _refresh() async {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    await provider.fetchHomeData(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.homeData == null) {
            return const _HomeSkeleton();
          }

          if (provider.error != null && provider.homeData == null) {
             return Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                   const SizedBox(height: 16),
                   Text(provider.error!, style: Theme.of(context).textTheme.bodyLarge),
                   const SizedBox(height: 16),
                   FilledButton.tonal(onPressed: _refresh, child: const Text("Retry"))
                 ],
               ),
             );
          }
          
          final homeData = provider.homeData;
          // If no data and no error/loading, it might be empty or initial state, retry or show empty
          if (homeData == null) {
             return const Center(child: Text("No data available"));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  title: Row(
                    children: [
                      Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary, size: 20),
                      const SizedBox(width: 4),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.deliverTo,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                          Text(
                            AppStrings.homeAddressPlaceholder,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    Consumer<CartProvider>(
                      builder: (context, cart, _) {
                        return IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CartScreen()),
                            );
                          },
                          icon: Badge(
                            isLabelVisible: cart.itemCount > 0,
                            label: Text('${cart.itemCount}'),
                            child: const Icon(Icons.shopping_cart_outlined),
                          ),
                        );
                      }
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.p16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search Bar
                        CustomTextField(
                          controller: TextEditingController(),
                          hintText: AppStrings.searchHint,
                          prefixIcon: Icons.search,
                          onSubmitted: (value) {
                             Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductListScreen(initialSearch: value),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppSizes.p24),

                        // Banner Placeholder
                        Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(AppSizes.radius16),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.local_offer,
                                  size: 48,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  AppStrings.offerBanner,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.p32),

                        // Categories Header
                        if (homeData.categories.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppStrings.shopByCategory,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ProductListScreen(),
                                    ),
                                  );
                                },
                                child: const Text(AppStrings.viewAll),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.p16),
                          // Categories List (Horizontal)
                          SizedBox(
                            height: 110, 
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: homeData.categories.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 16),
                              itemBuilder: (context, index) {
                                final category = homeData.categories[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProductListScreen(categoryId: category.id),
                                      ),
                                    );
                                  },
                                  child: Column(
                                    children: [
                                      Container(
                                        height: 60,
                                        width: 60,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).cardColor,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
                                              blurRadius: 4,
                                            ),
                                          ],
                                          image: category.image != null ? DecorationImage(
                                            image: NetworkImage(category.image!),
                                            fit: BoxFit.cover,
                                          ) : null,
                                        ),
                                        child: category.image == null ? Icon(
                                          Icons.category,
                                          color: Theme.of(context).colorScheme.primary,
                                          size: 24,
                                        ) : null,
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: 70,
                                        child: Text(
                                          category.name,
                                          style: Theme.of(context).textTheme.bodySmall,
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: AppSizes.p24),
                        ],
                      ],
                    ),
                  ),
                ),
                // Dynamic Sections
                if (homeData.sections.isEmpty)
                   const SliverToBoxAdapter(
                     child: Padding(
                       padding: EdgeInsets.all(16.0),
                       child: Center(child: Text("No featured products today.")),
                     ),
                   )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final section = homeData.sections[index];
                        if (section.products.isEmpty) return const SizedBox.shrink();
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSizes.p24, left: AppSizes.p16, right: AppSizes.p16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    section.category.name,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                       Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProductListScreen(categoryId: section.category.id),
                                        ),
                                      );
                                    },
                                    child: const Text(AppStrings.viewAll)
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSizes.p16),
                              SizedBox(
                                height: 230,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: section.products.length,
                                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                                  itemBuilder: (context, idx) {
                                    final product = section.products[idx];
                                    return SizedBox(
                                      width: 150,
                                      child: ProductCard(
                                        product: product,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ProductDetailScreen(product: product),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: homeData.sections.length,
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)), // Bottom padding
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 60), // App bar approximation
            Container(
              height: 50, 
              decoration: BoxDecoration(
                color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12)
              )
            ), // Search
            const SizedBox(height: 24),
            Container(
              height: 150, 
              decoration: BoxDecoration(
                color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
            ), // Banner
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (index) => Column(children: [
              Container(
                height: 50, 
                width: 50, 
                decoration: BoxDecoration(
                  color: Theme.of(context).disabledColor.withValues(alpha: 0.1), 
                  shape: BoxShape.circle
                )
              ),
              const SizedBox(height: 8),
              Container(
                height: 10, 
                width: 40, 
                color: Theme.of(context).disabledColor.withValues(alpha: 0.1)
              ),
            ]))),
            const SizedBox(height: 32),
             Align(
               alignment: Alignment.centerLeft,
               child: Container(
                 height: 20, 
                 width: 150, 
                 color: Theme.of(context).disabledColor.withValues(alpha: 0.1)
               ),
             ),
             const SizedBox(height: 16),
             Row(children: [
               Container(
                 height: 200, 
                 width: 140, 
                 decoration: BoxDecoration(
                   color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                   borderRadius: BorderRadius.circular(12)
                 )
               ),
               const SizedBox(width: 16),
               Container(
                 height: 200, 
                 width: 140, 
                 decoration: BoxDecoration(
                   color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                   borderRadius: BorderRadius.circular(12)
                 )
               ),
             ])
          ],
        ),
      ),
    );
  }
}