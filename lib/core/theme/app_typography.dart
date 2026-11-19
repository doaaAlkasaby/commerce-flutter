import 'package:flutter/material.dart';
import 'package:ecommerce/core/constants/app_colors.dart';

class AppTypography {
  static const String fontFamily = 'IBMPlexSansArabic';

  /// Device Form Factor Scale Ratios
  static double mobileScaleRatio = 1.0; // Mobile phones (< 600px width)
  static double tabletScaleRatio = 1.15; // Tablets & Foldables (600px - 900px)
  static double desktopScaleRatio = 1.25; // Desktop & Web (> 900px)

  /// Global User Accessibility Adjustment (Multiplier applied on top of device ratio)
  static double userFontScaleMultiplier = 1.0;

  /// Calculates the active font scale ratio based on current device screen width
  static double fontScaleRatioFor(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    double deviceRatio;
    if (width > 900) {
      deviceRatio = desktopScaleRatio;
    } else if (width > 600) {
      deviceRatio = tabletScaleRatio;
    } else {
      deviceRatio = mobileScaleRatio;
    }
    return deviceRatio * userFontScaleMultiplier;
  }

  /// Calculates responsive scalable pixel size (sp) incorporating screen width and active device ratio
  static double sp(double baseSize, BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final responsiveFactor = width > 600 ? 1.0 : (width / 375.0);
    return baseSize * responsiveFactor * fontScaleRatioFor(context);
  }

  static TextTheme lightTextTheme(BuildContext context) {
    return TextTheme(
      headlineLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: sp(24, context),
        fontWeight: FontWeight.w900,
        color: AppColors.lightTextPrimary,
      ),
      headlineMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: sp(22, context),
        fontWeight: FontWeight.w900,
        color: AppColors.lightTextPrimary,
      ),
      headlineSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: sp(20, context),
        fontWeight: FontWeight.w900,
        color: AppColors.lightTextPrimary,
      ),
      displayLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: sp(18, context),
        fontWeight: FontWeight.w800,
        color: AppColors.lightTextPrimary,
      ),
      displayMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: sp(16, context),
        fontWeight: FontWeight.w800,
        color: AppColors.lightTextPrimary,
      ),
      displaySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: sp(14, context),
        fontWeight: FontWeight.w800,
        color: AppColors.lightTextPrimary,
      ),
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: sp(16, context),
        fontWeight: FontWeight.bold,
        color: AppColors.lightTextPrimary,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: sp(14, context),
        fontWeight: FontWeight.w600,
        color: AppColors.lightTextPrimary,
      ),
      titleSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: sp(12, context),
        fontWeight: FontWeight.w600,
        color: AppColors.lightTextPrimary,
      ),
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: sp(15, context),
        fontWeight: FontWeight.w500,
        color: AppColors.lightTextPrimary,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: sp(14, context),
        fontWeight: FontWeight.w500,
        color: AppColors.lightTextPrimary,
      ),
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: sp(12, context),
        fontWeight: FontWeight.w500,
        color: AppColors.lightTextPrimary,
      ),
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: sp(14, context),
        fontWeight: FontWeight.w400,
        color: AppColors.lightTextSecondary,
      ),
      labelMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: sp(12, context),
        fontWeight: FontWeight.w400,
        color: AppColors.lightTextSecondary,
      ),
      labelSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: sp(10, context),
        fontWeight: FontWeight.w400,
        color: AppColors.lightTextSecondary,
      ),
    );
  }

  static TextTheme darkTextTheme(BuildContext context) {
    return TextTheme(
      headlineLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: sp(24, context),
        fontWeight: FontWeight.w900,
        color: AppColors.darkTextPrimary,
      ),
      headlineMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: sp(22, context),
        fontWeight: FontWeight.w900,
        color: AppColors.darkTextPrimary,
      ),
      headlineSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: sp(20, context),
        fontWeight: FontWeight.w900,
        color: AppColors.darkTextPrimary,
      ),
      displayLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: sp(18, context),
        fontWeight: FontWeight.w800,
        color: AppColors.darkTextPrimary,
      ),
      displayMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: sp(16, context),
        fontWeight: FontWeight.w800,
        color: AppColors.darkTextPrimary,
      ),
      displaySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: sp(14, context),
        fontWeight: FontWeight.w800,
        color: AppColors.darkTextPrimary,
      ),
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: sp(16, context),
        fontWeight: FontWeight.bold,
        color: AppColors.darkTextPrimary,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: sp(14, context),
        fontWeight: FontWeight.w600,
        color: AppColors.darkTextPrimary,
      ),
      titleSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: sp(12, context),
        fontWeight: FontWeight.w600,
        color: AppColors.darkTextPrimary,
      ),
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: sp(15, context),
        fontWeight: FontWeight.w500,
        color: AppColors.darkTextPrimary,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: sp(14, context),
        fontWeight: FontWeight.w500,
        color: AppColors.darkTextSecondary,
      ),
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: sp(12, context),
        fontWeight: FontWeight.w500,
        color: AppColors.darkTextSecondary,
      ),
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: sp(14, context),
        fontWeight: FontWeight.w400,
        color: AppColors.darkTextSecondary,
      ),
      labelMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: sp(12, context),
        fontWeight: FontWeight.w400,
        color: AppColors.darkTextSecondary,
      ),
      labelSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: sp(10, context),
        fontWeight: FontWeight.w400,
        color: AppColors.darkTextSecondary,
      ),
    );
  }
}
