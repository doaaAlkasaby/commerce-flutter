import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/widgets/app_button.dart';
import 'package:ecommerce/features/cart/presentation/providers/cart_provider.dart';
import 'package:ecommerce/features/checkout/presentation/screens/checkout_screen.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartProvider);
    final localizationAsync = ref.watch(appLocalizationLoaderProvider);
    final currentLang = ref.watch(languageProvider);
    final strings = AppStrings(localizationAsync.value ?? {}, currentLang);
    final isArabic = currentLang == AppLanguage.ar;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        elevation: 0,
        title: Text(
          strings.cart,
          style: context.textTheme.titleLarge?.copyWith(
                fontSize: 22.sp(context),
              ),
        ),
      ),
      body: cartAsync.when(
        data: (cart) {
          if (cart.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64.sp(context), color: AppColors.lightTextSecondary),
                  SizedBox(height: 16.h(context)),
                  Text(
                    isArabic ? 'سلة التسوق فارغة' : 'Your cart is empty',
                    style: context.textTheme.boldTitleLarge?.copyWith(fontSize: 18.sp(context)),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.all(20.w(context)),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    final imageUrl = item.variant.images.isNotEmpty ? item.variant.images.first.url : '';
                    return Container(
                      margin: EdgeInsets.only(bottom: 16.h(context)),
                      padding: EdgeInsets.all(12.w(context)),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCardBg : Colors.white,
                        borderRadius: BorderRadius.circular(20.w(context)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: Offset(0, 4.h(context)),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16.w(context)),
                            child: SizedBox(
                              width: 76.w(context),
                              height: 76.h(context),
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) => const Icon(Icons.image_not_supported_outlined),
                              ),
                            ),
                          ),
                          SizedBox(width: 14.w(context)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.variant.product.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.textTheme.boldTitleMedium?.copyWith(
                                        fontSize: 15.sp(context),
                                      ),
                                ),
                                SizedBox(height: 4.h(context)),
                                Text(
                                  '\$${item.finalUnitPrice} each',
                                  style: context.textTheme.bodySmall?.copyWith(
                                        fontSize: 13.sp(context),
                                        color: AppColors.lightTextSecondary,
                                      ),
                                ),
                                SizedBox(height: 2.h(context)),
                                Text(
                                  'Subtotal: \$${item.totalPrice}',
                                  style: context.textTheme.boldTitleSmall?.copyWith(
                                        fontSize: 14.sp(context),
                                        color: AppColors.primary,
                                      ),
                                ),
                                SizedBox(height: 8.h(context)),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        if (item.quantity > 1) {
                                          ref.read(cartProvider.notifier).updateQuantity(item.variantId, item.quantity - 1);
                                        } else {
                                          ref.read(cartProvider.notifier).deleteItem(item.variantId);
                                        }
                                      },
                                      child: Container(
                                        width: 28.w(context),
                                        height: 28.w(context),
                                        decoration: BoxDecoration(
                                          color: AppColors.lightBackground,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.grey.shade300),
                                        ),
                                        child: const Icon(Icons.remove, size: 14),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 12.w(context)),
                                      child: Text('${item.quantity}', style: context.textTheme.boldTitleMedium?.copyWith(fontSize: 14.sp(context))),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        ref.read(cartProvider.notifier).updateQuantity(item.variantId, item.quantity + 1);
                                      },
                                      child: Container(
                                        width: 28.w(context),
                                        height: 28.w(context),
                                        decoration: BoxDecoration(
                                          color: AppColors.lightBackground,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.grey.shade300),
                                        ),
                                        child: const Icon(Icons.add, size: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.badgeRed),
                            onPressed: () {
                              ref.read(cartProvider.notifier).deleteItem(item.variantId);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: EdgeInsets.all(24.w(context)),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: Offset(0, -4.h(context)),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(strings.total, style: context.textTheme.boldTitleMedium?.copyWith(fontSize: 14.sp(context), color: AppColors.lightTextSecondary)),
                        Text(
                          '\$${cart.subtotal}',
                          style: context.textTheme.displayMedium?.copyWith(fontSize: 22.sp(context), color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h(context)),
                    AppButton(
                      text: strings.checkout,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
