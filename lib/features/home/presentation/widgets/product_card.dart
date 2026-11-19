import 'package:ecommerce/core/constants/app_assets.dart';
import 'package:ecommerce/core/widgets/app_price_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:ecommerce/core/config/tenant_config.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/utils/app_error_utils.dart';
import 'package:ecommerce/core/widgets/app_image_container.dart';
import 'package:ecommerce/core/widgets/app_image_placeholder.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/features/auth/presentation/screens/login_screen.dart';
import 'package:ecommerce/features/cart/presentation/providers/cart_provider.dart';
import 'package:ecommerce/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:ecommerce/features/product/presentation/screens/product_details_screen.dart';
import 'package:flutter_svg/svg.dart';
import '../../models/home_response_model.dart';

class ProductCard extends ConsumerStatefulWidget {
  final ProductModel product;
  final VoidCallback onFavoriteTap;
  final VoidCallback onAddTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.onFavoriteTap,
    required this.onAddTap,
  });

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard> {
  void _showLoginRequiredDialog(BuildContext context, AppStrings strings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.cancel, style: context.textTheme.bodyMedium),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
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

  Future<void> _handleAddToCart(
    BuildContext context,
    AppStrings strings,
  ) async {
    final token = ref.read(authTokenProvider);
    final isLoggedIn = token != null && token.isNotEmpty;

    if (!isLoggedIn) {
      _showLoginRequiredDialog(context, strings);
      return;
    }

    final variantId =
        widget.product.defaultVariantId ??
        (widget.product.variants.isNotEmpty
            ? widget.product.variants.first.id
            : null);

    if (widget.product.hasVariants || variantId == null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductDetailsScreen(product: widget.product),
        ),
      );
      return;
    }

    try {
      await ref.read(cartProvider.notifier).addItem(variantId, 1);
      widget.onAddTap();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              strings
                  .get('added_to_cart_item')
                  .replaceAll('{productName}', widget.product.name),
            ),
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
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    }
  }

  Future<void> _handleFavoriteToggle(
    BuildContext context,
    AppStrings strings,
  ) async {
    final token = ref.read(authTokenProvider);
    final isLoggedIn = token != null && token.isNotEmpty;

    if (!isLoggedIn) {
      _showLoginRequiredDialog(context, strings);
      return;
    }

    try {
      await ref
          .read(wishlistControllerProvider.notifier)
          .toggleFavorite(widget.product.id);
      widget.onFavoriteTap();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppErrorUtils.extractErrorMessage(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizationAsync = ref.watch(appLocalizationLoaderProvider);
    final currentLang = ref.watch(languageProvider);
    final strings = AppStrings(localizationAsync.value ?? {}, currentLang);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tenant = ref.watch(tenantProvider);
    final currencyStr = tenant.currencySymbol.isNotEmpty
        ? tenant.currencySymbol
        : '\$';

    final wishlistData = ref.watch(wishlistControllerProvider).value;
    final isFavorite =
        wishlistData?.isFavorite(widget.product.id) ??
        widget.product.isFavorite;

    final origPrice = widget.product.priceInfo.originalPrice;
    final finalPrice = widget.product.priceInfo.finalPrice;
    final discountPctVal =
        widget.product.priceInfo.discountPercentage?.round() ??
        (origPrice > finalPrice && origPrice > 0
            ? (((origPrice - finalPrice) / origPrice) * 100).round()
            : 0);

    final hasDiscount =
        discountPctVal > 0 &&
        origPrice > finalPrice &&
        (origPrice - finalPrice) > 0.001;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(product: widget.product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
          borderRadius: BorderRadius.circular(24.w(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: Offset(0, 4.h(context)),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  AppImageContainer(
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24.w(context)),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: widget.product.image,
                      fit: BoxFit.cover,
                      httpHeaders: const {
                        'User-Agent':
                            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                      },
                      placeholder: (context, url) =>
                          const AppImagePlaceholder(),
                      errorWidget: (context, url, error) =>
                          const AppImagePlaceholder(
                            icon: Icons.broken_image_outlined,
                          ),
                    ),
                  ),
                  if (hasDiscount)
                    Positioned(
                      top: 12.h(context),
                      left: strings.isArabic ? null : 12.w(context),
                      right: strings.isArabic ? 12.w(context) : null,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w(context),
                          vertical: 4.h(context),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8.w(context)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 4,
                              offset: Offset(0, 2.h(context)),
                            ),
                          ],
                        ),
                        child: Text(
                          '$discountPctVal% OFF',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp(context),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 12.h(context),
                    right: strings.isArabic ? null : 12.w(context),
                    left: strings.isArabic ? 12.w(context) : null,
                    child: GestureDetector(
                      onTap: () => _handleFavoriteToggle(context, strings),
                      child: Container(
                        width: 34.w(context),
                        height: 34.w(context),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurface
                              : AppColors.darkBkg,
                          shape: BoxShape.circle,
                          // boxShadow: const [
                          //   BoxShadow(
                          //     color: Colors.black12,
                          //     blurRadius: 6,
                          //     offset: Offset(0, 2),
                          //   ),
                          // ],
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite
                              ? AppColors.badgeRed
                              : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary),
                          size: 18.sp(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(14.w(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleSmall,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: AppPriceTextRow(
                                price: widget.product.priceInfo.finalPrice,
                                currency: currencyStr,
                              ),
                            ),
                            if (hasDiscount) ...[
                              SizedBox(height: 2.h(context)),
                              AppPriceTextRow(
                                price: '${widget.product.priceInfo.originalPrice.toStringAsFixed(2)} $currencyStr',
                                priceStyle: context.textTheme.strikeThroughBodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(width: 4.w(context)),
                      GestureDetector(
                        onTap: () => _handleAddToCart(context, strings),
                        child: Container(
                          width: 33.w(context),
                          height: 33.w(context),
                          padding: EdgeInsets.all(10.w(context)),
                          decoration: BoxDecoration(
                            color: AppColors.darkBkg,
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(10.h(context)),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: Offset(0, 3.h(context)),
                              ),
                            ],
                          ),
                          child: SvgPicture.asset(
                            AppAssets.cartAddSvg,
                            colorFilter: const ColorFilter.mode(
                              AppColors.primary,
                              BlendMode.srcIn,
                            ),
                            width: 14.sp(context),
                            height: 14.sp(context),
                          ),
                        ),
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
