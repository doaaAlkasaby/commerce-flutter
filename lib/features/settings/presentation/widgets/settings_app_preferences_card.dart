import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/app_theme.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/features/notifications/presentation/screens/notifications_screen.dart';
import 'settings_menu_card.dart';

class SettingsAppPreferencesCard extends ConsumerWidget {
  final AppStrings strings;
  final bool isDark;
  final dynamic currentLang;

  const SettingsAppPreferencesCard({
    super.key,
    required this.strings,
    required this.isDark,
    required this.currentLang,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsMenuCard(
      isDark: isDark,
      children: [
        SettingsMenuItem(
          strings: strings,
          icon: Icons.language,
          iconColor: AppColors.primary,
          title: strings.languageStr,
          trailing: Text(
            currentLang == AppLanguage.en ? 'English' : 'العربية',
            style: context.textTheme.mintTitleSmall,
          ),
          onTap: () {
            ref.read(languageProvider.notifier).toggleLanguage();
          },
        ),
        Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
        SettingsMenuItem(
          strings: strings,
          icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          iconColor: AppColors.primary,
          title: strings.appTheme,
          trailing: Text(
            isDark ? strings.dark : strings.light,
            style: context.textTheme.mintTitleSmall,
          ),
          onTap: () {
            ref.read(themeProvider.notifier).toggleTheme();
          },
        ),
        Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
        SettingsMenuItem(
          strings: strings,
          icon: Icons.info_outline,
          iconColor: AppColors.primary,
          title: strings.appVersion,
          trailing: Text('1.0.1', style: context.textTheme.bodySmall),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          },
          showArrow: false,
        ),
      ],
    );
  }
}
