import 'package:flutter/material.dart';
import 'package:ecommerce/core/constants/app_assets.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/features/settings/presentation/screens/help_support_screen.dart';
import 'package:ecommerce/features/special_orders/presentation/screens/special_orders_list_screen.dart';
import 'package:ecommerce/features/tenant_selection/presentation/screens/tenant_selection_screen.dart';
import 'settings_menu_card.dart';

class SettingsStoreSupportCard extends StatelessWidget {
  final AppStrings strings;
  final bool isDark;

  const SettingsStoreSupportCard({
    super.key,
    required this.strings,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsMenuCard(
      isDark: isDark,
      children: [
        SettingsMenuItem(
          strings: strings,
          iconSVG: AppAssets.shopSvg,
          icon: Icons.store_outlined,
          iconColor: AppColors.mintTeal,
          title: strings.changeStore,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    const TenantSelectionScreen(isChangeStore: true),
              ),
            );
          },
        ),
        Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
        SettingsMenuItem(
          strings: strings,
          icon: Icons.headphones_outlined,
          iconSVG: AppAssets.supportSvg,
          iconColor: AppColors.badgeRed,
          title: strings.support,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
            );
          },
        ),
        Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
        SettingsMenuItem(
          strings: strings,
          icon: Icons.assignment_outlined,
          iconColor: AppColors.primary,
          title: strings.mySpecialOrders,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const SpecialOrdersListScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
}
