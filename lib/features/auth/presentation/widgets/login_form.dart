import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/widgets/app_text_field.dart';
import 'package:ecommerce/core/widgets/app_button.dart';

class LoginFormWidget extends ConsumerWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onLoginPressed;
  final VoidCallback onForgotPasswordPressed;
  final VoidCallback onCreateAccountPressed;
  final bool isArabic;

  const LoginFormWidget({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.onTogglePasswordVisibility,
    required this.onLoginPressed,
    required this.onForgotPasswordPressed,
    required this.onCreateAccountPressed,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(languageProvider);
    final localizationAsync = ref.watch(appLocalizationLoaderProvider);
    final strings = AppStrings(localizationAsync.value ?? {}, currentLang);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w(context)),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(36.w(context)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: Offset(0, -8.h(context)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48.w(context),
              height: 5.h(context),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10.w(context)),
              ),
            ),
          ),
          SizedBox(height: 24.h(context)),
          Text(strings.welcomeBack, style: context.textTheme.displaySmall),
          SizedBox(height: 8.h(context)),
          Text(
            strings.pleaseEnterAccountDetails,
            style: context.textTheme.bodyMedium,
          ),
          SizedBox(height: 28.h(context)),
          AppTextField(
            controller: emailController,
            labelText: strings.emailAddress,
            hintText: 'name@example.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 20.h(context)),
          AppTextField(
            controller: passwordController,
            labelText: strings.password,
            hintText: strings.enterYourPassword,
            prefixIcon: Icons.lock_outline,
            obscureText: obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.lightTextSecondary,
              ),
              onPressed: onTogglePasswordVisibility,
            ),
          ),
          SizedBox(height: 24.h(context)),
          AppButton(
            text: strings.signIn,
            onPressed: onLoginPressed,
            isLoading: isLoading,
          ),
          SizedBox(height: 0.h(context)),
          Center(
            child: TextButton(
              onPressed: onForgotPasswordPressed,
              child: Text(
                strings.forgotPasswordQ,
                style: context.textTheme.primaryBodySmall,
              ),
            ),
          ),
          SizedBox(height: 8.h(context)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                strings.dontHaveAccount,
                style: context.textTheme.bodyMedium,
              ),
              TextButton(
                onPressed: onCreateAccountPressed,
                child: Text(
                  strings.signUp,
                  style: context.textTheme.primaryTitleMedium,
                ),
              ),
            ],
          ),
          SizedBox(height: 0.h(context)),
        ],
      ),
    );
  }
}
