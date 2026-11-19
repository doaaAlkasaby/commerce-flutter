import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecommerce/main.dart';
import 'package:ecommerce/core/theme/app_theme.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';

void main() {
  group('Theme & Language Persistence Tests', () {
    test(
      '1. ThemeNotifier loads saved dark mode from SharedPreferences',
      () async {
        SharedPreferences.setMockInitialValues({'app_theme_mode': 'dark'});
        sharedPreferences = await SharedPreferences.getInstance();

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final theme = container.read(themeProvider);
        expect(theme, equals(ThemeMode.dark));
      },
    );

    test(
      '2. Toggling theme updates state and saves to SharedPreferences',
      () async {
        SharedPreferences.setMockInitialValues({'app_theme_mode': 'light'});
        sharedPreferences = await SharedPreferences.getInstance();

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(themeProvider.notifier);
        expect(container.read(themeProvider), equals(ThemeMode.light));

        notifier.toggleTheme();
        expect(container.read(themeProvider), equals(ThemeMode.dark));
        expect(sharedPreferences.getString('app_theme_mode'), equals('dark'));

        notifier.toggleTheme();
        expect(container.read(themeProvider), equals(ThemeMode.light));
        expect(sharedPreferences.getString('app_theme_mode'), equals('light'));
      },
    );

    test(
      '3. LanguageNotifier loads saved Arabic language from SharedPreferences',
      () async {
        SharedPreferences.setMockInitialValues({'app_language': 'ar'});
        sharedPreferences = await SharedPreferences.getInstance();

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final lang = container.read(languageProvider);
        expect(lang, equals(AppLanguage.ar));
      },
    );

    test(
      '4. Toggling language updates state and saves to SharedPreferences',
      () async {
        SharedPreferences.setMockInitialValues({'app_language': 'en'});
        sharedPreferences = await SharedPreferences.getInstance();

        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(languageProvider.notifier);
        expect(container.read(languageProvider), equals(AppLanguage.en));

        notifier.toggleLanguage();
        expect(container.read(languageProvider), equals(AppLanguage.ar));
        expect(sharedPreferences.getString('app_language'), equals('ar'));

        notifier.toggleLanguage();
        expect(container.read(languageProvider), equals(AppLanguage.en));
        expect(sharedPreferences.getString('app_language'), equals('en'));
      },
    );
  });
}
