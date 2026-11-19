import 'package:flutter/material.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';

class CartHeaderRow extends StatelessWidget {
  final int totalItems;
  final int uniqueProductsCount;
  final AppStrings strings;
  final VoidCallback onClearCart;

  const CartHeaderRow({
    super.key,
    required this.totalItems,
    required this.uniqueProductsCount,
    required this.strings,
    required this.onClearCart,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.shoppingCart, style: context.textTheme.displaySmall),
            SizedBox(height: 2.h(context)),
            Text(
              strings
                  .get('cart_summary')
                  .replaceAll('{itemsCount}', '$totalItems')
                  .replaceAll('{productsCount}', '$uniqueProductsCount'),
              style: context.textTheme.bodySmall,
            ),
          ],
        ),
        TextButton(
          onPressed: onClearCart,
          child: Text(
            strings.clearCart,
            style: context.textTheme.titleSmall?.copyWith(
              color: AppColors.badgeRed,
            ),
          ),
        ),
      ],
    );
  }
}
