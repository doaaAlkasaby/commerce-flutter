import 'package:flutter/material.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';

class SettingsHeader extends StatelessWidget {
  final AppStrings strings;

  const SettingsHeader({super.key, required this.strings});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(strings.settings, style: context.textTheme.displayLarge)],
    );
  }
}
