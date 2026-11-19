import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import '../widgets/settings_account_actions_card.dart';
import '../widgets/settings_app_preferences_card.dart';
import '../widgets/settings_header.dart';
import '../widgets/settings_profile_card.dart';
import '../widgets/settings_shortcuts_row.dart';
import '../widgets/settings_store_support_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(languageProvider);
    final localizationAsync = ref.watch(appLocalizationLoaderProvider);
    final strings = AppStrings(localizationAsync.value ?? {}, currentLang);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            12.w(context),
            12.h(context),
            12.w(context),
            100.h(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header
              SettingsHeader(strings: strings),

              SizedBox(height: 20.h(context)),

              // 2. Profile Card
              SettingsProfileCard(strings: strings, isDark: isDark),

              SizedBox(height: 22.h(context)),

              // 3. Shortcuts Row (Favorites, Addresses, Notifications)
              SettingsShortcutsRow(strings: strings, isDark: isDark),

              SizedBox(height: 24.h(context)),

              // 4. Store & Support Actions
              SettingsStoreSupportCard(strings: strings, isDark: isDark),

              SizedBox(height: 16.h(context)),

              // 5. Account & Auth Actions
              SettingsAccountActionsCard(strings: strings, isDark: isDark),

              SizedBox(height: 16.h(context)),

              // 6. App Preferences (Language, Theme, Version)
              SettingsAppPreferencesCard(
                strings: strings,
                isDark: isDark,
                currentLang: currentLang,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
