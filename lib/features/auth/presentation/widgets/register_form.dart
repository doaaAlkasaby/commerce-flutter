import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/widgets/app_text_field.dart';
import 'package:ecommerce/core/widgets/app_button.dart';

class RegisterFormWidget extends ConsumerWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onRegisterPressed;

  const RegisterFormWidget({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.onTogglePasswordVisibility,
    required this.onRegisterPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(languageProvider);
    final localizationAsync = ref.watch(appLocalizationLoaderProvider);
    final strings = AppStrings(localizationAsync.value ?? {}, currentLang);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: nameController,
          labelText: strings.fullName,
          hintText: strings.nameHint,
          prefixIcon: Icons.person_outline,
          bkgColor: Theme.of(context).cardColor,
        ),
        SizedBox(height: 16.h(context)),
        AppTextField(
          controller: emailController,
          labelText: strings.emailAddress,
          hintText: 'name@example.com',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          bkgColor: Theme.of(context).cardColor,
        ),
        SizedBox(height: 16.h(context)),
        AppTextField(
          controller: passwordController,
          labelText: strings.password,
          hintText: strings.createAPassword,
          prefixIcon: Icons.lock_outline,
          obscureText: obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
            onPressed: onTogglePasswordVisibility,
          ),
          bkgColor: Theme.of(context).cardColor,
        ),
        SizedBox(height: 4.h(context)),
        Text(strings.passwordValidation, style: context.textTheme.labelSmall),
        SizedBox(height: 32.h(context)),
        AppButton(
          text: strings.signUp,
          onPressed: onRegisterPressed,
          isLoading: isLoading,
        ),
      ],
    );
  }
}
