import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/features/settings/presentation/providers/settings_provider.dart';

class AppUpdateHelper {
  static Future<void> checkAndShowUpdateDialog(BuildContext context, WidgetRef ref) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 1;

      final settings = await ref.read(appSettingsProvider.future);
      if (settings != null && context.mounted) {
        final localizationAsync = ref.read(appLocalizationLoaderProvider);
        final currentLang = ref.read(languageProvider);
        final strings = AppStrings(localizationAsync.value ?? {}, currentLang);

        final supportedBuilds = Platform.isIOS ? settings.iosBuild : settings.androidBuild;
        final needsUpdate = settings.forceUpdate && (supportedBuilds.isNotEmpty && !supportedBuilds.contains(currentBuild));

        if (needsUpdate) {
          showDialog(
            context: context,
            barrierDismissible: !settings.forceUpdate,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(strings.updateRequired, style: const TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strings.updateMessage),
                  const SizedBox(height: 16),
                  Text('${strings.currentBuildStr}: $currentBuild', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.lightTextSecondary)),
                  Text('${strings.supportedBuildsStr}: ${supportedBuilds.join(", ")}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.lightTextSecondary)),
                ],
              ),
              actions: [
                if (!settings.forceUpdate)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(strings.later, style: const TextStyle(color: AppColors.lightTextSecondary)),
                  ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: Text(strings.updateNow, style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }
      }
    } catch (_) {}
  }
}
