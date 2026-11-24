import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/config/tenant_config.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/app_error_utils.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/features/auth/presentation/screens/login_screen.dart';
import 'package:ecommerce/features/cart/presentation/providers/cart_provider.dart';
import 'package:ecommerce/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:ecommerce/features/home/models/home_response_model.dart';
import 'package:ecommerce/features/main_shell_screen.dart';
import 'package:ecommerce/features/product/data/product_repository.dart';
import 'package:ecommerce/features/product/presentation/providers/reviews_provider.dart';
import 'package:ecommerce/features/product/presentation/screens/all_reviews_screen.dart';
import 'package:ecommerce/features/product/presentation/widgets/product_attributes.dart';
import 'package:ecommerce/features/product/presentation/widgets/product_bottom_bar.dart';
import 'package:ecommerce/features/product/presentation/widgets/product_header.dart';
import 'package:ecommerce/features/product/presentation/widgets/product_pricing_row.dart';
import 'package:ecommerce/features/product/presentation/widgets/product_review_tile.dart';
import 'package:ecommerce/features/product/presentation/widgets/product_tabs_selector.dart';
import 'package:ecommerce/features/product/presentation/widgets/product_write_review_section.dart';
import 'package:ecommerce/features/product/utils/variant_selection_helper.dart';

class _ProductPricingDetail {
  final double originalPrice;
  final double finalPrice;
  final int? discountPercentage;

  bool get hasDiscount =>
      originalPrice > 0 &&
      finalPrice < originalPrice &&
      (originalPrice - finalPrice) > 0.001;

  const _ProductPricingDetail({
    required this.originalPrice,
    required this.finalPrice,
    this.discountPercentage,
  });
}

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final ProductModel product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  int _quantity = 1;
  int _selectedTabIndex = 0; // 0: Details/Overview, 1: Reviews
  double _userRating = 5.0;
  Map<String, String> _selectedAttributeValues = {};
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _reviewController = TextEditingController();
  late Future<ProductModel> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  void _loadData() {
    final repo = ProductRepository(ref.read(dioClientProvider));
    _detailsFuture = repo.getProductDetails(widget.product.id);
  }

  void _reconcileSelection(ProductModel loadedProduct) {
    if (_selectedAttributeValues.isEmpty &&
        loadedProduct.attributes.isNotEmpty &&
        loadedProduct.variants.isNotEmpty) {
      _selectedAttributeValues = VariantSelectionHelper.initializeSelection(
        attributes: loadedProduct.attributes,
        variants: loadedProduct.variants,
        defaultVariantId: loadedProduct.defaultVariantId,
      );
    }
  }

  ProductVariantModel? _getResolvedVariant(ProductModel currentProduct) {
    return VariantSelectionHelper.findMatchingVariant(
      currentProduct.variants,
      _selectedAttributeValues,
      currentProduct.attributes.length,
    );
  }

  _ProductPricingDetail _getUnitPricingDetail(ProductModel currentProduct) {
    final variant = _getResolvedVariant(currentProduct);

    if (variant != null) {
      final baseP = variant.pricing.basePrice > 0
          ? variant.pricing.basePrice
          : (variant.price > 0
                ? variant.price
                : currentProduct.priceInfo.originalPrice);
      final finalP = variant.pricing.finalPrice > 0
          ? variant.pricing.finalPrice
          : baseP;

      final diff = baseP - finalP;
      final hasDiscount = baseP > 0 && finalP < baseP && diff > 0.001;
      final discountPct = hasDiscount
          ? (((baseP - finalP) / baseP) * 100).round()
          : null;

      return _ProductPricingDetail(
        originalPrice: baseP,
        finalPrice: finalP,
        discountPercentage: discountPct,
      );
    }

    if (currentProduct.variants.isNotEmpty) {
      final activeVariants = currentProduct.variants
          .where((v) => v.isActive)
          .toList();
      final targetVariant = activeVariants.firstWhere(
        (v) => v.id == currentProduct.defaultVariantId,
        orElse: () => activeVariants.isNotEmpty
            ? activeVariants.first
            : currentProduct.variants.first,
      );

      final baseP = targetVariant.pricing.basePrice > 0
          ? targetVariant.pricing.basePrice
          : (targetVariant.price > 0
                ? targetVariant.price
                : currentProduct.priceInfo.originalPrice);
      final finalP = targetVariant.pricing.finalPrice > 0
          ? targetVariant.pricing.finalPrice
          : baseP;

      final diff = baseP - finalP;
      final hasDiscount = baseP > 0 && finalP < baseP && diff > 0.001;
      final discountPct = hasDiscount
          ? (((baseP - finalP) / baseP) * 100).round()
          : null;

      return _ProductPricingDetail(
        originalPrice: baseP,
        finalPrice: finalP,
        discountPercentage: discountPct,
      );
    }

    // Product without variants
    final baseP = currentProduct.priceInfo.originalPrice;
    final finalP = currentProduct.priceInfo.finalPrice;
    final diff = baseP - finalP;
    final hasDiscount = baseP > 0 && finalP < baseP && diff > 0.001;
    final discountPct = hasDiscount
        ? (currentProduct.priceInfo.discountPercentage?.round() ??
              (((baseP - finalP) / baseP) * 100).round())
        : null;

    return _ProductPricingDetail(
      originalPrice: baseP,
      finalPrice: finalP,
      discountPercentage: discountPct,
    );
  }

  void _showLoginRequiredDialog(BuildContext context, AppStrings strings) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.w(context)),
        ),
        title: Text(strings.loginRequired, style: context.textTheme.titleLarge),
        content: Text(
          strings.loginRequiredDesc,
          style: context.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(strings.cancel, style: context.textTheme.bodyMedium),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(
              strings.signIn,
              style: context.textTheme.whiteLabelLarge,
            ),
          ),
        ],
      ),
    );
  }

  void _openCartTab() {
    ref.read(navigationIndexProvider.notifier).setIndex(2);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _postReview(AppStrings strings) async {
    final token = ref.read(authTokenProvider);
    if (token == null || token.isEmpty) {
      _showLoginRequiredDialog(context, strings);
      return;
    }

    final comment = _reviewController.text.trim();
    final title = _titleController.text.trim();

    if (comment.isEmpty && title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.pleaseEnterTitleOrComment)),
      );
      return;
    }

    try {
      await ref
          .read(productReviewsControllerProvider(widget.product.id).notifier)
          .submitReview(
            rating: _userRating.toInt(),
            title: title.isNotEmpty ? title : null,
            comment: comment.isNotEmpty ? comment : null,
          );
      _reviewController.clear();
      _titleController.clear();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(strings.reviewSubmittedSuccess)));
      }
    } catch (e) {
      if (mounted) {
        String msg = AppErrorUtils.extractErrorMessage(e);
        if (e is DioException && e.response?.statusCode == 403) {
          msg = strings.reviewOnlyPurchased;
        } else if (e is DioException && e.response?.statusCode == 409) {
          msg = strings.reviewAlreadySubmitted;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  Future<void> _addToCart(
    ProductModel currentProduct,
    AppStrings strings,
  ) async {
    final token = ref.read(authTokenProvider);
    if (token == null || token.isEmpty) {
      _showLoginRequiredDialog(context, strings);
      return;
    }

    String? variantId;

    if (currentProduct.attributes.isNotEmpty) {
      final variant = _getResolvedVariant(currentProduct);
      if (variant == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(strings.selectRequiredOptions)));
        return;
      }
      final availableStock = variant.inventory?.availableQuantity ?? 10;
      if (availableStock <= 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(strings.optionOutOfStock)));
        return;
      }
      variantId = variant.id;
    } else {
      variantId =
          currentProduct.defaultVariantId ??
          (currentProduct.variants.isNotEmpty
              ? currentProduct.variants.first.id
              : null);
    }

    if (variantId == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(strings.productUnavailable)));
      }
      return;
    }

    try {
      await ref.read(cartProvider.notifier).addItem(variantId, _quantity);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${strings.addedToCart}: ${currentProduct.name}'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      String errorMessage = strings.errorAddingToCart;
      if (e is DioException && e.response?.data != null) {
        final data = e.response?.data;
        if (data is Map<String, dynamic> && data['message'] != null) {
          errorMessage = data['message'].toString();
        }
      } else if (e is StateError) {
        errorMessage = e.message;
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizationAsync = ref.watch(appLocalizationLoaderProvider);
    final currentLang = ref.watch(languageProvider);
    final strings = AppStrings(localizationAsync.value ?? {}, currentLang);
    final isArabic = strings.isArabic;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tenant = ref.watch(tenantProvider);
    final currencyStr = tenant.currencySymbol.isNotEmpty
        ? tenant.currencySymbol
        : 'KWD';

    final reviewsAsync = ref.watch(
      productReviewsControllerProvider(widget.product.id),
    );

    return FutureBuilder<ProductModel>(
      future: _detailsFuture,
      initialData: widget.product,
      builder: (context, snapshot) {
        final currentProduct = snapshot.data ?? widget.product;
        _reconcileSelection(currentProduct);

        final resolvedVariant = _getResolvedVariant(currentProduct);
        final isCartEnabled =
            currentProduct.attributes.isEmpty ||
            (resolvedVariant != null &&
                (resolvedVariant.inventory?.availableQuantity ?? 10) > 0);

        final unitPricing = _getUnitPricingDetail(currentProduct);
        final formattedTotalPrice = VariantSelectionHelper.formatCurrency(
          unitPricing.finalPrice * _quantity,
          currencyStr,
        );
        final overrideImages = resolvedVariant?.images.isNotEmpty == true
            ? resolvedVariant!.images
            : null;

        return Scaffold(
          backgroundColor: isDark
              ? AppColors.darkBackground
              : AppColors.lightBackground,
          body: Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  ProductHeaderWidget(
                    product: currentProduct,
                    overrideImages: overrideImages,
                    isArabic: isArabic,
                    isDark: isDark,
                    isFavorite:
                        ref
                            .watch(wishlistControllerProvider)
                            .value
                            ?.isFavorite(currentProduct.id) ??
                        currentProduct.isFavorite,
                    onBackPressed: () => Navigator.of(context).pop(),
                    onCartPressed: _openCartTab,
                    onFavoritePressed: () async {
                      final token = ref.read(authTokenProvider);
                      if (token == null || token.isEmpty) {
                        _showLoginRequiredDialog(context, strings);
                        return;
                      }
                      try {
                        await ref
                            .read(wishlistControllerProvider.notifier)
                            .toggleFavorite(currentProduct.id);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppErrorUtils.extractErrorMessage(e),
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        12.w(context),
                        16.h(context),
                        12.w(context),
                        140.h(context),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 6.h(context)),
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: AppColors.starYellow,
                                size: 16.sp(context),
                              ),
                              SizedBox(width: 4.w(context)),
                              Expanded(
                                child: Text(
                                  '${currentProduct.rating} (${currentProduct.reviewCount} ${strings.reviewsCount})',
                                  style: context.textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                strings.freeDelivery,
                                style: context.textTheme.mintTitleSmall,
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h(context)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  currentProduct.name,
                                  style: context.textTheme.titleLarge,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 14.w(context),
                                  vertical: 4.h(context),
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.peach.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    7.w(context),
                                  ),
                                ),
                                child: Text(
                                  strings.inStock,
                                  style: context.textTheme.mintTitleMini
                                      ?.copyWith(color: AppColors.peach),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 16.h(context)),

                          // Product Main Price Section (Unit Price)
                          ProductPricingRow(
                            finalPrice: unitPricing.finalPrice,
                            originalPrice: unitPricing.originalPrice,
                            hasDiscount: unitPricing.hasDiscount,
                            discountPercentage: unitPricing.discountPercentage,
                            currencyStr: currencyStr,
                          ),
                          SizedBox(height: 20.h(context)),

                          // Tab Selector (Details vs Reviews)
                          ProductTabsSelector(
                            selectedTabIndex: _selectedTabIndex,
                            reviewCount: currentProduct.reviewCount,
                            isDark: isDark,
                            strings: strings,
                            onTabSelected: (index) =>
                                setState(() => _selectedTabIndex = index),
                          ),

                          // Tab Content
                          if (_selectedTabIndex == 0) ...[
                            ProductAttributesWidget(
                              product: currentProduct,
                              selectedAttributeValues: _selectedAttributeValues,
                              onAttributeSelected: (attrId, valId) {
                                setState(() {
                                  _selectedAttributeValues =
                                      VariantSelectionHelper.selectValue(
                                        targetAttributeId: attrId,
                                        selectedValueId: valId,
                                        attributes: currentProduct.attributes,
                                        variants: currentProduct.variants,
                                        currentSelection:
                                            _selectedAttributeValues,
                                      );
                                });
                              },
                              isDark: isDark,
                            ),
                            SizedBox(height: 20.h(context)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  strings.quantityLabel,
                                  style: context.textTheme.titleMedium,
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w(context),
                                    vertical: 6.h(context),
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkCardBg
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(
                                      20.w(context),
                                    ),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          if (_quantity > 1) {
                                            setState(() => _quantity--);
                                          }
                                        },
                                        child: const Icon(
                                          Icons.remove,
                                          size: 18,
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16.w(context),
                                        ),
                                        child: Text(
                                          '$_quantity',
                                          style: context.textTheme.titleMedium,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          final variant = _getResolvedVariant(
                                            currentProduct,
                                          );
                                          final maxStock =
                                              variant
                                                  ?.inventory
                                                  ?.availableQuantity ??
                                              10;
                                          if (_quantity < maxStock) {
                                            setState(() => _quantity++);
                                          }
                                        },
                                        child: const Icon(Icons.add, size: 18),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 24.h(context)),
                            Text(
                              strings.description,
                              style: context.textTheme.titleMedium,
                            ),
                            SizedBox(height: 8.h(context)),
                            Text(
                              currentProduct.description.isNotEmpty
                                  ? currentProduct.description
                                  : strings.defaultProductDescription,
                              style: context.textTheme.bodyMedium,
                            ),
                          ] else ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  strings.reviewsHeader,
                                  style: context.textTheme.titleMedium,
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => AllReviewsScreen(
                                          product: currentProduct,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    strings.readMore,
                                    style: context.textTheme.primaryTitleSmall,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12.h(context)),
                            reviewsAsync.when(
                              data: (paginatedState) {
                                final reviews = paginatedState.items;
                                if (reviews.isEmpty) {
                                  return Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 20.h(context),
                                      ),
                                      child: Text(
                                        strings.noReviewsBeFirst,
                                        style: context.textTheme.labelMedium,
                                      ),
                                    ),
                                  );
                                }
                                final review = reviews.first;
                                return ProductReviewTile(
                                  name: review.user.name,
                                  date: review.createdAt.contains('T')
                                      ? review.createdAt.split('T').first
                                      : review.createdAt,
                                  rating: review.rating,
                                  title: review.title,
                                  comment: review.comment ?? '',
                                );
                              },
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              error: (e, st) => Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      strings.failedToLoadReviews,
                                      style: context.textTheme.redTitleSmall,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => ref.invalidate(
                                      productReviewsControllerProvider(
                                        widget.product.id,
                                      ),
                                    ),
                                    child: Text(strings.retry),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 24.h(context)),
                            ProductWriteReviewSection(
                              userRating: _userRating,
                              titleController: _titleController,
                              reviewController: _reviewController,
                              strings: strings,
                              onRatingChanged: (r) =>
                                  setState(() => _userRating = r),
                              onSubmitReview: () => _postReview(strings),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              ProductBottomBarWidget(
                product: currentProduct,
                formattedTotalPrice: formattedTotalPrice,
                quantity: _quantity,
                isDark: isDark,
                isEnabled: isCartEnabled,
                onAddToCartPressed: () => _addToCart(currentProduct, strings),
              ),
            ],
          ),
        );
      },
    );
  }
}
