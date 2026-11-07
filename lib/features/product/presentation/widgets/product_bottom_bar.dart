import 'package:flutter/material.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/widgets/app_button.dart';
import 'package:ecommerce/features/home/models/home_response_model.dart';

class ProductBottomBarWidget extends StatelessWidget {
  final ProductModel product;
  final int quantity;
  final bool isDark;
  final VoidCallback onAddToCartPressed;

  const ProductBottomBarWidget({
    super.key,
    required this.product,
    required this.quantity,
    required this.isDark,
    required this.onAddToCartPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(24.w(context), 16.h(context), 24.w(context), 28.h(context)),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('TOTAL', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 11.sp(context), color: AppColors.lightTextSecondary, fontWeight: FontWeight.bold)),
                SizedBox(height: 2.h(context)),
                Text(
                  '\$${(product.priceInfo.finalPrice * quantity).toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontSize: 22.sp(context),
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                ),
              ],
            ),
            SizedBox(width: 20.w(context)),
            Expanded(
              child: AppButton(
                text: 'ADD TO CART',
                onPressed: onAddToCartPressed,
                icon: Icons.shopping_bag_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
