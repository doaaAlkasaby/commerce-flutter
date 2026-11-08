import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/features/auth/presentation/screens/login_screen.dart';

class UnAuthBottomBanner extends ConsumerStatefulWidget {
  const UnAuthBottomBanner({super.key});

  @override
  ConsumerState<UnAuthBottomBanner> createState() => _UnAuthBottomBannerState();
}

class _UnAuthBottomBannerState extends ConsumerState<UnAuthBottomBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final currentLang = ref.watch(languageProvider);
    final isArabic = currentLang == AppLanguage.ar;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.fromLTRB(
        16.w(context),
        0,
        16.w(context),
        12.h(context),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 16.w(context),
        vertical: 12.h(context),
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(30.w(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: Offset(0, 4.h(context)),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36.w(context),
            height: 36.w(context),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_outline,
              color: AppColors.primary,
              size: 18.sp(context),
            ),
          ),
          SizedBox(width: 12.w(context)),
          Expanded(
            child: Text(
              isArabic
                  ? 'تسجيل الدخول لحفظ تقدمك'
                  : 'Sign in to save your progress',
              style: TextStyle(
                fontSize: 13.sp(context),
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(
                horizontal: 16.w(context),
                vertical: 8.h(context),
              ),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18.w(context)),
              ),
            ),
            child: Text(
              isArabic ? 'دخول' : 'SIGN IN',
              style: TextStyle(
                fontSize: 12.sp(context),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: 8.w(context)),
          IconButton(
            icon: Icon(
              Icons.close,
              size: 18.sp(context),
              color: AppColors.lightTextSecondary,
            ),
            onPressed: () {
              setState(() {
                _dismissed = true;
              });
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
