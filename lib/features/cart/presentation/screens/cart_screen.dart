import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/config/tenant_config.dart';
import 'package:ecommerce/core/constants/app_assets.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/app_error_utils.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/widgets/app_empty_widget.dart';
import 'package:ecommerce/core/widgets/app_error_widget.dart';
import 'package:ecommerce/core/widgets/app_unauth_widget.dart';
import 'package:ecommerce/features/cart/presentation/providers/cart_provider.dart';
import 'package:ecommerce/features/cart/presentation/widgets/cart_bottom_action_bar.dart';
import 'package:ecommerce/features/cart/presentation/widgets/cart_cross_sell_section.dart';
import 'package:ecommerce/features/cart/presentation/widgets/cart_delivery_notice_banner.dart';
import 'package:ecommerce/features/cart/presentation/widgets/cart_header_row.dart';
import 'package:ecommerce/features/cart/presentation/widgets/cart_items_list_view.dart';
import 'package:ecommerce/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:ecommerce/features/home/presentation/providers/home_provider.dart';
import 'package:ecommerce/features/main_shell_screen.dart';
import 'package:ecommerce/features/product/data/product_repository.dart';
import 'package:ecommerce/features/product/presentation/screens/product_details_screen.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

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
    final token = ref.watch(authTokenProvider);
    final isLoggedIn = token != null && token.isNotEmpty;
    final cartAsync = ref.watch(cartProvider);
    final homeDataAsync = ref.watch(homeDataProvider);
    final localizationAsync = ref.watch(appLocalizationLoaderProvider);
    final currentLang = ref.watch(languageProvider);
    final strings = AppStrings(localizationAsync.value ?? {}, currentLang);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tenant = ref.watch(tenantProvider);
    final currencyStr = tenant.currencySymbol.isNotEmpty
        ? tenant.currencySymbol
        : 'KWD';

    if (!isLoggedIn) {
      return AppUnauthWidget(
        screenTitle: strings.cart,
        description: strings.loginRequiredCartDesc,
      );
    }

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : const Color(0xFFF8F4EE),
      body: SafeArea(
        child: cartAsync.when(
          data: (cart) {
            if (cart.items.isEmpty) {
              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      20.w(context),
                      16.h(context),
                      20.w(context),
                      12.h(context),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          strings.cart,
                          style: context.textTheme.displayLarge,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: AppEmptyWidget(
                      title: strings.cartIsEmpty,
                      svgAsset: AppAssets.shoppingCartSVG,
                      actionText: strings.shopNow,
                      onActionPressed: () {
                        ref.read(navigationIndexProvider.notifier).setIndex(0);
                      },
                    ),
                  ),
                ],
              );
            }

            final totalItems = cart.itemCount;
            final uniqueProductsCount = cart.items.length;

            return Stack(
              children: [
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    20.w(context),
                    16.h(context),
                    20.w(context),
                    140.h(context),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      CartHeaderRow(
                        totalItems: totalItems,
                        uniqueProductsCount: uniqueProductsCount,
                        strings: strings,
                        onClearCart: () async {
                          try {
                            await ref.read(cartProvider.notifier).clearCart();
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(strings.failedToClearCart),
                                ),
                              );
                            }
                          }
                        },
                      ),

                      SizedBox(height: 16.h(context)),

                      // Cart Items List
                      CartItemsListView(
                        items: cart.items,
                        currencyStr: currencyStr,
                        strings: strings,
                        isDark: isDark,
                        onNavigateToDetails: (productId) =>
                            _navigateToDetails(ref, context, productId),
                      ),

                      SizedBox(height: 10.h(context)),

                      // Cross-Sell Carousel ("You may also like")
                      CartCrossSellSection(
                        homeDataAsync: homeDataAsync,
                        currencyStr: currencyStr,
                        strings: strings,
                        onNavigateToDetails: (productId) =>
                            _navigateToDetails(ref, context, productId),
                      ),

                      // Delivery Guarantee Banner
                      CartDeliveryNoticeBanner(
                        strings: strings,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),

                // Sticky Bottom Bar
                CartBottomActionBar(
                  cart: cart,
                  totalItems: totalItems,
                  currencyStr: currencyStr,
                  strings: strings,
                  isDark: isDark,
                  onCheckout: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                    );
                  },
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => AppErrorWidget(
            message: strings.failedToLoadCart,
            onRetry: () => ref.read(cartProvider.notifier).refreshCart(),
          ),
        ),
      ),
    );
  }
}
