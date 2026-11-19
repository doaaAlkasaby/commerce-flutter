import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../core/config/app_environment.dart';
import '../../../../core/config/tenant_config.dart';
import '../../../../core/constants/app_assets.dart';

class LoginHeaderWidget extends ConsumerWidget {
  const LoginHeaderWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(languageProvider);
    final localizationAsync = ref.watch(appLocalizationLoaderProvider);
    final strings = AppStrings(localizationAsync.value ?? {}, currentLang);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tenant = ref.watch(tenantProvider);
    Widget defaultLogo = Image.asset(
      AppAssets.logo,
      width: 50.w(context),
      height: 50.w(context),
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.storefront, color: AppColors.primary, size: 24),
    );

    final resolvedLogoUrl = AppEnvironment.resolveImageUrl(tenant.logoUrl);

    Widget logoWidget;
    if (resolvedLogoUrl.isNotEmpty) {
      if (resolvedLogoUrl.toLowerCase().contains('.svg')) {
        logoWidget = SvgPicture.network(
          resolvedLogoUrl,
          width: 100.w(context),
          height: 100.w(context),
          fit: BoxFit.fill,
          placeholderBuilder: (_) => defaultLogo,
        );
      } else {
        logoWidget = CachedNetworkImage(
          imageUrl: resolvedLogoUrl,
          width: 100.w(context),
          height: 100.w(context),
          fit: BoxFit.fill,
          errorWidget: (context, url, error) => defaultLogo,
        );
      }
    } else {
      logoWidget = defaultLogo;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(50.w(context)),
          child: logoWidget,
        ),
        SizedBox(height: 12.h(context)),
        Text(tenant.appName, style: context.textTheme.primaryDisplayLarge),
        SizedBox(height: 16.h(context)),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 16.w(context),
            vertical: 8.h(context),
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardBg : Colors.white,
            borderRadius: BorderRadius.circular(20.w(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: Offset(0, 2.h(context)),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome,
                size: 16.sp(context),
                color: AppColors.primary,
              ),
              SizedBox(width: 6.w(context)),
              Text(
                strings.learnThroughPlay,
                style: context.textTheme.titleSmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
