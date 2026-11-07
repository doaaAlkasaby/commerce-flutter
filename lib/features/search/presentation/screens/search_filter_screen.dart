import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/core/widgets/app_button.dart';
import 'package:ecommerce/core/widgets/app_text_field.dart';
import 'package:ecommerce/core/widgets/app_drop_down.dart';
import 'package:ecommerce/features/home/models/home_response_model.dart';
import 'package:ecommerce/features/home/presentation/widgets/product_card.dart';
import 'package:ecommerce/features/product/data/product_repository.dart';
import 'package:ecommerce/features/search/presentation/providers/search_provider.dart';
import 'package:ecommerce/features/categories/presentation/providers/categories_provider.dart';

class SearchFilterScreen extends ConsumerStatefulWidget {
  const SearchFilterScreen({super.key});

  @override
  ConsumerState<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends ConsumerState<SearchFilterScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(searchQueryProvider);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        ref.read(searchQueryProvider.notifier).setQuery(query);
      }
    });
  }

  void _onSearchSubmitted(String query) {
    _debounceTimer?.cancel();
    ref.read(searchQueryProvider.notifier).setQuery(query);
  }

  void _showFilterBottomSheet(BuildContext context, AppStrings strings) {
    final currentFilter = ref.read(filterProvider);
    double minPrice = currentFilter.minPrice;
    double maxPrice = currentFilter.maxPrice;
    String? categoryId = currentFilter.categoryId;
    String? brandId = currentFilter.brandId;
    String sortBy = currentFilter.sortBy;
    String sortOrder = currentFilter.sortOrder;

    final categories = ref.read(activeCategoriesListProvider).value ?? [];
    final brands = ref.read(activeBrandsListProvider).value ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.all(24.w(context)),
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32.w(context))),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          strings.filterProducts,
                          style: context.textTheme.boldTitleLarge?.copyWith(fontSize: 20.sp(context)),
                        ),
                        TextButton(
                          onPressed: () {
                            ref.read(filterProvider.notifier).resetFilter();
                            Navigator.of(context).pop();
                          },
                          child: Text(strings.reset, style: context.textTheme.primaryTitleMedium?.copyWith(fontSize: 14.sp(context), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h(context)),
                    Text('${strings.priceRange} (\$0 - \$20000)', style: context.textTheme.fieldLabel?.copyWith(fontSize: 14.sp(context))),
                    RangeSlider(
                      values: RangeValues(minPrice, maxPrice),
                      min: 0,
                      max: 20000,
                      activeColor: AppColors.primary,
                      inactiveColor: Colors.grey.shade300,
                      labels: RangeLabels('\$${minPrice.toStringAsFixed(0)}', '\$${maxPrice.toStringAsFixed(0)}'),
                      onChanged: (values) {
                        setModalState(() {
                          minPrice = values.start;
                          maxPrice = values.end;
                        });
                      },
                    ),
                    SizedBox(height: 16.h(context)),
                    AppDropDown<String?>(
                      value: categoryId,
                      labelText: 'Category',
                      hintText: 'All Categories',
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('All Categories')),
                        ...categories.map((cat) => DropdownMenuItem<String?>(
                              value: cat['id']?.toString(),
                              child: Text(cat['name']?.toString() ?? ''),
                            )),
                      ],
                      onChanged: (val) => setModalState(() => categoryId = val),
                    ),
                    SizedBox(height: 16.h(context)),
                    AppDropDown<String?>(
                      value: brandId,
                      labelText: 'Brand',
                      hintText: 'All Brands',
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('All Brands')),
                        ...brands.map((brand) => DropdownMenuItem<String?>(
                              value: brand['id']?.toString(),
                              child: Text(brand['name']?.toString() ?? ''),
                            )),
                      ],
                      onChanged: (val) => setModalState(() => brandId = val),
                    ),
                    SizedBox(height: 16.h(context)),
                    Row(
                      children: [
                        Expanded(
                          child: AppDropDown<String>(
                            value: sortBy,
                            labelText: 'Sort By',
                            hintText: 'Date Added',
                            items: const [
                              DropdownMenuItem(value: 'createdAt', child: Text('Date Added')),
                              DropdownMenuItem(value: 'basePrice', child: Text('Price')),
                              DropdownMenuItem(value: 'name', child: Text('Name')),
                            ],
                            onChanged: (val) => setModalState(() => sortBy = val ?? 'createdAt'),
                          ),
                        ),
                        SizedBox(width: 12.w(context)),
                        Expanded(
                          child: AppDropDown<String>(
                            value: sortOrder,
                            labelText: 'Order',
                            hintText: 'Descending',
                            items: const [
                              DropdownMenuItem(value: 'desc', child: Text('Descending')),
                              DropdownMenuItem(value: 'asc', child: Text('Ascending')),
                            ],
                            onChanged: (val) => setModalState(() => sortOrder = val ?? 'desc'),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32.h(context)),
                    AppButton(
                      text: strings.applyFilters,
                      onPressed: () {
                        ref.read(filterProvider.notifier).updateFilter(
                              currentFilter.copyWith(
                                minPrice: minPrice,
                                maxPrice: maxPrice,
                                categoryId: categoryId,
                                brandId: brandId,
                                sortBy: sortBy,
                                sortOrder: sortOrder,
                              ),
                            );
                        Navigator.of(context).pop();
                      },
                    ),
                    SizedBox(height: 16.h(context)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizationAsync = ref.watch(appLocalizationLoaderProvider);
    final currentLang = ref.watch(languageProvider);
    final strings = AppStrings(localizationAsync.value ?? {}, currentLang);
    final isArabic = currentLang == AppLanguage.ar;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final query = ref.watch(searchQueryProvider);
    final filter = ref.watch(filterProvider);

    // Preload cached active categories and brands globally across the app
    ref.watch(activeCategoriesListProvider);
    ref.watch(activeBrandsListProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        elevation: 0,
        leading: Padding(
          padding: EdgeInsets.all(8.w(context)),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: Offset(0, 2.h(context)),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                isArabic ? Icons.arrow_forward_ios : Icons.arrow_back_ios_new,
                size: 16.sp(context),
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: AppTextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          onSubmitted: _onSearchSubmitted,
          textInputAction: TextInputAction.search,
          hintText: strings.searchProductsHint,
          prefixIcon: Icons.search,
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.w(context), top: 8.h(context), bottom: 8.h(context)),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2.h(context)),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.tune, size: 18.sp(context), color: AppColors.primary),
                onPressed: () => _showFilterBottomSheet(context, strings),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<ProductModel>>(
        future: ProductRepository(ref.read(dioClientProvider)).searchProducts(
          search: query,
          minPrice: filter.minPrice,
          maxPrice: filter.maxPrice,
          categoryId: filter.categoryId,
          brandId: filter.brandId,
          sortBy: filter.sortBy,
          sortOrder: filter.sortOrder,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64.sp(context), color: AppColors.lightTextSecondary),
                  SizedBox(height: 16.h(context)),
                  Text(
                    strings.noProductsFound,
                    style: context.textTheme.boldTitleLarge?.copyWith(
                          fontSize: 18.sp(context),
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                  ),
                  SizedBox(height: 6.h(context)),
                  Text(
                    strings.tryAdjusting,
                    style: context.textTheme.description?.copyWith(fontSize: 13.sp(context)),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.all(20.w(context)),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.68,
              crossAxisSpacing: 16.w(context),
              mainAxisSpacing: 16.h(context),
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(
                product: product,
                onFavoriteTap: () {},
                onAddTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${strings.addedToCart}: ${product.name}'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
