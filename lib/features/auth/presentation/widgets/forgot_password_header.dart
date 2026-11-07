import 'package:flutter/material.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';

class ForgotPasswordHeaderWidget extends StatelessWidget {
  final bool isArabic;

  const ForgotPasswordHeaderWidget({
    super.key,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? 'إعادة تعيين كلمة المرور' : 'Reset password',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontSize: 26.sp(context),
                fontWeight: FontWeight.bold,
                color: AppColors.lightTextPrimary,
              ),
        ),
        SizedBox(height: 6.h(context)),
        Text(
          'Enter your email address and we will send you instructions to reset your password.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14.sp(context),
                color: AppColors.lightTextSecondary,
                height: 1.4,
              ),
        ),
      ],
    );
  }
}
