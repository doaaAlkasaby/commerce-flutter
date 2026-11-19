import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ecommerce/core/constants/app_assets.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/core/widgets/unauth_bottom_banner.dart';
import 'package:ecommerce/features/home/presentation/screens/home_screen.dart';
import 'package:ecommerce/features/categories/presentation/screens/categories_main_screen.dart';
import 'package:ecommerce/features/cart/presentation/screens/cart_screen.dart';
import 'package:ecommerce/features/orders/presentation/screens/orders_screen.dart';
import 'package:ecommerce/features/settings/presentation/screens/settings_screen.dart';
import 'package:ecommerce/features/cart/presentation/providers/cart_provider.dart';

part 'main_shell_screen.g.dart';

@riverpod
class NavigationIndex extends _$NavigationIndex {
  @override
  int build() => 0;

  void setIndex(int index) {
    state = index;
  }
}

class MainShellScreen extends ConsumerWidget {
  const MainShellScreen({super.key});

  Widget _buildSvgIcon(String assetPath, Color color, {double size = 20}) {
    return Padding(
      padding: EdgeInsetsGeometry.only(top: 5, bottom: 5),
      child: SvgPicture.asset(
        assetPath,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
    );
  }

  Widget _buildCartIcon(
    String assetPath,
    Color color,
    int itemCount, {
    double size = 20,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: EdgeInsetsGeometry.only(top: 5, bottom: 5),
          child: SvgPicture.asset(
            assetPath,
            width: size,
            height: size,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
        ),
        if (itemCount > 0)
          Positioned(
            top: -4,
            right: -6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.badgeRed,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$itemCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);
    final currentLang = ref.watch(languageProvider);
    final localizationAsync = ref.watch(appLocalizationLoaderProvider);
    final strings = AppStrings(localizationAsync.value ?? {}, currentLang);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final token = ref.watch(authTokenProvider);
    final isUnauthorized = token == null || token.isEmpty;
    final cartAsync = ref.watch(cartProvider);
    final itemCount = cartAsync.value?.itemCount ?? 0;

    final selectedColor = isDark ? Colors.white : AppColors.primary;
    final unselectedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    final List<Widget> screens = [
      const HomeScreen(),
      const CategoriesMainScreen(),
      const CartScreen(),
      const OrdersScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: screens),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isUnauthorized) const UnAuthBottomBanner(),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: (index) {
                ref.read(navigationIndexProvider.notifier).setIndex(index);
              },
              backgroundColor: isDark
                  ? AppColors.darkSurface
                  : AppColors.lightBackground,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: isDark ? Colors.white : AppColors.primary,
              selectedIconTheme: IconThemeData(
                color: isDark ? Colors.white : AppColors.primary,
              ),
              unselectedItemColor: unselectedColor,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
              items: [
                BottomNavigationBarItem(
                  icon: _buildSvgIcon(
                    AppAssets.homeSvg,
                    unselectedColor,
                    size: 17,
                  ),
                  activeIcon: _buildSvgIcon(
                    AppAssets.homeSvg,
                    selectedColor,
                    size: 17,
                  ),
                  label: strings.home,
                ),
                BottomNavigationBarItem(
                  icon: _buildSvgIcon(
                    AppAssets.categoriesSvg,
                    unselectedColor,
                    size: 17,
                  ),
                  activeIcon: _buildSvgIcon(
                    AppAssets.categoriesSvg,
                    selectedColor,
                    size: 17,
                  ),
                  label: strings.categories,
                ),
                BottomNavigationBarItem(
                  icon: _buildCartIcon(
                    AppAssets.cartSvg,
                    unselectedColor,
                    itemCount,
                    size: 17,
                  ),
                  activeIcon: _buildCartIcon(
                    AppAssets.cartSvg,
                    selectedColor,
                    itemCount,
                    size: 17,
                  ),
                  label: strings.cart,
                ),
                BottomNavigationBarItem(
                  icon: _buildSvgIcon(AppAssets.ordersSvg, unselectedColor),
                  activeIcon: _buildSvgIcon(AppAssets.ordersSvg, selectedColor),
                  label: strings.orders,
                ),
                BottomNavigationBarItem(
                  icon: _buildSvgIcon(AppAssets.settingsSvg, unselectedColor),
                  activeIcon: _buildSvgIcon(
                    AppAssets.settingsSvg,
                    selectedColor,
                  ),
                  label: strings.settings,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
