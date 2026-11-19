import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

extension BuildContextTextTheme on BuildContext {
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
}

extension AppTextTheme on TextTheme {
  // Field & Form Styles
  TextStyle? get badgeLabel => labelSmall?.copyWith(color: AppColors.primary);
  TextStyle? get hint => labelSmall;
  TextStyle? get field => bodySmall;
  TextStyle? get error => labelSmall?.copyWith(color: AppColors.badgeRed);
  TextStyle? get secondaryHint =>
      labelMedium?.copyWith(color: AppColors.lightTextSecondary);
  TextStyle? get semiBoldHint =>
      bodyMedium?.copyWith(color: AppColors.lightTextSecondary);
  TextStyle? get fieldLabel =>
      labelMedium?.copyWith(color: AppColors.lightTextSecondary);

  // Verification & Status Badges
  TextStyle? get greenLabelSmall => labelSmall?.copyWith(color: Colors.green);
  TextStyle? get orangeLabelSmall => labelSmall?.copyWith(color: Colors.orange);
  TextStyle? get greenBodySmall => bodySmall?.copyWith(color: Colors.green);
  TextStyle? get orangeBodySmall => bodySmall?.copyWith(color: Colors.orange);
  TextStyle? get greenTitleSmall => titleSmall?.copyWith(color: Colors.green);
  TextStyle? get orangeTitleSmall => labelSmall?.copyWith(color: Colors.orange);

  // Body Variations
  TextStyle? get bodyMini => bodySmall?.copyWith(fontSize: 11);
  TextStyle? get titleMini => titleSmall?.copyWith(fontSize: 11);
  TextStyle? get addressBody => bodyMedium?.copyWith(height: 1.4);
  TextStyle? get strikeThroughBodySmall =>
      grayBodySmall?.copyWith(decoration: TextDecoration.lineThrough);

  // Address Screen Custom Styles
  TextStyle? get subheaderLabel => labelSmall?.copyWith(
    color: const Color(0xFF9E8E81),
    fontWeight: FontWeight.bold,
    letterSpacing: 1.1,
  );
  TextStyle? get badgeTextTan => labelSmall?.copyWith(
    color: AppColors.peach, //8D7F73
    fontWeight: FontWeight.bold,
  );
  TextStyle? get badgeTextOrange => labelSmall?.copyWith(
    color: const Color(0xFFE65100),
    fontWeight: FontWeight.bold,
  );
  TextStyle? get badgeTextGreen => labelSmall?.copyWith(
    color: const Color(0xFF2E7D32),
    fontWeight: FontWeight.bold,
  );
  TextStyle? get badgeTextBrown => labelSmall?.copyWith(
    color: const Color(0xFF6E5C4E),
    fontWeight: FontWeight.bold,
  );
  TextStyle? get primaryActionText => titleSmall?.copyWith(
    color: AppColors.primary,
    fontWeight: FontWeight.bold,
  );
  TextStyle? get secondaryNoticeText =>
      labelSmall?.copyWith(color: const Color(0xFF9E8E81));

  // White Text Variants

  TextStyle? get whiteHeadlineLarge =>
      headlineSmall?.copyWith(color: Colors.white);
  TextStyle? get whiteHeadlineMedium =>
      headlineSmall?.copyWith(color: Colors.white);
  TextStyle? get whiteHeadlineSmall =>
      headlineSmall?.copyWith(color: Colors.white);

  TextStyle? get whiteDisplayLarge =>
      displayLarge?.copyWith(color: Colors.white);
  TextStyle? get whiteDisplayMedium =>
      displayMedium?.copyWith(color: Colors.white);
  TextStyle? get whiteDisplaySmall =>
      displaySmall?.copyWith(color: Colors.white);

  TextStyle? get whiteBodyLarge => bodyLarge?.copyWith(color: Colors.white);
  TextStyle? get whiteBodyMedium => bodyMedium?.copyWith(color: Colors.white);
  TextStyle? get whiteBodySmall => bodySmall?.copyWith(color: Colors.white);

  TextStyle? get whiteTitleLarge => titleLarge?.copyWith(color: Colors.white);
  TextStyle? get whiteTitleMedium => titleMedium?.copyWith(color: Colors.white);
  TextStyle? get whiteTitleSmall => titleSmall?.copyWith(color: Colors.white);

  TextStyle? get whiteLabelLarge => labelLarge?.copyWith(color: Colors.white);
  TextStyle? get whiteLabelMedium => labelMedium?.copyWith(color: Colors.white);
  TextStyle? get whiteLabelSmall => labelSmall?.copyWith(color: Colors.white);
  TextStyle? get whiteLabelMini => labelSmall?.copyWith(color: Colors.white70);

  //primary Text Variants
  TextStyle? get primaryTitleLarge =>
      titleLarge?.copyWith(color: AppColors.primary);
  TextStyle? get primaryTitleMedium =>
      titleMedium?.copyWith(color: AppColors.primary);
  TextStyle? get primaryTitleSmall =>
      titleSmall?.copyWith(color: AppColors.primary);
  TextStyle? get primaryTitleMini =>
      titleSmall?.copyWith(color: AppColors.primary, fontSize: 11);

  TextStyle? get primaryHeadlineSmall =>
      headlineSmall?.copyWith(color: AppColors.primary);
  TextStyle? get primaryDisplayMax =>
      displayLarge?.copyWith(color: AppColors.primary, fontSize: 22);
  TextStyle? get primaryDisplayLarge =>
      displayLarge?.copyWith(color: AppColors.primary);
  TextStyle? get primaryDisplayMedium =>
      displayMedium?.copyWith(color: AppColors.primary);
  TextStyle? get primaryDisplaySmall =>
      displaySmall?.copyWith(color: AppColors.primary);

  TextStyle? get primaryBodyLarge =>
      bodyLarge?.copyWith(color: AppColors.primary);
  TextStyle? get primaryBodyMedium =>
      bodyMedium?.copyWith(color: AppColors.primary);
  TextStyle? get primaryBodySmall =>
      bodySmall?.copyWith(color: AppColors.primary);
  TextStyle? get primaryBodyMini =>
      bodySmall?.copyWith(color: AppColors.primary, fontSize: 11);

  TextStyle? get primaryLabelLarge =>
      labelLarge?.copyWith(color: AppColors.primary);
  TextStyle? get primaryLabelMedium =>
      labelMedium?.copyWith(color: AppColors.primary);
  TextStyle? get primaryLabelSmall =>
      labelSmall?.copyWith(color: AppColors.primary);

  // Red Text Variants
  TextStyle? get redLabelMedium =>
      labelMedium?.copyWith(color: AppColors.badgeRed);
  TextStyle? get redTitleSmall =>
      titleSmall?.copyWith(color: AppColors.badgeRed);

  // Others Text Variants
  TextStyle? get mintTitleMini =>
      titleMini?.copyWith(color: AppColors.mintTeal);
  TextStyle? get mintTitleSmall =>
      titleSmall?.copyWith(color: AppColors.mintTeal);
  TextStyle? get mintTitleMedium =>
      titleMedium?.copyWith(color: AppColors.mintTeal);
  TextStyle? get mintLabelSmall =>
      labelSmall?.copyWith(color: AppColors.mintTeal);

  TextStyle? get grayBodySmall =>
      bodySmall?.copyWith(color: AppColors.lightTextSecondary);

  TextStyle? get grayBodyMedium =>
      bodyMedium?.copyWith(color: AppColors.lightTextSecondary);
}
