import 'package:flutter/material.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';

class AddressCompletionProgressCard extends StatelessWidget {
  final double completionRatio;
  final bool isDark;
  final AppStrings strings;

  const AddressCompletionProgressCard({
    super.key,
    required this.completionRatio,
    required this.isDark,
    required this.strings,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                strings.requiredFieldsComplete,
                style: context.textTheme.titleSmall,
              ),
              Text(
                '${(completionRatio * 100).round()}%',
                style: context.textTheme.primaryTitleSmall,
              ),
            ],
          ),
          SizedBox(height: 8.h(context)),
          ClipRRect(
            borderRadius: BorderRadius.circular(6.w(context)),
            child: LinearProgressIndicator(
              value: completionRatio,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 8.h(context),
            ),
          ),
        ],
      ),
    );
  }
}
