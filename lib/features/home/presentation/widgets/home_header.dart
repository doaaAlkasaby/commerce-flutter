import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce/core/config/app_environment.dart';
import 'package:ecommerce/core/config/tenant_config.dart';
import 'package:ecommerce/core/constants/app_assets.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/features/search/presentation/screens/search_filter_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';

class HomeHeaderWidget extends ConsumerWidget {
  final AppStrings strings;
  final bool isDark;
  final bool isLoggedIn;
  final String userName;
  final AppLanguage currentLang;

  const HomeHeaderWidget({
    super.key,
    required this.strings,
    required this.isDark,
    required this.isLoggedIn,
    required this.userName,
    required this.currentLang,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget logoWidget;
    if (resolvedLogoUrl.isNotEmpty) {
      if (resolvedLogoUrl.toLowerCase().contains('.svg')) {
        logoWidget = SvgPicture.network(
          resolvedLogoUrl,
          width: 50.w(context),
          height: 50.w(context),
          fit: BoxFit.fill,
          placeholderBuilder: (_) => defaultLogo,
        );
      } else {
        logoWidget = CachedNetworkImage(
          imageUrl: resolvedLogoUrl,
          width: 50.w(context),
          height: 50.w(context),
          fit: BoxFit.fill,
          errorWidget: (context, url, error) => defaultLogo,
        );
      }
    } else {
      logoWidget = defaultLogo;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 50.w(context),
                height: 50.w(context),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14.w(context)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15.w(context)),
                  child: logoWidget,
                ),
              ),
              SizedBox(width: 5.w(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tenant.appName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.primaryDisplayMedium?.copyWith(
                        color: isDark ? Colors.white : AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 2.h(context)),
                    Text(
                      isLoggedIn ? 'Hi, $userName!' : strings.helloGuest,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 12.w(context)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w(context),
              height: 40.w(context),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2.h(context)),
                  ),
                ],
              ),
              child: IconButton(
                icon: SvgPicture.asset(
                  AppAssets.searchSvg,
                  colorFilter: ColorFilter.mode(
                    isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    BlendMode.srcIn,
                  ),
                  width: 17.sp(context),
                  height: 17.sp(context),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SearchFilterScreen(),
                    ),
                  );
                },
                padding: EdgeInsets.zero,
              ),
            ),
            SizedBox(width: 10.w(context)),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40.w(context),
                  height: 40.w(context),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: Offset(0, 2.h(context)),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: SvgPicture.asset(
                      AppAssets.bell,
                      colorFilter: ColorFilter.mode(
                        isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                        BlendMode.srcIn,
                      ),
                      width: 17.sp(context),
                      height: 17.sp(context),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      );
                    },
                    padding: EdgeInsets.zero,
                  ),
                ),
                Positioned(
                  top: 4.h(context),
                  right: 4.w(context),
                  child: Container(
                    padding: EdgeInsets.all(4.w(context)),
                    decoration: const BoxDecoration(
                      color: AppColors.badgeRed,
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(
                      minWidth: 18.w(context),
                      minHeight: 18.h(context),
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontSize: 10.sp(context),
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
