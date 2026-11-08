import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/core/widgets/app_button.dart';
import 'package:ecommerce/core/widgets/app_text_field.dart';
import 'package:ecommerce/features/home/models/home_response_model.dart';
import 'package:ecommerce/features/product/data/product_repository.dart';
import 'package:ecommerce/features/product/presentation/widgets/product_header.dart';
import 'package:ecommerce/features/product/presentation/widgets/product_bottom_bar.dart';
import 'package:ecommerce/features/product/presentation/widgets/product_attributes.dart';
import 'package:ecommerce/features/product/presentation/widgets/product_variants.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final ProductModel product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  int _quantity = 1;
  double _userRating = 5.0;
  bool _isFavorite = false;
  ProductVariantModel? _selectedVariant;
  String _selectedColor = '';
  String _selectedSize = '';
  final TextEditingController _reviewController = TextEditingController();
  late Future<ProductModel> _detailsFuture;
  late Future<List<Map<String, dynamic>>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.product.isFavorite;
    if (widget.product.variants.isNotEmpty) {
      _selectedVariant = widget.product.variants.first;
    }
    _loadData();
  }

  void _loadData() {
    final repo = ProductRepository(ref.read(dioClientProvider));
    _detailsFuture = repo.getProductDetails(widget.product.id);
    _reviewsFuture = repo.getProductReviews(widget.product.id);
  }

  Future<void> _handleFavoriteToggle() async {
    final token = ref.read(authTokenProvider);
    final isLoggedIn = token != null && token.isNotEmpty;
    if (!isLoggedIn) return;

    setState(() {
      _isFavorite = !_isFavorite;
    });

    try {
      final repo = ProductRepository(ref.read(dioClientProvider));
      await repo.toggleFavorite(widget.product.id, _isFavorite);
    } catch (_) {
      setState(() {
        _isFavorite = !_isFavorite;
      });
    }
  }

  Future<void> _postReview(AppStrings strings) async {
    if (_reviewController.text.trim().isEmpty) return;
    try {
      final repo = ProductRepository(ref.read(dioClientProvider));
      await repo.addReview(
        widget.product.id,
        _userRating,
        _reviewController.text.trim(),
      );
      _reviewController.clear();
      setState(() {
        _loadData();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review posted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _addToCart(
    ProductModel currentProduct,
    AppStrings strings,
  ) async {
    try {
      final repo = ProductRepository(ref.read(dioClientProvider));
      final variantId =
          _selectedVariant?.id ??
          currentProduct.defaultVariantId ??
          currentProduct.id;
      await repo.addToCart(variantId, _quantity);
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding to cart: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizationAsync = ref.watch(appLocalizationLoaderProvider);
    final currentLang = ref.watch(languageProvider);
    final strings = AppStrings(localizationAsync.value ?? {}, currentLang);
    final isArabic = currentLang == AppLanguage.ar;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<ProductModel>(
      future: _detailsFuture,
      initialData: widget.product,
      builder: (context, snapshot) {
        final currentProduct = snapshot.data ?? widget.product;

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
                    isArabic: isArabic,
                    isDark: isDark,
                    isFavorite: _isFavorite,
                    onBackPressed: () => Navigator.of(context).pop(),
                    onFavoritePressed: () => _handleFavoriteToggle(),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        20.w(context),
                        16.h(context),
                        20.w(context),
                        140.h(context),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  currentProduct.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .displaySmall
                                      ?.copyWith(
                                        fontSize: 22.sp(context),
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.lightTextPrimary,
                                      ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w(context),
                                  vertical: 4.h(context),
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.mintTeal.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    10.w(context),
                                  ),
                                ),
                                child: Text(
                                  strings.inStock,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        fontSize: 11.sp(context),
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.mintTeal,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6.h(context)),
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: AppColors.starYellow,
                                size: 16.sp(context),
                              ),
                              SizedBox(width: 4.w(context)),
                              Text(
                                '${currentProduct.rating} (${currentProduct.reviewCount} reviews)',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontSize: 13.sp(context)),
                              ),
                              Text(
                                strings.freeDelivery,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(fontSize: 12.sp(context)),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h(context)),
                          Row(
                            children: [
                              Text(
                                '\$${currentProduct.priceInfo.finalPrice.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.displayMedium
                                    ?.copyWith(
                                      fontSize: 24.sp(context),
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary,
                                    ),
                              ),
                              if (currentProduct.priceInfo.discountPercentage !=
                                  null) ...[
                                SizedBox(width: 10.w(context)),
                                Text(
                                  '\$${currentProduct.priceInfo.originalPrice.toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        fontSize: 14.sp(context),
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 20.h(context)),
                          Text(
                            strings.colour,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontSize: 15.sp(context),
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          SizedBox(height: 10.h(context)),
                          ProductVariantsWidget(
                            product: currentProduct,
                            selectedVariant: _selectedVariant,
                            isDark: isDark,
                          ),
                          SizedBox(height: 20.h(context)),
                          Text(
                            strings.size,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontSize: 15.sp(context),
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          SizedBox(height: 10.h(context)),
                          ProductAttributesWidget(
                            product: currentProduct,
                            selectedColor: _selectedColor,
                            selectedSize: _selectedSize,
                            onColorSelected: (c) =>
                                setState(() => _selectedColor = c),
                            onSizeSelected: (s) =>
                                setState(() => _selectedSize = s),
                            isDark: isDark,
                          ),
                          SizedBox(height: 20.h(context)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Quantity',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontSize: 15.sp(context),
                                      fontWeight: FontWeight.bold,
                                    ),
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
                                      child: const Icon(Icons.remove, size: 18),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16.w(context),
                                      ),
                                      child: Text(
                                        '$_quantity',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => setState(() => _quantity++),
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
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontSize: 18.sp(context),
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          SizedBox(height: 8.h(context)),
                          Text(
                            currentProduct.description.isNotEmpty
                                ? currentProduct.description
                                : 'High quality crafted item designed with care for your little ones. Made from sustainable and safe materials.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontSize: 14.sp(context),
                                  height: 1.5,
                                ),
                          ),
                          Divider(height: 36.h(context)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                strings.reviewsHeader,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontSize: 18.sp(context),
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              TextButton(
                                onPressed: () {},
                                child: Text(
                                  strings.readMore,
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h(context)),
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: _reviewsFuture,
                            builder: (context, snapshot) {
                              final reviews = snapshot.data ?? [];
                              if (reviews.isEmpty) {
                                return Text(
                                  'No reviews yet. Be the first to review!',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(fontSize: 13.sp(context)),
                                );
                              }
                              return Column(
                                children: reviews.map((rev) {
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: 12.h(context),
                                    ),
                                    child: _buildReviewItem(
                                      context: context,
                                      name:
                                          rev['userName']?.toString() ??
                                          'Parent',
                                      date: 'Recent',
                                      rating:
                                          (rev['rating'] as num?)?.toInt() ?? 5,
                                      comment: rev['comment']?.toString() ?? '',
                                      helpfulCount: 0,
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                          SizedBox(height: 20.h(context)),
                          AppButton(
                            text: strings.seeAllReviews,
                            onPressed: () {},
                            type: AppButtonType.outlined,
                            height: 48.h(context),
                          ),
                          Divider(height: 36.h(context)),
                          Text(
                            strings.writeReview,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontSize: 18.sp(context),
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          SizedBox(height: 12.h(context)),
                          Text(
                            strings.yourRating,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.lightTextSecondary,
                                  fontSize: 13.sp(context),
                                ),
                          ),
                          SizedBox(height: 8.h(context)),
                          Row(
                            children: List.generate(5, (index) {
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _userRating = index + 1.0),
                                child: Icon(
                                  index < _userRating
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: AppColors.starYellow,
                                  size: 28.sp(context),
                                ),
                              );
                            }),
                          ),
                          SizedBox(height: 12.h(context)),
                          AppTextField(
                            controller: _reviewController,
                            hintText: strings.tellParents,
                            maxLines: 4,
                          ),
                          SizedBox(height: 12.h(context)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              AppButton(
                                text: strings.addPhoto,
                                onPressed: () {},
                                type: AppButtonType.outlined,
                                height: 40.h(context),
                                icon: Icons.camera_alt_outlined,
                                width: 140.w(context),
                              ),
                              Text(
                                '0/500',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppColors.lightTextSecondary,
                                      fontSize: 12.sp(context),
                                    ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h(context)),
                          AppButton(
                            text: strings.postReview,
                            onPressed: () => _postReview(strings),
                            height: 50.h(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              ProductBottomBarWidget(
                product: currentProduct,
                quantity: _quantity,
                isDark: isDark,
                onAddToCartPressed: () => _addToCart(currentProduct, strings),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviewItem({
    required BuildContext context,
    required String name,
    required String date,
    required int rating,
    required String comment,
    required int helpfulCount,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(16.w(context)),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(20.w(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: Offset(0, 2.h(context)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 14.sp(context),
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              Text(
                date,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontSize: 11.sp(context)),
              ),
            ],
          ),
          SizedBox(height: 6.h(context)),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < rating ? Icons.star : Icons.star_border,
                color: AppColors.starYellow,
                size: 14.sp(context),
              );
            }),
          ),
          SizedBox(height: 8.h(context)),
          Text(
            comment,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 13.sp(context),
              height: 1.4,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
