import 'package:flutter/material.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';

class TenantSelectionHeader extends StatelessWidget {
  final AppStrings strings;

  const TenantSelectionHeader({super.key, required this.strings});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10.h(context)),
        Text(strings.chooseYourStore, style: context.textTheme.titleLarge),
        SizedBox(height: 4.h(context)),
        Text(strings.chooseStoreDesc, style: context.textTheme.bodySmall),
      ],
    );
  }
}
