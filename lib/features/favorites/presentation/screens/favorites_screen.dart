import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/widgets/app_button.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/features/favorites/data/favorites_repository.dart';
import '../../../home/models/home_response_model.dart';
import 'package:ecommerce/features/product/presentation/screens/product_details_screen.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  late Future<List<ProductModel>> _wishlistFuture;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  void _loadWishlist() {
    _wishlistFuture = FavoritesRepository(
      ref.read(dioClientProvider),
    ).getWishlist();
  }

  Future<void> _removeItem(ProductModel product, AppStrings strings) async {
    try {
      final repo = FavoritesRepository(ref.read(dioClientProvider));
      await repo.removeFromWishlist(product.id);
      setState(() {
        _loadWishlist();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.removedFromFavorites),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
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

  @override
  Widget build(BuildContext context) {
    final localizationAsync = ref.watch(appLocalizationLoaderProvider);
    final currentLang = ref.watch(languageProvider);
    final strings = AppStrings(localizationAsync.value ?? {}, currentLang);
    final isArabic = currentLang == AppLanguage.ar;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                isArabic ? Icons.arrow_forward_ios : Icons.arrow_back_ios_new,
                size: 16.sp(context),
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: Text(
          strings.favorites,
          style: context.textTheme.titleLarge?.copyWith(
            fontSize: 20.sp(context),
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
      ),
      body: FutureBuilder<List<ProductModel>>(
        future: _wishlistFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final favorites = snapshot.data ?? [];

          if (favorites.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24.w(context)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 110.w(context),
                      height: 110.h(context),
                      decoration: BoxDecoration(
                        color: AppColors.peach.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.favorite_border,
                            size: 48.sp(context),
                            color: AppColors.primary,
                          ),
                          Positioned(
                            top: 24.h(context),
                            right: 28.w(context),
                            child: Container(
                              width: 8.w(context),
                              height: 8.h(context),
                              decoration: const BoxDecoration(
                                color: AppColors.starYellow,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h(context)),
                    Text(
                      strings.noFavoritesYet,
                      style: context.textTheme.headlineSmall?.copyWith(
                        fontSize: 22.sp(context),
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    SizedBox(height: 8.h(context)),
                    Text(
                      strings.tapTheHeart,
                      textAlign: TextAlign.center,
                      style: context.textTheme.addressBody?.copyWith(
                        fontSize: 14.sp(context),
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                    SizedBox(height: 32.h(context)),
                    SizedBox(
                      width: 240.w(context),
                      height: 52.h(context),
                      child: AppButton(
                        text: strings.browseTheShop,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    SizedBox(height: 16.h(context)),
                    Text(
                      strings.syncDevices,
                      style: context.textTheme.bodySmall?.copyWith(
                        fontSize: 11.sp(context),
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return GridView.builder(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.all(20.w(context)),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 16.w(context),
              mainAxisSpacing: 16.h(context),
            ),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final product = favorites[index];
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProductDetailsScreen(product: product),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardBg : Colors.white,
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
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkCategoryBg
                                    : AppColors.lightCategoryBg,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(24.w(context)),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(24.w(context)),
                                ),
                                child: CachedNetworkImage(
                                  imageUrl: product.image,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) =>
                                      const Icon(
                                        Icons.image_not_supported_outlined,
                                      ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 10.h(context),
                              right: 10.w(context),
                              child: GestureDetector(
                                onTap: () => _removeItem(product, strings),
                                child: Container(
                                  width: 30.w(context),
                                  height: 30.w(context),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkSurface
                                        : Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    size: 16.sp(context),
                                    color: AppColors.lightTextSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(12.w(context)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.boldTitleMedium
                                  ?.copyWith(
                                    fontSize: 14.sp(context),
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                            ),
                            SizedBox(height: 8.h(context)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '\$${product.priceInfo.finalPrice.toStringAsFixed(2)}',
                                      style: context.textTheme.boldTitleMedium
                                          ?.copyWith(
                                            fontSize: 15.sp(context),
                                            color: isDark
                                                ? AppColors.darkTextPrimary
                                                : AppColors.lightTextPrimary,
                                          ),
                                    ),
                                    if (product.priceInfo.discountPercentage !=
                                        null) ...[
                                      SizedBox(height: 2.h(context)),
                                      Text(
                                        '\$${product.priceInfo.originalPrice.toStringAsFixed(2)}',
                                        style: context.textTheme.bodySmall
                                            ?.copyWith(
                                              fontSize: 11.sp(context),
                                              decoration:
                                                  TextDecoration.lineThrough,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                                Container(
                                  width: 34.w(context),
                                  height: 34.w(context),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 6,
                                        offset: Offset(0, 3.h(context)),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 18.sp(context),
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
            },
          );
        },
      ),
    );
  }
}
