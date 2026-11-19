import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/config/tenant_config.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/widgets/app_button.dart';
import 'package:ecommerce/core/widgets/app_drop_down.dart';
import 'package:ecommerce/features/categories/presentation/providers/categories_provider.dart';
import 'package:ecommerce/features/search/presentation/providers/search_provider.dart';

class SearchFilterBottomSheet extends ConsumerStatefulWidget {
  final AppStrings strings;

  const SearchFilterBottomSheet({super.key, required this.strings});

  static void show(BuildContext context, AppStrings strings) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SearchFilterBottomSheet(strings: strings),
    );
  }

  @override
  ConsumerState<SearchFilterBottomSheet> createState() =>
      _SearchFilterBottomSheetState();
}

class _SearchFilterBottomSheetState
    extends ConsumerState<SearchFilterBottomSheet> {
  late double _minPrice;
  late double _maxPrice;
  String? _categoryId;
  String? _brandId;
  late String _sortBy;
  late String _sortOrder;

  @override
  void initState() {
    super.initState();
    final currentFilter = ref.read(filterProvider);
    _minPrice = currentFilter.minPrice;
    _maxPrice = currentFilter.maxPrice ?? 2000.0;
    _categoryId = currentFilter.categoryId;
    _brandId = currentFilter.brandId;
    _sortBy = currentFilter.sortBy;
    _sortOrder = currentFilter.sortOrder;
  }

  @override
  Widget build(BuildContext context) {
    final currentFilter = ref.watch(filterProvider);
    final tenant = ref.watch(tenantProvider);
    final currencyStr = tenant.currencySymbol.isNotEmpty
        ? tenant.currencySymbol
        : '\$';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final categories = ref.watch(activeCategoriesListProvider).value ?? [];
    final brands = ref.watch(activeBrandsListProvider).value ?? [];

    return Container(
      padding: EdgeInsets.all(24.w(context)),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(32.w(context)),
        ),
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
                  widget.strings.filterProducts,
                  style: context.textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {
                    ref.read(filterProvider.notifier).resetFilter();
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    widget.strings.reset,
                    style: context.textTheme.primaryTitleMedium,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h(context)),
            Text(
              '${widget.strings.priceRange} (0 $currencyStr - ${_maxPrice >= 2000.0 ? widget.strings.anyLabel : "${_maxPrice.toStringAsFixed(0)} $currencyStr"})',
              style: context.textTheme.fieldLabel,
            ),
            RangeSlider(
              values: RangeValues(_minPrice, _maxPrice),
              min: 0,
              max: 2000,
              activeColor: AppColors.primary,
              inactiveColor: Colors.grey.shade300,
              labels: RangeLabels(
                '$currencyStr${_minPrice.toStringAsFixed(0)}',
                _maxPrice >= 2000.0
                    ? widget.strings.anyLabel
                    : '$currencyStr${_maxPrice.toStringAsFixed(0)}',
              ),
              onChanged: (values) {
                setState(() {
                  _minPrice = values.start;
                  _maxPrice = values.end;
                });
              },
            ),
            SizedBox(height: 16.h(context)),
            AppDropDown<String?>(
              value: _categoryId,
              labelText: widget.strings.categoryLabel,
              hintText: widget.strings.allCategories,
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(widget.strings.allCategories),
                ),
                ...categories.map(
                  (cat) => DropdownMenuItem<String?>(
                    value: cat['id']?.toString(),
                    child: Text(cat['name']?.toString() ?? ''),
                  ),
                ),
              ],
              onChanged: (val) => setState(() => _categoryId = val),
            ),
            SizedBox(height: 16.h(context)),
            AppDropDown<String?>(
              value: _brandId,
              labelText: widget.strings.brandLabel,
              hintText: widget.strings.allBrands,
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(widget.strings.allBrands),
                ),
                ...brands.map(
                  (brand) => DropdownMenuItem<String?>(
                    value: brand['id']?.toString(),
                    child: Text(brand['name']?.toString() ?? ''),
                  ),
                ),
              ],
              onChanged: (val) => setState(() => _brandId = val),
            ),
            SizedBox(height: 16.h(context)),
            Row(
              children: [
                Expanded(
                  child: AppDropDown<String>(
                    value: _sortBy,
                    labelText: widget.strings.sortByLabel,
                    hintText: widget.strings.dateAdded,
                    items: [
                      DropdownMenuItem(
                        value: 'createdAt',
                        child: Text(widget.strings.dateAdded),
                      ),
                      DropdownMenuItem(
                        value: 'basePrice',
                        child: Text(widget.strings.priceLabel),
                      ),
                      DropdownMenuItem(
                        value: 'name',
                        child: Text(widget.strings.nameLabel),
                      ),
                    ],
                    onChanged: (val) =>
                        setState(() => _sortBy = val ?? 'createdAt'),
                  ),
                ),
                SizedBox(width: 12.w(context)),
                Expanded(
                  child: AppDropDown<String>(
                    value: _sortOrder,
                    labelText: widget.strings.orderLabel,
                    hintText: widget.strings.descending,
                    items: [
                      DropdownMenuItem(
                        value: 'desc',
                        child: Text(widget.strings.descending),
                      ),
                      DropdownMenuItem(
                        value: 'asc',
                        child: Text(widget.strings.ascending),
                      ),
                    ],
                    onChanged: (val) =>
                        setState(() => _sortOrder = val ?? 'desc'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 32.h(context)),
            AppButton(
              text: widget.strings.applyFilters,
              onPressed: () {
                ref
                    .read(filterProvider.notifier)
                    .updateFilter(
                      currentFilter.copyWith(
                        minPrice: _minPrice,
                        maxPrice: _maxPrice >= 10000.0 ? null : _maxPrice,
                        categoryId: _categoryId,
                        brandId: _brandId,
                        sortBy: _sortBy,
                        sortOrder: _sortOrder,
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
  }
}
