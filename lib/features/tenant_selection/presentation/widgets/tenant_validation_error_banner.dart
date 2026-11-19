import 'package:flutter/material.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';

class TenantValidationErrorBanner extends StatelessWidget {
  final String errorMessage;
  final bool isValidating;
  final AppStrings strings;
  final VoidCallback onRetry;

  const TenantValidationErrorBanner({
    super.key,
    required this.errorMessage,
    required this.isValidating,
    required this.strings,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h(context)),
      padding: EdgeInsets.all(10.w(context)),
      decoration: BoxDecoration(
        color: AppColors.badgeRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.w(context)),
        border: Border.all(color: AppColors.badgeRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.badgeRed,
            size: 18.sp(context),
          ),
          SizedBox(width: 8.w(context)),
          Expanded(
            child: Text(errorMessage, style: context.textTheme.redTitleSmall),
          ),
          TextButton(
            onPressed: isValidating ? null : onRetry,
            child: Text(strings.retry),
          ),
        ],
      ),
    );
  }
}
