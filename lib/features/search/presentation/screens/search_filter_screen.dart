import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/widgets/app_empty_widget.dart';
import 'package:ecommerce/core/widgets/app_error_widget.dart';
import 'package:ecommerce/core/widgets/app_text_field.dart';
import 'package:ecommerce/features/categories/presentation/providers/categories_provider.dart';
import 'package:ecommerce/features/search/presentation/providers/search_provider.dart';
import '../widgets/search_filter_bottom_sheet.dart';
import '../widgets/search_product_grid.dart';

class SearchFilterScreen extends ConsumerStatefulWidget {
  const SearchFilterScreen({super.key});

  @override
  ConsumerState<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends ConsumerState<SearchFilterScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(searchQueryProvider);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(searchControllerProvider.notifier).loadNextPage();
    }
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

  @override
  Widget build(BuildContext context) {
    final localizationAsync = ref.watch(appLocalizationLoaderProvider);
    final currentLang = ref.watch(languageProvider);
    final strings = AppStrings(localizationAsync.value ?? {}, currentLang);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final searchAsync = ref.watch(searchControllerProvider);

    ref.watch(activeCategoriesListProvider);
    ref.watch(activeBrandsListProvider);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
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
                Icons.arrow_back_ios_new,
                size: 16.sp(context),
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
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
          bkgColor: Theme.of(context).cardColor,
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(
              right: 16.w(context),
              top: 8.h(context),
              bottom: 8.h(context),
            ),
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
                  Icons.tune,
                  size: 18.sp(context),
                  color: AppColors.primary,
                ),
                onPressed: () => SearchFilterBottomSheet.show(context, strings),
              ),
            ),
          ),
        ],
      ),
      body: searchAsync.when(
        data: (paginatedState) {
          final products = paginatedState.items;

          if (products.isEmpty) {
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                await ref.read(searchControllerProvider.notifier).refresh();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                children: [
                  SizedBox(height: 120.h(context)),
                  AppEmptyWidget(
                    title: strings.noProductsFound,
                    subtitle: strings.tryAdjusting,
                    icon: Icons.search_off,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              await ref.read(searchControllerProvider.notifier).refresh();
            },
            child: SearchProductGrid(
              scrollController: _scrollController,
              paginatedState: paginatedState,
              strings: strings,
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => AppErrorWidget(
          message: strings.failedToSearchProducts,
          icon: Icons.search_off,
          onRetry: () => ref.invalidate(searchControllerProvider),
        ),
      ),
    );
  }
}
