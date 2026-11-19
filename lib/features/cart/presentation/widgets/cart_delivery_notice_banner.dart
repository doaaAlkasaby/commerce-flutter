import 'package:flutter/material.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';

class CartDeliveryNoticeBanner extends StatelessWidget {
  final AppStrings strings;
  final bool isDark;

  const CartDeliveryNoticeBanner({
    super.key,
    required this.strings,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w(context)),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(16.w(context)),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_shipping_outlined,
            color: AppColors.primary,
            size: 20.sp(context),
          ),
          SizedBox(width: 12.w(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.deliveryCalculatedAtCheckout,
                  style: context.textTheme.titleSmall,
                ),
                Text(strings.codAvailable, style: context.textTheme.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
