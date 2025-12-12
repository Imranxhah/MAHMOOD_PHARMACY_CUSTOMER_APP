import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/src/providers/product_provider.dart';
import 'package:customer_app/src/models/category_model.dart';
import 'package:customer_app/src/constants/app_sizes.dart';
import 'package:customer_app/src/constants/app_strings.dart';

class ProductSearchWidget extends StatefulWidget {
  final int? initialCategoryId;
  final String? initialSearch;
  final bool showFilters;
  final Function(
    String search,
    int? categoryId,
    String? ordering,
    double? minPrice,
    double? maxPrice,
  )?
  onSearchChanged;

  const ProductSearchWidget({
    super.key,
    this.initialCategoryId,
    this.initialSearch,
    this.showFilters = true,
    this.onSearchChanged,
  });

  @override
  State<ProductSearchWidget> createState() => _ProductSearchWidgetState();
}

class _ProductSearchWidgetState extends State<ProductSearchWidget> {
  late TextEditingController _searchController;
  int? _selectedCategoryId;
  String? _selectedOrdering;
  double? _minPrice;
  double? _maxPrice;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearch);
    _selectedCategoryId = widget.initialCategoryId;
  }

  @override
  void didUpdateWidget(covariant ProductSearchWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCategoryId != oldWidget.initialCategoryId) {
      setState(() {
        _selectedCategoryId = widget.initialCategoryId;
        _selectedOrdering = null;
        _minPrice = null;
        _maxPrice = null;
        // Optionally clear search controller if you want a complete reset
        // _searchController.clear();
      });
      // We don't automatically fetch/apply filters here because the parent widget
      // (ProductListScreen) likely fetches products for the new categoryId in its own initState/update logic.
      // If we called _applyFilters() here, it might cause a double fetch.
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    provider.fetchProducts(
      search: _searchController.text,
      categoryId: _selectedCategoryId,
      ordering: _selectedOrdering,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
    );
    if (widget.onSearchChanged != null) {
      widget.onSearchChanged!(
        _searchController.text,
        _selectedCategoryId,
        _selectedOrdering,
        _minPrice,
        _maxPrice,
      );
    }
  }

  void _showSortBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(AppSizes.p20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Sort By",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSizes.p20),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildSortChip(
                        context,
                        "Newest",
                        "-created_at",
                        setModalState,
                      ),
                      _buildSortChip(
                        context,
                        "Price: Low to High",
                        "price",
                        setModalState,
                      ),
                      _buildSortChip(
                        context,
                        "Price: High to Low",
                        "-price",
                        setModalState,
                      ),
                      _buildSortChip(
                        context,
                        "Oldest",
                        "created_at",
                        setModalState,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.p20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _applyFilters();
                      },
                      child: const Text("Apply Sort"),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    if (provider.categories.isEmpty) {
      provider.fetchCategories();
    }

    int? tempCategoryId = _selectedCategoryId;
    TextEditingController minPriceController = TextEditingController(
      text: _minPrice?.toString(),
    );
    TextEditingController maxPriceController = TextEditingController(
      text: _maxPrice?.toString(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(AppSizes.p20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Filters",
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempCategoryId = null;
                              minPriceController.clear();
                              maxPriceController.clear();
                            });
                          },
                          child: const Text("Clear All"),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.p20),
                    Text(
                      "Category",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSizes.p8),
                    Consumer<ProductProvider>(
                      builder: (context, provider, _) {
                        if (provider.isLoading && provider.categories.isEmpty) {
                          return const LinearProgressIndicator();
                        }
                        return DropdownButtonFormField<int>(
                          value: tempCategoryId,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            hintText: "Select Category",
                          ),
                          items: provider.categories.map((
                            CategoryModel category,
                          ) {
                            return DropdownMenuItem<int>(
                              value: category.id,
                              child: Text(category.name),
                            );
                          }).toList(),
                          onChanged: (int? value) {
                            setModalState(() {
                              tempCategoryId = value;
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: AppSizes.p20),
                    Text(
                      "Price Range",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSizes.p8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minPriceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Min Price",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: maxPriceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Max Price",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.p24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedCategoryId = tempCategoryId;
                            _minPrice = double.tryParse(
                              minPriceController.text,
                            );
                            _maxPrice = double.tryParse(
                              maxPriceController.text,
                            );
                          });
                          Navigator.pop(context);
                          _applyFilters();
                        },
                        child: const Text("Apply Filters"),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSortChip(
    BuildContext context,
    String label,
    String value,
    StateSetter setModalState,
  ) {
    final isSelected = _selectedOrdering == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setModalState(() {
          _selectedOrdering = selected ? value : null;
        });
        setState(() {
          _selectedOrdering = selected ? value : null;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Enhanced Search Bar
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
          ),
          child: TextField(
            controller: _searchController,
            onSubmitted: (_) => _applyFilters(),
            decoration: InputDecoration(
              hintText: AppStrings.searchHint,
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: colorScheme.onSurfaceVariant,
                size: 22,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              isDense: true,
            ),
            style: theme.textTheme.bodyMedium,
            textInputAction: TextInputAction.search,
          ),
        ),

        if (widget.showFilters) ...[
          const SizedBox(height: 12),
          // Filter & Sort Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showSortBottomSheet(context),
                  icon: Icon(Icons.sort, size: 18),
                  label: const Text("Sort"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(
                      color: _selectedOrdering != null
                          ? colorScheme.primary
                          : colorScheme.outline.withOpacity(0.3),
                    ),
                    backgroundColor: _selectedOrdering != null
                        ? colorScheme.primaryContainer.withOpacity(0.2)
                        : null,
                    foregroundColor: _selectedOrdering != null
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showFilterBottomSheet(context),
                  icon: Icon(
                    Icons.tune,
                    size: 18,
                  ), // Using tune icon for filter
                  label: const Text("Filter"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(
                      color:
                          (_selectedCategoryId != null ||
                              _minPrice != null ||
                              _maxPrice != null)
                          ? colorScheme.primary
                          : colorScheme.outline.withOpacity(0.3),
                    ),
                    backgroundColor:
                        (_selectedCategoryId != null ||
                            _minPrice != null ||
                            _maxPrice != null)
                        ? colorScheme.primaryContainer.withOpacity(0.2)
                        : null,
                    foregroundColor:
                        (_selectedCategoryId != null ||
                            _minPrice != null ||
                            _maxPrice != null)
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
