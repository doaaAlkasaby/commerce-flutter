import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ecommerce/core/constants/app_assets.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/features/address/presentation/screens/addresses_screen.dart';
import 'package:ecommerce/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:ecommerce/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:ecommerce/features/notifications/presentation/screens/notifications_screen.dart';

class SettingsShortcutsRow extends ConsumerWidget {
  final AppStrings strings;
  final bool isDark;

  const SettingsShortcutsRow({
    super.key,
    required this.strings,
    required this.isDark,
  });

  Widget _buildShortcutItem({
    required BuildContext context,
    required String icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required String badgeCount,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 32.w(context),
                height: 32.h(context),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SvgPicture.asset(
                    icon,
                    width: 16.sp(context),
                    height: 16.sp(context),
                    colorFilter: ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
                  ),
                )
              ),


              if (badgeCount.isNotEmpty && badgeCount != '0')
                Positioned(
                  bottom: 5,
                  right: -8,
                  child: Container(
                    padding: EdgeInsets.all(5.w(context)),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(
                      minWidth: 20.w(context),
                      minHeight: 20.h(context),
                    ),
                    child: Text(
                      badgeCount,
                      style: context.textTheme.whiteTitleSmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8.h(context)),
          Text(label, style: context.textTheme.primaryBodySmall),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return  Container(
        padding: EdgeInsets.symmetric(vertical: 20.w(context)),
      decoration: BoxDecoration(
        color: Colors.white, //AppColors.primary.withValues(alpha: 0.08),
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(20.w(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: Offset(0, 4.h(context)),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(

          children: [
            Expanded(
              child: _buildShortcutItem(
                context: context,
                icon: AppAssets.heart,
                iconColor: AppColors.badgeRed,
                bgColor: AppColors.badgeRed.withValues(alpha: 0.1),
                label: strings.favorites,
                badgeCount: '',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                  );
                },
              ),
            ),
            VerticalDivider(
              width: 1,
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
            Expanded(
              child: _buildShortcutItem(
                context: context,
                icon: AppAssets.marker,
                iconColor: AppColors.mintTeal,
                bgColor: AppColors.mintTeal.withValues(alpha: 0.1),
                label: strings.addresses,
                badgeCount: '',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddressesScreen()),
                  );
                },
              ),
            ),
            VerticalDivider(
              width: 1,
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
            Expanded(
              child: _buildShortcutItem(
                context: context,
                icon: AppAssets.bell,
                iconColor: Colors.amber.shade800,
                bgColor: AppColors.softYellow,
                label: strings.notifications,
                badgeCount: unreadCount.toString(),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ));
  }
}
