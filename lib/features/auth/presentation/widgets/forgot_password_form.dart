import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/widgets/app_text_field.dart';
import 'package:ecommerce/core/widgets/app_button.dart';

class ForgotPasswordFormWidget extends ConsumerWidget {
  final TextEditingController emailController;
  final bool isLoading;
  final VoidCallback onSubmitPressed;

  const ForgotPasswordFormWidget({
    super.key,
    required this.emailController,
    required this.isLoading,
    required this.onSubmitPressed,
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
          controller: emailController,
          labelText: strings.emailAddress,
          hintText: 'name@example.com',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          bkgColor: Theme.of(context).cardColor,
        ),
        SizedBox(height: 32.h(context)),
        AppButton(
          text: strings.sendInstructions,
          onPressed: onSubmitPressed,
          isLoading: isLoading,
        ),
      ],
    );
  }
}
