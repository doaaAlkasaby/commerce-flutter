import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/services.dart';
import 'package:ecommerce/core/constants/app_assets.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/core/services/notification_navigation_handler.dart';
import 'package:ecommerce/core/widgets/unauth_bottom_banner.dart';
import 'package:ecommerce/features/home/presentation/screens/home_screen.dart';
import 'package:ecommerce/features/categories/presentation/screens/categories_main_screen.dart';
import 'package:ecommerce/features/cart/presentation/screens/cart_screen.dart';
import 'package:ecommerce/features/orders/presentation/screens/orders_screen.dart';
import 'package:ecommerce/features/cart/presentation/providers/cart_provider.dart';
import 'package:ecommerce/features/special_orders/presentation/providers/special_orders_availability_provider.dart';
import 'package:ecommerce/features/special_orders/presentation/screens/special_orders_list_screen.dart';

part 'main_shell_screen.g.dart';

class MainShellDestination {
  static const int home = 0;
  static const int categories = 1;
  static const int cart = 2;
  static const int orders = 3;
  static const int specialOrders = 4;
}

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

  Widget _buildSvgIcon(String assetPath, Color color, {double size = 16}) {
    return Container(
      margin: EdgeInsetsGeometry.only(bottom: 5),
      padding: EdgeInsetsGeometry.only(top: 5, bottom: 5, left: 10, right: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
      ),
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
    double size = 16,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: EdgeInsetsGeometry.only(bottom: 5),
          padding: EdgeInsetsGeometry.only(
            top: 5,
            bottom: 5,
            left: 10,
            right: 10,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30),
          ),
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

  Future<bool> _showExitConfirmationDialog(
    BuildContext context,
    AppStrings strings,
    bool isDark,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.w(context)),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 20.w(context),
            vertical: 24.h(context),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60.w(context),
                height: 60.w(context),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    color: AppColors.primary,
                    size: 28.sp(context),
                  ),
                ),
              ),
              SizedBox(height: 16.h(context)),
              Text(
                strings.exitAppTitle,
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10.h(context)),
              Text(
                strings.exitAppDesc,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h(context)),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.w(context)),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h(context)),
                      ),
                      child: Text(
                        strings.exitAppBtn,
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.badgeRed,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w(context)),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.w(context)),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h(context)),
                      ),
                      child: Text(
                        strings.continueBtn,
                        style: context.textTheme.whiteLabelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(authTokenProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationNavigationHandler.checkAndNavigatePending(
        authToken: token,
        context: context,
      );
    });

    final currentIndex = ref.watch(navigationIndexProvider);
    final currentLang = ref.watch(languageProvider);
    final localizationAsync = ref.watch(appLocalizationLoaderProvider);
    final strings = AppStrings(localizationAsync.value ?? {}, currentLang);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUnauthorized = token == null || token.isEmpty;
    final cartAsync = ref.watch(cartProvider);
    final itemCount = cartAsync.value?.itemCount ?? 0;

    final isSpecialOrdersEnabled = ref.watch(specialOrdersAvailabilityProvider);
    final selectedColor = isDark ? Colors.white : AppColors.primary;
    final unselectedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    final List<Widget> screens = [
      const HomeScreen(),
      const CategoriesMainScreen(),
      const CartScreen(),
      const OrdersScreen(),
      if (isSpecialOrdersEnabled) const SpecialOrdersListScreen(),
    ];

    final effectiveIndex = currentIndex < screens.length ? currentIndex : 0;
    if (currentIndex >= screens.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(navigationIndexProvider.notifier).setIndex(0);
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (effectiveIndex != 0) {
          ref.read(navigationIndexProvider.notifier).setIndex(0);
          return;
        }

        final shouldExit = await _showExitConfirmationDialog(
          context,
          strings,
          isDark,
        );

        if (shouldExit && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(index: effectiveIndex, children: screens),
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
                currentIndex: effectiveIndex,
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
                      size: 14,
                    ),
                    activeIcon: _buildSvgIcon(
                      AppAssets.homeSvg,
                      selectedColor,
                      size: 14,
                    ),
                    label: strings.home,
                  ),
                  BottomNavigationBarItem(
                    icon: _buildSvgIcon(
                      AppAssets.categoriesSvg,
                      unselectedColor,
                      size: 13,
                    ),
                    activeIcon: _buildSvgIcon(
                      AppAssets.categoriesSvg,
                      selectedColor,
                      size: 13,
                    ),
                    label: strings.categories,
                  ),
                  BottomNavigationBarItem(
                    icon: _buildCartIcon(
                      AppAssets.cartSvg,
                      unselectedColor,
                      itemCount,
                      size: 14,
                    ),
                    activeIcon: _buildCartIcon(
                      AppAssets.cartSvg,
                      selectedColor,
                      itemCount,
                      size: 14,
                    ),
                    label: strings.cart,
                  ),
                  BottomNavigationBarItem(
                    icon: _buildSvgIcon(AppAssets.basketSvg, unselectedColor),
                    activeIcon: _buildSvgIcon(
                      AppAssets.basketSvg,
                      selectedColor,
                    ),
                    label: strings.orders,
                  ),
                  if (isSpecialOrdersEnabled)
                    BottomNavigationBarItem(
                      icon: _buildSvgIcon(AppAssets.orderSVG, unselectedColor, size: 14),
                      activeIcon: _buildSvgIcon(
                        AppAssets.orderSVG,
                        selectedColor,
                        size: 14,
                      ),
                      label: strings.specialOrders,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
