import 'package:ecommerce/core/widgets/app_price_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/constants/app_assets.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/widgets/app_button.dart';
import 'package:ecommerce/features/home/models/home_response_model.dart';

class ProductBottomBarWidget extends ConsumerWidget {
  final ProductModel product;
  final String formattedTotalPrice;
  final int quantity;
  final bool isDark;
  final bool isEnabled;
  final VoidCallback onAddToCartPressed;

  const ProductBottomBarWidget({
    super.key,
    required this.product,
    required this.formattedTotalPrice,
    required this.quantity,
    required this.isDark,
    this.isEnabled = true,
    required this.onAddToCartPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(languageProvider);
    final localizationAsync = ref.watch(appLocalizationLoaderProvider);
    final strings = AppStrings(localizationAsync.value ?? {}, currentLang);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          16.w(context),
          16.h(context),
          16.w(context),
          28.h(context),
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: Offset(0, -6.h(context)),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    strings.totalUppercase,
                    style: context.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5.h(context)),
                  AppPriceTextRow(
                    price: formattedTotalPrice,
                    currency: "",
                    isLarge: true,
                    // style: context.textTheme.primaryDisplayMedium,
                  ),
                ],
              ),
            ),
            SizedBox(width: 20.w(context)),
            Expanded(
              child: AppButton(
                text: strings.addToCartBtn,
                height: 45.h(context),
                onPressed: isEnabled ? onAddToCartPressed : null,
                svg: AppAssets.cartAddSvg,
                textColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
