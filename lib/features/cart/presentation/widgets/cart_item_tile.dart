import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/widgets/app_price_text.dart';
import 'package:ecommerce/features/cart/models/cart_model.dart';
import 'package:ecommerce/features/orders/models/order_model.dart';

class CartItemTile extends StatelessWidget {
  final CartItemModel item;
  final String currencyStr;
  final AppStrings strings;
  final bool isDark;
  final VoidCallback onNavigateToDetails;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onDelete;

  const CartItemTile({
    super.key,
    required this.item,
    required this.currencyStr,
    required this.strings,
    required this.isDark,
    required this.onNavigateToDetails,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final productImgUrl = item.variant.resolvedImageUrl ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 16.h(context)),
      padding: EdgeInsets.all(16.w(context)),
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
      child: Column(
        children: [
          // Top Row: Image + Details + Item Subtotal Price
          GestureDetector(
            onTap: onNavigateToDetails,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 68.w(context),
                  height: 68.h(context),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBF7F2),
                    borderRadius: BorderRadius.circular(16.w(context)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.w(context)),
                    child: CachedNetworkImage(
                      imageUrl: productImgUrl,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.shopping_bag_outlined, size: 24),
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
                        style: context.textTheme.titleMedium,
                      ),
                      SizedBox(height: 2.h(context)),
                      Text(
                        item.variant.sku.isNotEmpty
                            ? item.variant.sku
                            : strings.oneSize,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.labelMedium,
                      ),
                      SizedBox(height: 2.h(context)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${formatOrderMoney(item.finalUnitPrice, currencyStr, strings.isArabic)} ${strings.each}',
                            style: context.textTheme.labelSmall,
                          ),
                          AppPriceTextRow(
                            price: item.totalPrice,
                            currency: currencyStr,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 12.h(context)),

          // Bottom Row: Stepper Pill + Delete Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Quantity Stepper Pill
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10.w(context),
                  vertical: 4.h(context),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F5EE),
                  borderRadius: BorderRadius.circular(20.w(context)),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: onDecrement,
                      child: Padding(
                        padding: EdgeInsets.all(4.w(context)),
                        child: Icon(
                          Icons.remove,
                          size: 14.sp(context),
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w(context)),
                      child: Text(
                        '${item.quantity}',
                        style: context.textTheme.primaryTitleSmall,
                      ),
                    ),
                    GestureDetector(
                      onTap: onIncrement,
                      child: Padding(
                        padding: EdgeInsets.all(4.w(context)),
                        child: Icon(
                          Icons.add,
                          size: 14.sp(context),
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Delete Icon Button
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: Colors.grey.shade500,
                  size: 20.sp(context),
                ),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
