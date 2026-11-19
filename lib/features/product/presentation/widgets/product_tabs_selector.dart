import 'package:flutter/material.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';

class ProductTabsSelector extends StatelessWidget {
  final int selectedTabIndex;
  final int reviewCount;
  final bool isDark;
  final AppStrings strings;
  final ValueChanged<int> onTabSelected;

  const ProductTabsSelector({
    super.key,
    required this.selectedTabIndex,
    required this.reviewCount,
    required this.isDark,
    required this.strings,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkBkg,
        borderRadius: BorderRadius.circular(16.w(context)),
      ),
      padding: EdgeInsets.all(4.w(context)),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onTabSelected(0),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10.h(context)),
                decoration: BoxDecoration(
                  color: selectedTabIndex == 0
                      ? (isDark ? AppColors.darkSurface : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12.w(context)),
                  boxShadow: selectedTabIndex == 0
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  strings.details,
                  textAlign: TextAlign.center,
                  style: context.textTheme.titleSmall?.copyWith(
                    color: selectedTabIndex == 0
                        ? (isDark ? Colors.white : AppColors.primary)
                        : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onTabSelected(1),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10.h(context)),
                decoration: BoxDecoration(
                  color: selectedTabIndex == 1
                      ? (isDark ? AppColors.darkSurface : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12.w(context)),
                  boxShadow: selectedTabIndex == 1
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  '${strings.reviewsHeader} ($reviewCount)',
                  textAlign: TextAlign.center,
                  style: context.textTheme.titleSmall?.copyWith(
                    color: selectedTabIndex == 1
                        ? AppColors.primary
                        : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
