import 'package:flutter/material.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/widgets/app_button.dart';
import 'package:ecommerce/core/widgets/app_price_text.dart';
import 'package:ecommerce/features/cart/models/cart_model.dart';

class CartBottomActionBar extends StatelessWidget {
  final CartModel cart;
  final int totalItems;
  final String currencyStr;
  final AppStrings strings;
  final bool isDark;
  final VoidCallback onCheckout;

  const CartBottomActionBar({
    super.key,
    required this.cart,
    required this.totalItems,
    required this.currencyStr,
    required this.strings,
    required this.isDark,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          20.w(context),
          14.h(context),
          20.w(context),
          24.h(context),
        ),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${strings.total} · $totalItems ${strings.items}',
                      style: context.textTheme.titleSmall?.copyWith(
                        letterSpacing: 0.8,
                      ),
                    ),
                    SizedBox(height: 2.h(context)),
                    Text(
                      strings.deliveryAddedAtCheckout,
                      style: context.textTheme.labelSmall,
                    ),
                  ],
                ),
                AppPriceTextColumn(
                  price: cart.subtotal,
                  currency: currencyStr,
                  isLarge: true,
                ),
              ],
            ),
            SizedBox(height: 12.h(context)),
            AppButton(text: strings.checkout, onPressed: onCheckout),
          ],
        ),
      ),
    );
  }
}
