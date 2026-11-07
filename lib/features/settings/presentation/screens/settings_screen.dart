import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/core/theme/app_theme.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/widgets/app_button.dart';
import 'package:ecommerce/features/auth/data/auth_repository.dart';
import 'package:ecommerce/features/auth/presentation/screens/login_screen.dart';
import 'package:ecommerce/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:ecommerce/features/address/presentation/screens/addresses_screen.dart';
import 'package:ecommerce/features/notifications/presentation/screens/notifications_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final currentLang = ref.watch(languageProvider);
    final isArabic = currentLang == AppLanguage.ar;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20.w(context), 12.h(context), 20.w(context), 100.h(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerWidget(isArabic, isDark),
              SizedBox(height: 20.h(context)),
              _profileWidget(isArabic, isDark),
              SizedBox(height: 22.h(context)),
              _mainScreensWidget(isArabic, isDark),
              SizedBox(height: 24.h(context)),
              _additionalPagesWidget(isArabic, isDark),
              SizedBox(height: 16.h(context)),
              _appSettingsWidget(isArabic, isDark, currentLang),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShortcutItem({
    required IconData icon,
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
                width: 64.w(context),
                height: 64.h(context),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: Offset(0, 4.h(context)),
                    ),
                  ],
                ),
                child: Icon(icon, color: iconColor, size: 28.sp(context)),
              ),
              Positioned(
                top: 0,
                right: 0,
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
                    style: context.textTheme.whiteLabelLarge?.copyWith(fontSize: 10.sp(context)),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h(context)),
          Text(
            label,
            style: context.textTheme.description?.copyWith(fontSize: 13.sp(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
    bool showArrow = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40.w(context),
          height: 40.h(context),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20.sp(context)),
        ),
        title: Text(
          title,
          style: context.textTheme.titleMedium?.copyWith(
                fontSize: 15.sp(context),
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ?trailing,
            if (showArrow) ...[
              SizedBox(width: 8.w(context)),
              Icon(Icons.arrow_forward_ios, size: 14.sp(context), color: AppColors.lightTextSecondary),
            ],
          ],
        ),
      ),
    );
  }

  Widget _headerWidget(bool isArabic, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          isArabic ? 'الإعدادات' : 'Settings',
          style: context.textTheme.displayLarge?.copyWith(
                fontSize: 28.sp(context),
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
        ),
        Row(
          children: [
            Container(
              width: 24.w(context),
              height: 24.h(context),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 4.w(context)),
            Icon(
              Icons.favorite,
              color: AppColors.primary,
              size: 30.sp(context),
            ),
            SizedBox(width: 4.w(context)),
            Container(
              width: 24.w(context),
              height: 28.h(context),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12.w(context)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _profileWidget(bool isArabic, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w(context)),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(28.w(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: Offset(0, 6.h(context)),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 80.w(context),
                height: 80.h(context),
                decoration: BoxDecoration(
                  color: AppColors.peach.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
              ),
              Icon(
                Icons.vpn_key,
                size: 38.sp(context),
                color: AppColors.mintTeal,
              ),
              Positioned(
                top: 8.h(context),
                right: 12.w(context),
                child: Container(
                  width: 10.w(context),
                  height: 10.h(context),
                  decoration: const BoxDecoration(
                    color: AppColors.starYellow,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: 10.h(context),
                left: 12.w(context),
                child: Container(
                  width: 10.w(context),
                  height: 10.h(context),
                  decoration: const BoxDecoration(
                    color: AppColors.badgeRed,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h(context)),
          Text(
            isArabic ? 'أنت لم تقم بتسجيل الدخول بعد' : "You're not signed in yet",
            style: context.textTheme.boldTitleLarge?.copyWith(
                  fontSize: 18.sp(context),
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
          ),
          SizedBox(height: 6.h(context)),
          Text(
            isArabic
                ? 'قم بتسجيل الدخول لحفظ المفضلة وتتبع الطلبات.'
                : 'Sign in to save favourites, track orders and get picks made for your family.',
            textAlign: TextAlign.center,
            style: context.textTheme.secondaryHint?.copyWith(
                  fontSize: 13.sp(context),
                ),
          ),
          SizedBox(height: 20.h(context)),
          AppButton(
            text: isArabic ? 'تسجيل الدخول' : 'SIGN IN',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            height: 50.h(context),
          ),
          SizedBox(height: 12.h(context)),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: Text(
              isArabic ? 'إنشاء حساب' : 'Create an account',
              style: context.textTheme.primaryTitleMedium?.copyWith(
                    fontSize: 13.sp(context),
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mainScreensWidget(bool isArabic, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildShortcutItem(
          icon: Icons.favorite,
          iconColor: AppColors.badgeRed,
          bgColor: AppColors.badgeRed.withValues(alpha: 0.1),
          label: isArabic ? 'المفضلة' : 'Favorites',
          badgeCount: '12',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FavoritesScreen()),
            );
          },
        ),
        _buildShortcutItem(
          icon: Icons.location_on_outlined,
          iconColor: AppColors.mintTeal,
          bgColor: AppColors.mintTeal.withValues(alpha: 0.1),
          label: isArabic ? 'العناوين' : 'Addresses',
          badgeCount: '2',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddressesScreen()),
            );
          },
        ),
        _buildShortcutItem(
          icon: Icons.notifications_outlined,
          iconColor: Colors.amber.shade800,
          bgColor: AppColors.softYellow,
          label: isArabic ? 'الإشعارات' : 'Notifications',
          badgeCount: '5',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _appSettingsWidget(bool isArabic, bool isDark, currentLang) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(24.w(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: Offset(0, 4.h(context)),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.language,
            iconColor: AppColors.primary,
            title: isArabic ? 'اللغة' : 'Language',
            trailing: Text(
              currentLang == AppLanguage.en ? 'English' : 'العربية',
              style: context.textTheme.primaryTitleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            onTap: () {
              ref.read(languageProvider.notifier).toggleLanguage();
            },
          ),
          Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
          _buildMenuItem(
            icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            iconColor: AppColors.primary,
            title: isArabic ? 'مظهر التطبيق' : 'App Theme',
            trailing: Text(
              isDark ? (isArabic ? 'داكن' : 'Dark') : (isArabic ? 'فاتح' : 'Light'),
              style: context.textTheme.primaryTitleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            onTap: () {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),
          Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
          _buildMenuItem(
            icon: Icons.info_outline,
            iconColor: AppColors.primary,
            title: isArabic ? 'إصدار التطبيق' : 'App version',
            trailing: Text(
              '1.0.1',
              style: context.textTheme.secondaryHint?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
            showArrow: false,
          ),
        ],
      ),
    );
  }

  Widget _additionalPagesWidget(bool isArabic, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(24.w(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: Offset(0, 4.h(context)),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.headphones_outlined,
            iconColor: AppColors.badgeRed,
            title: isArabic ? 'الدعم' : 'Support',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
          _buildMenuItem(
            icon: Icons.store_outlined,
            iconColor: AppColors.mintTeal,
            title: isArabic ? 'محدد المتاجر' : 'Store locator',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
          _buildMenuItem(
            icon: Icons.mail_outline,
            iconColor: Colors.amber.shade800,
            title: isArabic ? 'النشرة البريدية' : 'Newsletter',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
          _buildMenuItem(
            icon: Icons.logout,
            iconColor: AppColors.badgeRed,
            title: isArabic ? 'تسجيل الخروج من كل الأجهزة' : 'Logout All Devices',
            onTap: () async {
              try {
                final authRepo = AuthRepository(ref.read(dioClientProvider));
                await authRepo.logoutAll();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logged out from all devices successfully.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
          ),
          Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
          _buildMenuItem(
            icon: Icons.mark_email_unread_outlined,
            iconColor: AppColors.mintTeal,
            title: isArabic ? 'إعادة إرسال تفعيل البريد' : 'Resend Verification Email',
            onTap: () async {
              try {
                final authRepo = AuthRepository(ref.read(dioClientProvider));
                await authRepo.resendVerification('amelia.wood@gmail.com');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Verification email sent successfully.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
