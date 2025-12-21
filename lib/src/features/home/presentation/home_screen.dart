import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/src/providers/product_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:customer_app/src/providers/banner_provider.dart';
import 'package:customer_app/src/features/products/presentation/product_detail_screen.dart';
import '../../../constants/app_sizes.dart';
import '../../../constants/app_strings.dart';
import '../../../common_widgets/custom_widgets.dart';
import '../../../common_widgets/product_card.dart';
import '../../products/presentation/product_list_screen.dart';
import 'dart:async';
import '../../notifications/presentation/notification_screen.dart';
import '../../../providers/notification_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BannerProvider>(context, listen: false).fetchBanners();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 10 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 10 && _isScrolled) {
      setState(() => _isScrolled = false);
    }
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

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : Colors.grey[50],
      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          if (provider.homeData == null && provider.isLoading) {
            return const _HomeSkeleton();
          }

          if (provider.error != null && provider.homeData == null) {
            return _buildErrorState(context, provider);
          }

          final homeData = provider.homeData;

          if (homeData == null) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            color: colorScheme.primary,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                _buildAppBar(context, isDark, _isScrolled),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildSearchSection(context, isDark),
                      gapH24,
                      Consumer<BannerProvider>(
                        builder: (context, bannerProvider, _) {
                          return PromotionalBanner(
                            isDark: isDark,
                            bannerProvider: bannerProvider,
                          );
                        },
                      ),
                      gapH32,
                      if (homeData.categories.isNotEmpty)
                        _buildCategoriesSection(context, homeData, isDark),
                    ],
                  ),
                ),
                _buildProductSections(context, homeData, provider, isDark),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark, bool isScrolled) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SliverAppBar(
      floating: true,
      snap: true,
      elevation: isScrolled ? 2 : 0,
      backgroundColor: isDark ? colorScheme.surface : colorScheme.primary,
      automaticallyImplyLeading: false, // Remove the back button
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      toolbarHeight: 64,
      title: Row(
        children: [
          Container(
            child: Image.asset(
              'assets/app_icon/ic_launcher.png',
              height: 54, // Matches the previous icon size
              width: 54,
            ),
          ),
          gapW12,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.appName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? colorScheme.onSurface : Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                'Your Health, Our Priority',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? colorScheme.onSurfaceVariant
                      : Colors.white.withOpacity(0.9),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Consumer<NotificationProvider>(
          builder: (context, notificationProvider, child) {
            final unreadCount = notificationProvider.unreadCount;
            return IconButton(
              onPressed: () {
                Provider.of<NotificationProvider>(
                  context,
                  listen: false,
                ).markAllRead();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationScreen()),
                );
              },
              icon: Badge(
                isLabelVisible: unreadCount > 0,
                label: Text('$unreadCount'),
                backgroundColor: Colors.red,
                child: Icon(
                  Icons.notifications_outlined,
                  color: isDark ? colorScheme.onSurface : Colors.white,
                ),
              ),
            );
          },
        ),
        gapW4,
      ],
    );
  }

  Widget _buildSearchSection(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p16,
        AppSizes.p20,
        AppSizes.p16,
        0,
      ),
      child: Material(
        elevation: isDark ? 0 : 2,
        shadowColor: colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        child: CustomTextField(
          controller: TextEditingController(),
          hint: AppStrings.searchHint,
          prefixIcon: Icons.search_rounded,
          onSubmitted: (value) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductListScreen(initialSearch: value),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(
    BuildContext context,
    dynamic homeData,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.shopByCategory,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProductListScreen(),
                    ),
                  );
                },
                icon: const Text(
                  AppStrings.viewAll,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                label: const Icon(Icons.arrow_forward_rounded, size: 18),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ],
          ),
        ),
        gapH16,
        SizedBox(
          height: 110,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
            scrollDirection: Axis.horizontal,
            itemCount: homeData.categories.length,
            separatorBuilder: (_, __) => gapW12,
            itemBuilder: (context, index) {
              final category = homeData.categories[index];
              return _buildCategoryCard(context, category, isDark);
            },
          ),
        ),
        gapH32,
      ],
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    dynamic category,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasImage = category.image != null && category.image!.isNotEmpty;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductListScreen(categoryId: category.id),
          ),
        );
      },
      child: SizedBox(
        width: 80,
        child: Column(
          children: [
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surfaceContainerHighest
                    : colorScheme.surfaceContainerHighest.withOpacity(0.5),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.15),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: hasImage
                    ? CachedNetworkImage(
                        imageUrl: category.image!,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Center(
                          child: Icon(
                            Icons.category_rounded,
                            color: colorScheme.primary,
                            size: 32,
                          ),
                        ),
                        placeholder: (context, url) => Container(
                          color: isDark
                              ? colorScheme.surfaceContainerHighest
                              : colorScheme.surfaceContainerHighest
                                  .withOpacity(0.5),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.category_rounded,
                          color: colorScheme.primary,
                          size: 32,
                        ),
                      ),
              ),
            ),
            gapH8,
            Text(
              category.name,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSections(
    BuildContext context,
    dynamic homeData,
    ProductProvider provider,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (homeData.sections.isEmpty && !provider.isLoading) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Column(
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 64,
                color: colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
              gapH16,
              Text(
                'No featured products available',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final section = homeData.sections[index];
        if (section.products.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.p32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section.category.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${section.products.length} products',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductListScreen(
                              categoryId: section.category.id,
                            ),
                          ),
                        );
                      },
                      icon: const Text(
                        AppStrings.viewAll,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      label: const Icon(Icons.arrow_forward_rounded, size: 18),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ],
                ),
              ),
              gapH16,

              // Products Grid - Enhanced Layout
              LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate optimal card width and count based on screen size
                  // final screenWidth = constraints.maxWidth; // Unused
                  final cardWidth = 165.0; // Slightly larger cards
                  // final spacing = 12.0; // Unused
                  // final horizontalPadding = AppSizes.p16 * 2; // Unused

                  // Calculate how many cards can fit
                  // final availableWidth = screenWidth - horizontalPadding; // Unused
                  // final cardsPerRow = (availableWidth / (cardWidth + spacing))
                  //    .floor()
                  //    .clamp(2, 4); // Unused variable removed

                  return SizedBox(
                    height: 240, // Increased height for better proportions
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.p16,
                      ),
                      scrollDirection: Axis.horizontal,
                      itemCount: section.products.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, idx) {
                        final product = section.products[idx];
                        return SizedBox(
                          width: cardWidth,
                          child: ProductCard(
                            product: product,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ProductDetailScreen(product: product),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        );
      }, childCount: homeData.sections.length),
    );
  }

  Widget _buildErrorState(BuildContext context, ProductProvider provider) {
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
              'Oops! Something went wrong',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            gapH8,
            Text(
              provider.error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            gapH24,
            FilledButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
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

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          gapH16,
          Text(
            'No data available',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// Promotional Banner Widget
// ============================================
class PromotionalBanner extends StatefulWidget {
  final bool isDark;
  final dynamic bannerProvider;

  const PromotionalBanner({
    super.key,
    required this.isDark,
    required this.bannerProvider,
  });

  @override
  State<PromotionalBanner> createState() => _PromotionalBannerState();
}

class _PromotionalBannerState extends State<PromotionalBanner> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _autoPlayTimer;
  // Start at a large index to allow infinite scrolling in both directions
  static const int _kStartingPage = 10000;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _kStartingPage);
    _startAutoPlay();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onPageChanged(int page) {
    final banners = widget.bannerProvider.banners;
    if (banners.isEmpty) return;
    
    setState(() {
      _currentPage = (page % banners.length).toInt();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.bannerProvider.isLoading &&
        widget.bannerProvider.banners.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            color: widget.isDark
                ? colorScheme.surfaceContainerHighest
                : const Color.fromARGB(255, 255, 255, 255),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.primary,
            ),
          ),
        ),
      );
    }

    if (widget.bannerProvider.banners.isEmpty) {
      return _buildDefaultBanner(context);
    }

    final banners = widget.bannerProvider.banners;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
      child: Column(
        children: [
          SizedBox(
            height: 160,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              // Infinite items
              itemBuilder: (context, index) {
                final actualIndex = index % banners.length;
                final banner = banners[actualIndex];
                return _buildBannerCard(context, banner);
              },
            ),
          ),
          if (banners.length > 1) ...[
            gapH12,
            _buildPageIndicators(banners.length),
          ],
        ],
      ),
    );
  }

  Widget _buildBannerCard(BuildContext context, dynamic banner) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: widget.isDark
            ? theme.colorScheme.surfaceContainerHighest
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: CachedNetworkImage(
          imageUrl: banner.image,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => Container(
            color: theme.colorScheme.errorContainer,
            child: Icon(
              Icons.broken_image_rounded,
              size: 48,
              color: theme.colorScheme.error,
            ),
          ),
          placeholder: (context, url) => Container(
            color: widget.isDark
                ? theme.colorScheme.surfaceContainerHighest
                : const Color.fromARGB(255, 255, 255, 255),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicators(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == _currentPage;
        return GestureDetector(
          onTap: () {
            // Calculate the target page closest to the current page
            if (_pageController.hasClients) {
              final currentDataPage = _pageController.page!.round();
              final currentMod = currentDataPage % count;
              final difference = index - currentMod;
              final targetPage = currentDataPage + difference;
              
              _pageController.animateToPage(
                targetPage,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 8,
            width: isActive ? 24 : 8,
            decoration: BoxDecoration(
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDefaultBanner(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: widget.isDark ? null : theme.scaffoldBackgroundColor,
          gradient: widget.isDark
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.primaryContainer.withOpacity(0.6),
                  ],
                )
              : null, // No gradient in light mode
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(
                widget.isDark ? 0.15 : 0.25,
              ),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(widget.isDark ? 0.05 : 0.1),
                ),
              ),
            ),
            Positioned(
              left: -20,
              bottom: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(widget.isDark ? 0.03 : 0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(
                              widget.isDark ? 0.15 : 0.2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'SPECIAL OFFER',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: widget.isDark
                                  ? colorScheme.onPrimaryContainer
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        gapH12,
                        Text(
                          AppStrings.offerBanner,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: widget.isDark
                                ? colorScheme.onPrimaryContainer
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(
                        widget.isDark ? 0.15 : 0.2,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.local_offer_rounded,
                      size: 40,
                      color: widget.isDark
                          ? colorScheme.onPrimaryContainer
                          : Colors.white,
                    ),
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

// ============================================
// Skeleton Loader
// ============================================
class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  Widget _buildShimmer(
    BuildContext context, {
    required double width,
    required double height,
    BorderRadius? borderRadius,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            theme.colorScheme.surfaceContainerHighest.withOpacity(0.1),
            theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          ],
        ),
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          gapH64,
          gapH24,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
            child: _buildShimmer(
              context,
              width: double.infinity,
              height: 56,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          gapH24,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
            child: _buildShimmer(
              context,
              width: double.infinity,
              height: 160,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          gapH32,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
            child: _buildShimmer(context, width: 180, height: 24),
          ),
          gapH16,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                4,
                (index) => Column(
                  children: [
                    _buildShimmer(
                      context,
                      width: 80,
                      height: 80,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    gapH8,
                    _buildShimmer(context, width: 70, height: 12),
                  ],
                ),
              ),
            ),
          ),
          gapH32,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
            child: _buildShimmer(context, width: 200, height: 24),
          ),
          gapH16,
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
              child: Row(
                children: List.generate(
                  3,
                  (index) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _buildShimmer(context, width: 145, height: 215),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
