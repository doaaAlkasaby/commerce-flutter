import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';

class RegisterHeaderWidget extends ConsumerWidget {
  const RegisterHeaderWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(languageProvider);
    final localizationAsync = ref.watch(appLocalizationLoaderProvider);
    final strings = AppStrings(localizationAsync.value ?? {}, currentLang);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.createAccount.toUpperCase(),
          style: context.textTheme.displayLarge,
        ),
        SizedBox(height: 6.h(context)),
        Text(
          strings.registerHeaderDesc,
          style: context.textTheme.grayBodySmall,
        ),
      ],
    );
  }
}
