import 'package:flutter/material.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';

class LoginHeaderWidget extends StatelessWidget {
  const LoginHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36.w(context),
              height: 36.w(context),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 8.w(context)),
            Icon(
              Icons.favorite,
              color: AppColors.primary,
              size: 48.sp(context),
            ),
            SizedBox(width: 8.w(context)),
            Container(
              width: 36.w(context),
              height: 44.h(context),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(18.w(context)),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h(context)),
        Text(
          'kids studio',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontSize: 24.sp(context),
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 1.2,
              ),
        ),
        SizedBox(height: 16.h(context)),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w(context), vertical: 8.h(context)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.w(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: Offset(0, 2.h(context)),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, size: 16.sp(context), color: AppColors.primary),
              SizedBox(width: 6.w(context)),
              Text(
                'Learn through play',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 13.sp(context),
                      fontWeight: FontWeight.w600,
                      color: AppColors.lightTextPrimary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
