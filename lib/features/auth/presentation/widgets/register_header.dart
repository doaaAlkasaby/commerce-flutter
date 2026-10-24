import 'package:flutter/material.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';

class RegisterHeaderWidget extends StatelessWidget {
  final bool isArabic;

  const RegisterHeaderWidget({
    super.key,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? 'إنشاء حساب جديد' : 'Create account',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontSize: 26.sp(context),
                fontWeight: FontWeight.bold,
                color: AppColors.lightTextPrimary,
              ),
        ),
        SizedBox(height: 6.h(context)),
        Text(
          'Join our family studio and get special perks.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14.sp(context),
                color: AppColors.lightTextSecondary,
              ),
        ),
      ],
    );
  }
}
