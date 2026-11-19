import 'package:ecommerce/core/constants/app_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppUnauthWidget extends ConsumerWidget {
  final String? title;
  final String? description;
  final String? buttonText;
  final String? screenTitle;
  final IconData icon;
  final VoidCallback? onLoginPressed;

  const AppUnauthWidget({
    super.key,
    this.title,
    this.description,
    this.buttonText,
    this.screenTitle,
    this.icon = Icons.lock_outline,
    this.onLoginPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizationAsync = ref.watch(appLocalizationLoaderProvider);
    final currentLang = ref.watch(languageProvider);
    final strings = AppStrings(localizationAsync.value ?? {}, currentLang);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final effectiveTitle = title ?? strings.loginRequired;
    final effectiveDesc = description ?? strings.loginRequiredDesc;
    final effectiveBtnText = buttonText ?? strings.login;

    final content = Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(24.w(context)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(AppAssets.loginSVG, width: 140.w(context)),
            SizedBox(height: 16.h(context)),
            Text(
              effectiveTitle,
              style: context.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h(context)),
            Text(
              effectiveDesc,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium,
            ),
            SizedBox(height: 24.h(context)),
            ElevatedButton(
              onPressed:
                  onLoginPressed ??
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(
                  horizontal: 52.w(context),
                  vertical: 12.h(context),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.w(context)),
                ),
              ),
              child: Text(
                effectiveBtnText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (screenTitle != null) {
      return Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : const Color(0xFFF8F4EE),
        appBar: AppBar(
          backgroundColor: isDark
              ? AppColors.darkBackground
              : const Color(0xFFF8F4EE),
          elevation: 0,
          title: Text(screenTitle!, style: context.textTheme.titleLarge),
        ),
        body: content,
      );
    }

    return content;
  }
}
