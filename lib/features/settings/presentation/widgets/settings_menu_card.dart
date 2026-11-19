import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';

class SettingsMenuItem extends StatelessWidget {
  final IconData icon;
  final String? iconSVG;
  final Color iconColor;
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool showArrow;
  final AppStrings strings;

  const SettingsMenuItem({
    super.key,
    required this.icon,
    this.iconSVG,
    required this.iconColor,
    required this.title,
    this.trailing,
    required this.onTap,
    this.showArrow = true,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(
          vertical: 0.h(context),
          horizontal: 15.h(context),
        ),
        leading: Container(
          width: 32.w(context),
          height: 32.h(context),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: (iconSVG != null)
              ? Center(
                  child: SvgPicture.asset(
                    iconSVG!,
                    width: 12.sp(context),
                    height: 12.sp(context),
                    colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                  ),
                )
              : Icon(icon, color: iconColor, size: 18.sp(context)),
        ),
        title: Text(title, style: context.textTheme.titleSmall),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing != null) trailing!,
            if (showArrow) ...[
              SizedBox(width: 8.w(context)),
              Icon(
                Icons.arrow_forward_ios,
                size: 14.sp(context),
                color: AppColors.lightTextSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SettingsMenuCard extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;

  const SettingsMenuCard({
    super.key,
    required this.children,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 15.h(context)),
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
      child: Column(children: children),
    );
  }
}
