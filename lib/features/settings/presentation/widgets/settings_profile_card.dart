import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/widgets/app_button.dart';
import 'package:ecommerce/features/auth/presentation/providers/user_provider.dart';
import 'package:ecommerce/features/auth/presentation/screens/login_screen.dart';

class SettingsProfileCard extends ConsumerWidget {
  final AppStrings strings;
  final bool isDark;

  const SettingsProfileCard({
    super.key,
    required this.strings,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value;

    if (user != null) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(24.w(context)),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBg : Colors.white,
          borderRadius: BorderRadius.circular(28.w(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: Offset(0, 6.h(context)),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 72.w(context),
              height: 72.h(context),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                user.firstName.isNotEmpty
                    ? user.firstName[0].toUpperCase()
                    : 'U',
                style: context.textTheme.whiteHeadlineLarge,
              ),
            ),
            SizedBox(height: 12.h(context)),
            Text(
              user.fullName,
              style: context.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h(context)),
            Text(
              user.email,
              style: context.textTheme.secondaryHint,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10.h(context)),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 12.w(context),
                vertical: 4.h(context),
              ),
              decoration: BoxDecoration(
                color: user.isEmailVerified
                    ? Colors.green.withValues(alpha: 0.15)
                    : Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12.w(context)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    user.isEmailVerified
                        ? Icons.check_circle
                        : Icons.warning_amber_rounded,
                    size: 14.sp(context),
                    color: user.isEmailVerified ? Colors.green : Colors.orange,
                  ),
                  SizedBox(width: 6.w(context)),
                  Text(
                    user.isEmailVerified
                        ? strings.verifiedAccount
                        : strings.unverifiedAccount,
                    style: user.isEmailVerified
                        ? context.textTheme.greenBodySmall
                        : context.textTheme.orangeBodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w(context)),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(28.w(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: Offset(0, 6.h(context)),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 80.w(context),
                height: 80.h(context),
                decoration: BoxDecoration(
                  color: AppColors.peach.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
              ),
              Icon(
                Icons.vpn_key,
                size: 38.sp(context),
                color: AppColors.mintTeal,
              ),
            ],
          ),
          SizedBox(height: 16.h(context)),
          Text(strings.notSignedInYet, style: context.textTheme.titleLarge),
          SizedBox(height: 6.h(context)),
          Text(
            strings.notSignedInDesc,
            textAlign: TextAlign.center,
            style: context.textTheme.secondaryHint,
          ),
          SizedBox(height: 20.h(context)),
          AppButton(
            text: strings.signIn,
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            height: 50.h(context),
          ),
        ],
      ),
    );
  }
}
