import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/features/main_shell_screen.dart';
import '../providers/special_orders_availability_provider.dart';

enum SpecialOrdersBannerContext { home, categories, cart, orders }

class SpecialOrdersBanner extends ConsumerWidget {
  final SpecialOrdersBannerContext bannerContext;

  const SpecialOrdersBanner({
    super.key,
    required this.bannerContext,
  });

  String _getTitle(AppStrings strings) {
    switch (bannerContext) {
      case SpecialOrdersBannerContext.home:
        return strings.homeBannerTitle;
      case SpecialOrdersBannerContext.categories:
        return strings.categoriesBannerTitle;
      case SpecialOrdersBannerContext.cart:
        return strings.cartBannerTitle;
      case SpecialOrdersBannerContext.orders:
        return strings.ordersBannerTitle;
    }
  }

  String _getDescription(AppStrings strings) {
    switch (bannerContext) {
      case SpecialOrdersBannerContext.home:
        return strings.homeBannerDesc;
      case SpecialOrdersBannerContext.categories:
        return strings.categoriesBannerDesc;
      case SpecialOrdersBannerContext.cart:
        return strings.cartBannerDesc;
      case SpecialOrdersBannerContext.orders:
        return strings.ordersBannerDesc;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAvailable = ref.watch(specialOrdersAvailabilityProvider);
    if (!isAvailable) {
      return const SizedBox.shrink();
    }

    final localizationAsync = ref.watch(appLocalizationLoaderProvider);
    final currentLang = ref.watch(languageProvider);
    final strings = AppStrings(localizationAsync.value ?? {}, currentLang);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final title = _getTitle(strings);
    final description = _getDescription(strings);

    return InkWell(
      onTap: () {
        if (!isAvailable) return;
        ref
            .read(navigationIndexProvider.notifier)
            .setIndex(MainShellDestination.specialOrders);
      },
      borderRadius: BorderRadius.circular(16.w(context)),
      child: Container(
        constraints: BoxConstraints(minHeight: 64.h(context)),
        padding: EdgeInsets.symmetric(
          horizontal: 14.w(context),
          vertical: 10.h(context),
        ),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkCardBg
              : AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16.w(context)),
          border: Border.all(
            color: isDark
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38.w(context),
              height: 38.w(context),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.assignment_outlined,
                  size: 20.sp(context),
                  color: AppColors.primary,
                ),
              ),
            ),
            SizedBox(width: 12.w(context)),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp(context),
                    ),
                  ),
                  SizedBox(height: 2.h(context)),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      fontSize: 11.sp(context),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w(context)),
            Icon(
              Icons.arrow_forward_ios,
              size: 14.sp(context),
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
