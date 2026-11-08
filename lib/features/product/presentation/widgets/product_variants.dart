import 'package:flutter/material.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/features/home/models/home_response_model.dart';

class ProductVariantsWidget extends StatelessWidget {
  final ProductModel product;
  final ProductVariantModel? selectedVariant;
  final bool isDark;

  const ProductVariantsWidget({
    super.key,
    required this.product,
    required this.selectedVariant,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (product.variants.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(vertical: 16.h(context)),
      padding: EdgeInsets.all(16.w(context)),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(20.w(context)),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Variant SKU',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp(context),
                  color: AppColors.lightTextSecondary,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8.w(context),
                  vertical: 3.h(context),
                ),
                decoration: BoxDecoration(
                  color: (selectedVariant?.isActive ?? true)
                      ? AppColors.mintTeal.withValues(alpha: 0.15)
                      : AppColors.badgeRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.w(context)),
                ),
                child: Text(
                  (selectedVariant?.isActive ?? true)
                      ? 'In Stock'
                      : 'Out of Stock',
                  style: TextStyle(
                    fontSize: 11.sp(context),
                    fontWeight: FontWeight.bold,
                    color: (selectedVariant?.isActive ?? true)
                        ? AppColors.mintTeal
                        : AppColors.badgeRed,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h(context)),
          Text(
            selectedVariant?.sku ?? product.slug.toUpperCase(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 14.sp(context),
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
