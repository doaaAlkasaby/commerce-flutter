import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/app_error_utils.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/widgets/app_empty_widget.dart';
import 'package:ecommerce/core/widgets/app_error_widget.dart';
import 'package:ecommerce/features/favorites/data/favorites_repository.dart';
import 'package:ecommerce/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:ecommerce/features/product/data/product_repository.dart';
import 'package:ecommerce/features/product/presentation/screens/product_details_screen.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../main_shell_screen.dart';
import '../widgets/favorite_item_card.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  Future<void> _removeItem(
    WidgetRef ref,
    BuildContext context,
    WishlistItemModel item,
    AppStrings strings,
  ) async {
    try {
      await ref
          .read(wishlistControllerProvider.notifier)
          .toggleFavorite(item.product.id);
      if (context.mounted) {
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppErrorUtils.extractErrorMessage(e))),
        );
      }
    }
  }

  Future<void> _navigateToDetails(
    WidgetRef ref,
    BuildContext context,
    String productId,
  ) async {
    try {
      final repo = ProductRepository(ref.read(dioClientProvider));
      final fullProduct = await repo.getProductDetails(productId);
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(product: fullProduct),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppErrorUtils.extractErrorMessage(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizationAsync = ref.watch(appLocalizationLoaderProvider);
    final currentLang = ref.watch(languageProvider);
    final strings = AppStrings(localizationAsync.value ?? {}, currentLang);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final wishlistAsync = ref.watch(wishlistControllerProvider);

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
        title: Text(strings.favorites, style: context.textTheme.titleLarge),
      ),
      body: wishlistAsync.when(
        data: (wishlistState) {
          final items = wishlistState.items;

          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                await ref.read(wishlistControllerProvider.notifier).refresh();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                children: [
                  SizedBox(height: 80.h(context)),
                  AppEmptyWidget(
                    title: strings.noFavoritesYet,
                    subtitle: strings.tapTheHeart,
                    pngAsset: AppAssets.favorites,
                    actionText: strings.browseTheShop,
                    size: 100.w(context),
                    onActionPressed: () {
                      Navigator.of(context).pop();
                      ref.read(navigationIndexProvider.notifier).setIndex(0);
                    },
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(wishlistControllerProvider.notifier).refresh();
            },
            child: GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.all(20.w(context)),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 16.w(context),
                mainAxisSpacing: 16.h(context),
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];

                return FavoriteItemCard(
                  item: item,
                  isDark: isDark,
                  onTap: () =>
                      _navigateToDetails(ref, context, item.product.id),
                  onRemove: () => _removeItem(ref, context, item, strings),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => AppErrorWidget(
          message: strings.failedToLoadWishlist,
          onRetry: () => ref.invalidate(wishlistControllerProvider),
        ),
      ),
    );
  }
}
