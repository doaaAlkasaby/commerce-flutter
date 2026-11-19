import 'package:flutter/material.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum AppButtonType { primary, outlined, text }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final bool isLoading;
  final IconData? icon;
  final String? svg;
  final String? png;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? iconColor;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = AppButtonType.primary,
    this.isLoading = false,
    this.icon,
    this.svg,
    this.png,
    this.width,
    this.height,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final btnHeight = height ?? 48.h(context);
    final btnWidth = width ?? double.infinity;

    if (type == AppButtonType.outlined) {
      return SizedBox(
        width: btnWidth,
        height: btnHeight,
        child: OutlinedButton.icon(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: backgroundColor ?? AppColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(btnHeight / 2),
            ),
          ),
          icon: isLoading
              ? SizedBox(
                  width: 18.w(context),
                  height: 18.h(context),
                  child: CircularProgressIndicator(
                    color: backgroundColor ?? AppColors.primary,
                    strokeWidth: 2,
                  ),
                )
              : (icon != null
                    ? Icon(
                        icon,
                        size: 18.sp(context),
                        color: textColor ?? AppColors.primary,
                      )
                    : (svg != null)
                    ? SvgPicture.asset(
                        svg!,
                        width: 18.w(context),
                        height: 18.h(context),
                        colorFilter: ColorFilter.mode(
                          textColor ?? AppColors.primary,
                          BlendMode.srcIn,
                        ),
                      )
                    : (png != null)
                    ? Image.asset(
                        png!,
                        width: 18.w(context),
                        height: 18.h(context),
                        color: textColor ?? AppColors.primary,
                      )
                    : const SizedBox.shrink()),
          label: Text(
            text,
            style: textColor != null
                ? context.textTheme.titleMedium?.copyWith(color: textColor)
                : context.textTheme.primaryTitleMedium,
          ),
        ),
      );
    }

    if (type == AppButtonType.text) {
      return TextButton(
        onPressed: isLoading ? null : onPressed,
        child: Text(
          text,
          style: textColor != null
              ? context.textTheme.titleMedium?.copyWith(color: textColor)
              : context.textTheme.primaryTitleMedium,
        ),
      );
    }

    return SizedBox(
      width: btnWidth,
      height: btnHeight,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(btnHeight / 2),
          ),
          elevation: 4,
        ),
        icon: isLoading
            ? SizedBox(
                width: 18.w(context),
                height: 18.h(context),
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : (icon != null
                  ? Icon(
                      icon,
                      color: textColor ?? Colors.white,
                      size: 18.sp(context),
                    )
                  : (svg != null)
                  ? SvgPicture.asset(
                      svg!,
                      width: 18.w(context),
                      height: 18.h(context),
                      colorFilter: ColorFilter.mode(
                        textColor ?? Colors.white,
                        BlendMode.srcIn,
                      ),
                    )
                  : (png != null)
                  ? Image.asset(
                      png!,
                      width: 18.w(context),
                      height: 18.h(context),
                      color: textColor ?? Colors.white,
                    )
                  : const SizedBox.shrink()),
        label: Text(
          text,
          style: textColor != null
              ? context.textTheme.whiteTitleMedium?.copyWith(color: textColor)
              : context.textTheme.whiteTitleMedium,
        ),
      ),
    );
  }
}
