import 'package:flutter/material.dart';
import 'package:ecommerce/core/constants/app_assets.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/features/search/presentation/screens/search_filter_screen.dart';

class HomeHeaderWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isArabic = currentLang == AppLanguage.ar;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 44.w(context),
                height: 44.w(context),
                decoration: BoxDecoration(
                  // color: Colors.white,
                  borderRadius: BorderRadius.circular(14.w(context)),
                  // boxShadow: [
                  //   BoxShadow(
                  //     color: Colors.black.withValues(alpha: 0.08),
                  //     blurRadius: 8,
                  //     offset: Offset(0, 4.h(context)),
                  //   ),
                  // ],
                ),
                // child: ClipRRect(
                //   borderRadius: BorderRadius.circular(14.w(context)),
                  child: Image.asset(
                    AppAssets.logo,
                    width: 44.w(context),
                    height: 44.w(context),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.storefront, color: AppColors.primary, size: 24),
                    ),
                  // ),
                ),
              ),
              SizedBox(width: 12.w(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLoggedIn ? strings.goodMorning : (isArabic ? 'مرحباً بك' : 'Welcome'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 12.sp(context),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    SizedBox(height: 2.h(context)),
                    Text(
                      isLoggedIn ? 'Hi, $userName!' : (isArabic ? 'أهلاً بك، زائرنا الكريم' : 'Hello, Guest!'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 18.sp(context),
                            fontWeight: FontWeight.bold,
                          ),
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
                icon: Icon(
                  Icons.search,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  size: 20.sp(context),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SearchFilterScreen()),
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
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      size: 20.sp(context),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('You have 5 unread notifications'),
                          behavior: SnackBarBehavior.floating,
                        ),
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
                      '5',
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
