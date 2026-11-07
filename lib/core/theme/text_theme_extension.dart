import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

extension BuildContextTextTheme on BuildContext {
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
}

extension AppTextTheme on TextTheme {
  // Headings
  TextStyle? get sectionTitle => headlineMedium;
  TextStyle? get bodyMini => bodySmall?.copyWith(fontSize: 14);

  // Gray / Muted Styles (Descriptions & Hints)
  TextStyle? get description => labelMedium?.copyWith(fontWeight: FontWeight.w500);
  TextStyle? get hint => labelSmall;
  TextStyle? get field => bodyMedium;
  TextStyle? get error => labelSmall?.copyWith(color: AppColors.badgeRed);
  TextStyle? get secondaryHint => bodyMedium?.copyWith(color: AppColors.lightTextSecondary);

  // Custom App Extensions
  TextStyle? get boldTitleSmall => titleSmall?.copyWith(fontWeight: FontWeight.bold);
  TextStyle? get boldTitleMedium => titleMedium?.copyWith(fontWeight: FontWeight.bold);
  TextStyle? get boldTitleLarge => titleLarge?.copyWith(fontWeight: FontWeight.bold);
  TextStyle? get addressBody => bodyMedium?.copyWith(height: 1.4);
  TextStyle? get fieldLabel => labelMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.lightTextSecondary);
  TextStyle? get strikeThroughBodySmall => bodySmall?.copyWith(decoration: TextDecoration.lineThrough);

  // White Text Variants (For primary backgrounds, buttons, etc.)
  TextStyle? get whiteBodyLarge => bodyLarge?.copyWith(color: Colors.white);
  TextStyle? get whiteBodyMedium => bodyMedium?.copyWith(color: Colors.white);
  TextStyle? get whiteBodySmall => bodySmall?.copyWith(color: Colors.white);

  TextStyle? get whiteTitleLarge => titleLarge?.copyWith(color: Colors.white);
  TextStyle? get whiteTitleMedium => titleMedium?.copyWith(color: Colors.white);
  TextStyle? get whiteLabelLarge => labelLarge?.copyWith(color: Colors.white);
  TextStyle? get whiteLabelMedium => labelMedium?.copyWith(color: Colors.white);

  TextStyle? get primaryBodyMedium => bodyMedium?.copyWith(color: AppColors.primary);
  TextStyle? get primaryTitleMedium => titleMedium?.copyWith(color: AppColors.primary);
  TextStyle? get primaryHeadlineSmall => headlineSmall?.copyWith(color: AppColors.primary);
  TextStyle? get primaryDisplayLarge => displayLarge?.copyWith(color: AppColors.primary, letterSpacing: 1.5);
}
