import 'package:flutter/material.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';

enum AppButtonType { primary, outlined, text }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? textColor;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = AppButtonType.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final btnHeight = height ?? 54.h(context);
    final btnWidth = width ?? double.infinity;

    if (type == AppButtonType.outlined) {
      return SizedBox(
        width: btnWidth,
        height: btnHeight,
        child: OutlinedButton.icon(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: backgroundColor ?? AppColors.primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(btnHeight / 2)),
          ),
          icon: isLoading
              ? SizedBox(width: 18.w(context), height: 18.h(context), child: CircularProgressIndicator(color: backgroundColor ?? AppColors.primary, strokeWidth: 2))
              : (icon != null ? Icon(icon, size: 18.sp(context), color: textColor ?? AppColors.primary) : const SizedBox.shrink()),
          label: Text(
            text,
            style: context.textTheme.labelLarge?.copyWith(
                  fontSize: 15.sp(context),
                  fontWeight: FontWeight.bold,
                  color: textColor ?? AppColors.primary,
                ),
          ),
        ),
      );
    }

    if (type == AppButtonType.text) {
      return TextButton(
        onPressed: isLoading ? null : onPressed,
        child: Text(
          text,
          style: context.textTheme.labelLarge?.copyWith(
                fontSize: 14.sp(context),
                fontWeight: FontWeight.bold,
                color: textColor ?? AppColors.primary,
              ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(btnHeight / 2)),
          elevation: 4,
        ),
        icon: isLoading
            ? SizedBox(width: 18.w(context), height: 18.h(context), child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : (icon != null ? Icon(icon, color: textColor ?? Colors.white, size: 18.sp(context)) : const SizedBox.shrink()),
        label: Text(
          text,
          style: context.textTheme.whiteLabelLarge?.copyWith(
                fontSize: 15.sp(context),
                fontWeight: FontWeight.bold,
                color: textColor ?? Colors.white,
                letterSpacing: 1.0,
              ),
        ),
      ),
    );
  }
}
