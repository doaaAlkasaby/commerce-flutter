import 'package:flutter/material.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';

class OrderSectionHeader extends StatelessWidget {
  final String sortOrder;
  final AppStrings strings;
  final ValueChanged<String> onSortChanged;

  const OrderSectionHeader({
    super.key,
    required this.sortOrder,
    required this.strings,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w(context)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            strings.activeHeader,
            style: context.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: sortOrder,
              icon: Icon(
                Icons.keyboard_arrow_down,
                size: 16.sp(context),
                color: AppColors.primary,
              ),
              style: context.textTheme.primaryTitleSmall,
              onChanged: (val) {
                if (val != null) onSortChanged(val);
              },
              items: [
                DropdownMenuItem(
                  value: 'NEWEST',
                  child: Text(strings.newestFirst),
                ),
                DropdownMenuItem(
                  value: 'OLDEST',
                  child: Text(strings.oldestFirst),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
