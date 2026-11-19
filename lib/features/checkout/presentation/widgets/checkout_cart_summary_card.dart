import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce/core/config/tenant_config.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/widgets/app_price_text.dart';
import 'package:ecommerce/features/cart/models/cart_model.dart';

class CheckoutCartSummaryCard extends StatelessWidget {
  final CartModel cart;
  final String currencyStr;
  final AppStrings strings;
  final bool isDark;
  final TenantConfig tenant;

  const CheckoutCartSummaryCard({
    super.key,
    required this.cart,
    required this.currencyStr,
    required this.strings,
    required this.isDark,
    required this.tenant,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Row(
        children: [
          Row(
            children: [
              ...cart.items
                  .take(3)
                  .map(
                    (item) => Padding(
                      padding: EdgeInsets.only(right: 6.w(context)),
                      child: Container(
                        width: 36.w(context),
                        height: 36.h(context),
                        decoration: BoxDecoration(
                          color: AppColors.lightCategoryBg,
                          borderRadius: BorderRadius.circular(10.w(context)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.w(context)),
                          child: CachedNetworkImage(
                            imageUrl: item.variant.resolvedImageUrl ?? '',
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => const Icon(
                              Icons.shopping_bag_outlined,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
          SizedBox(width: 8.w(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${cart.itemCount} ${strings.items}',
                  style: context.textTheme.titleSmall,
                ),
                Text(
                  strings
                      .get('from_merchant')
                      .replaceAll('{merchantName}', tenant.appName),
                  style: context.textTheme.labelSmall,
                ),
              ],
            ),
          ),
          AppPriceTextRow(price: cart.subtotal, currency: currencyStr),
        ],
      ),
    );
  }
}
