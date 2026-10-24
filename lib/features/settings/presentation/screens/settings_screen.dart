import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/core/theme/app_theme.dart';
import 'package:ecommerce/features/auth/data/auth_repository.dart';
import 'package:ecommerce/features/auth/presentation/screens/login_screen.dart';
import 'package:ecommerce/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:ecommerce/features/address/presentation/screens/addresses_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _showBanner = true;

  @override
  Widget build(BuildContext context) {
    final currentLang = ref.watch(languageProvider);
    final isArabic = currentLang == AppLanguage.ar;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isArabic ? 'الإعدادات' : 'Settings',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.favorite,
                            color: AppColors.primary,
                            size: 30,
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 24,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardBg : Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppColors.peach.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const Icon(
                              Icons.vpn_key,
                              size: 38,
                              color: AppColors.mintTeal,
                            ),
                            Positioned(
                              top: 8,
                              right: 12,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: AppColors.starYellow,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 10,
                              left: 12,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: AppColors.badgeRed,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isArabic ? 'أنت لم تقم بتسجيل الدخول بعد' : "You're not signed in yet",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isArabic
                              ? 'قم بتسجيل الدخول لحفظ المفضلة وتتبع الطلبات.'
                              : 'Sign in to save favourites, track orders and get picks made for your family.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              elevation: 3,
                            ),
                            child: Text(
                              isArabic ? 'تسجيل الدخول' : 'SIGN IN',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                          },
                          child: Text(
                            isArabic ? 'إنشاء حساب' : 'Create an account',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
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
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardBg : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildMenuItem(
                          icon: Icons.headphones_outlined,
                          iconColor: AppColors.badgeRed,
                          title: isArabic ? 'الدعم' : 'Support',
                          onTap: () {},
                        ),
                        Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
                        _buildMenuItem(
                          icon: Icons.store_outlined,
                          iconColor: AppColors.mintTeal,
                          title: isArabic ? 'محدد المتاجر' : 'Store locator',
                          onTap: () {},
                        ),
                        Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
                        _buildMenuItem(
                          icon: Icons.mail_outline,
                          iconColor: Colors.amber.shade800,
                          title: isArabic ? 'النشرة البريدية' : 'Newsletter',
                          onTap: () {},
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
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardBg : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          onTap: () {
                            ref.read(themeProvider.notifier).toggleTheme();
                          },
                        ),
                        Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
                        _buildMenuItem(
                          icon: Icons.notifications_outlined,
                          iconColor: AppColors.badgeRed,
                          title: isArabic ? 'الإشعارات' : 'Notifications',
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.badgeRed,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('5', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                          onTap: () {},
                        ),
                        Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
                        _buildMenuItem(
                          icon: Icons.info_outline,
                          iconColor: AppColors.primary,
                          title: isArabic ? 'إصدار التطبيق' : 'App version',
                          trailing: const Text(
                            '1.0.1',
                            style: TextStyle(
                              color: AppColors.lightTextSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onTap: () {},
                          showArrow: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_showBanner)
              Positioned(
                bottom: 12,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lock_outline, color: AppColors.primary, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isArabic ? 'تسجيل الدخول لحفظ تقدمك' : 'Sign in to save your progress',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          isArabic ? 'دخول' : 'SIGN IN',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: AppColors.lightTextSecondary),
                        onPressed: () {
                          setState(() {
                            _showBanner = false;
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),
          ],
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
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    badgeCount,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.lightTextSecondary,
            ),
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.lightTextPrimary,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ?trailing,
            if (showArrow) ...[
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.lightTextSecondary),
            ],
          ],
        ),
      ),
    );
  }
}
