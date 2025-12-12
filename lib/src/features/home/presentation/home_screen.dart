import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/src/providers/product_provider.dart';
import 'package:customer_app/src/features/products/presentation/product_detail_screen.dart';
import '../../../constants/app_sizes.dart';
import '../../../constants/app_strings.dart';
import '../../../common_widgets/custom_widgets.dart';
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
    // Initial fetch is now handled by SplashScreen
  }

  Future<void> _refresh() async {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    await provider.fetchHomeData(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: isDark
            ? Colors.black
            : theme.colorScheme.primary, // Match AppBar color
        statusBarIconBrightness:
            Brightness.light, // Always light icons for primary/black AppBar
        statusBarBrightness:
            Brightness.light, // Always light icons for primary/black AppBar
        systemNavigationBarIconBrightness: theme.brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarContrastEnforced: true,
      ),
      child: Scaffold(
        // Set scaffold background to match the gradient
        backgroundColor: isDark ? colorScheme.surface : Colors.grey[50],
        body: Consumer<ProductProvider>(
          builder: (context, provider, child) {
            // Show skeleton if data is null AND we are currently loading.
            if (provider.homeData == null && provider.isLoading) {
              return const _HomeSkeleton();
            }

            // Show error if there's an error AND we still don't have data.
            if (provider.error != null && provider.homeData == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer.withValues(
                            alpha: 0.3,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.error_outline,
                          size: 64,
                          color: colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Oops! Something went wrong',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        provider.error!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh),
                        label: const Text("Try Again"),
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
              );
            }

            final homeData = provider.homeData;

            // If after all checks, homeData is still null (meaning not loading, no error, but still empty),
            // then it genuinely means no data was returned.
            if (homeData == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 64,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No data available",
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                slivers: [
                  // App Bar with solid background
                  SliverAppBar(
                    floating: true,
                    elevation: 0,
                    backgroundColor: isDark
                        ? Colors.black
                        : theme.colorScheme.primary,
                    title: Text(
                      "Mahmood Pharmacy",
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.white
                            : theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.p16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Enhanced Search Bar
                          Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CustomTextField(
                              controller: TextEditingController(),
                              hint: AppStrings.searchHint,
                              prefixIcon: Icons.search,
                              onSubmitted: (value) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ProductListScreen(initialSearch: value),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: AppSizes.p24),

                          // Enhanced Banner with gradient and shadow
                          Container(
                            height: 160,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  colorScheme.primaryContainer,
                                  colorScheme.primaryContainer.withValues(
                                    alpha: 0.7,
                                  ),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(
                                AppSizes.radius16,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                // Decorative circles
                                Positioned(
                                  right: -20,
                                  top: -20,
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: colorScheme.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: -30,
                                  bottom: -30,
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: colorScheme.primary.withValues(
                                        alpha: 0.08,
                                      ),
                                    ),
                                  ),
                                ),
                                // Content
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: colorScheme.onPrimaryContainer
                                              .withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.local_offer,
                                          size: 48,
                                          color: colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        AppStrings.offerBanner,
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                              color: colorScheme
                                                  .onPrimaryContainer,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSizes.p32),

                          // Categories Section
                          if (homeData.categories.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppStrings.shopByCategory,
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      height: 3,
                                      width: 40,
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ProductListScreen(),
                                      ),
                                    );
                                  },
                                  icon: const Text(AppStrings.viewAll),
                                  label: Icon(Icons.arrow_forward, size: 16),
                                  style: TextButton.styleFrom(
                                    foregroundColor: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSizes.p16),

                            // Enhanced Categories List
                            SizedBox(
                              height: 115,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: homeData.categories.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  final category = homeData.categories[index];
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ProductListScreen(
                                                categoryId: category.id,
                                              ),
                                        ),
                                      );
                                    },
                                    child: SizedBox(
                                      width: 85,
                                      child: Column(
                                        children: [
                                          Container(
                                            height: 70,
                                            width: 70,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  colorScheme.primaryContainer
                                                      .withValues(alpha: 0.3),
                                                  colorScheme.primaryContainer
                                                      .withValues(alpha: 0.1),
                                                ],
                                              ),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: colorScheme.primary
                                                    .withValues(alpha: 0.2),
                                                width: 2,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: colorScheme.primary
                                                      .withValues(alpha: 0.15),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                              image: category.image != null
                                                  ? DecorationImage(
                                                      image: NetworkImage(
                                                        category.image!,
                                                      ),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : null,
                                            ),
                                            child: category.image == null
                                                ? Icon(
                                                    Icons.category,
                                                    color: colorScheme.primary,
                                                    size: 28,
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            category.name,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 11,
                                                ),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
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

                  // Dynamic Product Sections
                  if (homeData.sections.isEmpty && !provider.isLoading)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 64,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No featured products today.",
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final section = homeData.sections[index];
                        if (section.products.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSizes.p24,
                            left: AppSizes.p16,
                            right: AppSizes.p16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        section.category.name,
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        height: 2,
                                        width: 30,
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary,
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  TextButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ProductListScreen(
                                                categoryId: section.category.id,
                                              ),
                                        ),
                                      );
                                    },
                                    icon: const Text(AppStrings.viewAll),
                                    label: Icon(Icons.arrow_forward, size: 16),
                                    style: TextButton.styleFrom(
                                      foregroundColor: colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSizes.p16),
                              SizedBox(
                                height: 215,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: section.products.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 12),
                                  itemBuilder: (context, idx) {
                                    final product = section.products[idx];
                                    return SizedBox(
                                      width: 145,
                                      child: ProductCard(
                                        product: product,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ProductDetailScreen(
                                                    product: product,
                                                  ),
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
                      }, childCount: homeData.sections.length),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  Widget _buildShimmer(
    BuildContext context, {
    required double width,
    required double height,
    BorderRadius? borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.1),
            Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          ],
        ),
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),
            // Search bar shimmer
            _buildShimmer(
              context,
              width: double.infinity,
              height: 50,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(height: 24),
            // Banner shimmer
            _buildShimmer(
              context,
              width: double.infinity,
              height: 160,
              borderRadius: BorderRadius.circular(16),
            ),
            const SizedBox(height: 32),
            // Categories header shimmer
            _buildShimmer(context, width: 150, height: 24),
            const SizedBox(height: 16),
            // Categories shimmer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                4,
                (index) => Column(
                  children: [
                    _buildShimmer(
                      context,
                      width: 70,
                      height: 70,
                      borderRadius: BorderRadius.circular(35),
                    ),
                    const SizedBox(height: 8),
                    _buildShimmer(context, width: 60, height: 12),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Section header shimmer
            _buildShimmer(context, width: 180, height: 24),
            const SizedBox(height: 16),
            // Products shimmer
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Row(
                children: List.generate(
                  3,
                  (index) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _buildShimmer(
                      context,
                      width: 145,
                      height: 215,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ); // <--- Added the semicolon here
  }
}
