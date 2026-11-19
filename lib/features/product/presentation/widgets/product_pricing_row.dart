import 'package:flutter/material.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/widgets/app_price_text.dart';
import 'package:ecommerce/features/product/utils/variant_selection_helper.dart';

class ProductPricingRow extends StatelessWidget {
  final double finalPrice;
  final double originalPrice;
  final bool hasDiscount;
  final int? discountPercentage;
  final String currencyStr;

  const ProductPricingRow({
    super.key,
    required this.finalPrice,
    required this.originalPrice,
    required this.hasDiscount,
    this.discountPercentage,
    required this.currencyStr,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppPriceTextRow(
          isLarge: true,
          price: finalPrice,
          currency: currencyStr,
        ),
        if (hasDiscount) ...[
          SizedBox(width: 10.w(context)),
          AppPriceTextRow(
            price: VariantSelectionHelper.formatCurrency(
              originalPrice,
              currencyStr,
            ),
            currency: '',
            priceStyle: context.textTheme.strikeThroughBodySmall,
          ),
          SizedBox(width: 8.w(context)),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 8.w(context),
              vertical: 3.h(context),
            ),
            decoration: BoxDecoration(
              color: AppColors.badgeRed.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6.w(context)),
            ),
            child: Text(
              '${discountPercentage ?? 0}% OFF',
              style: context.textTheme.redLabelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 11.sp(context),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
