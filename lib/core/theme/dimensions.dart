import 'package:flutter/widgets.dart';
import 'package:responsive_framework/responsive_framework.dart';


  double fieldsRadius(BuildContext context) => context.scaled(20);
  double fieldsVPadding(BuildContext context) =>  context.scaled(15);
  double fieldsVPaddingDropdown (BuildContext context) =>  context.scaled(15);
  double fieldsHPadding (BuildContext context) =>  context.scaled(15);
  double radiusListItems (BuildContext context) =>  context.scaled(20);

class AppDimens {
  AppDimens._(); // Private constructor - prevents instantiation

  // ==================== SCALING METHODS ====================

  /// Scales a base value by breakpoint.
  /// Example: base=200 -> mobile=200, tablet=220, desktop=260
  static double scaled(BuildContext context, num base) {
    final baseValue = base.toDouble();

    return ResponsiveValue<double>(
      context,
      defaultValue: baseValue,
      conditionalValues: [
        Condition.equals(name: MOBILE, value: baseValue),
        Condition.equals(name: TABLET, value: baseValue * 1.3),
        Condition.equals(name: DESKTOP, value: baseValue * 1.5),
        Condition.largerThan(name: DESKTOP, value: baseValue * 1.8),
      ],
    ).value;
  }

  // ==================== RATIO METHODS ====================

  /// Width based on screen ratio (e.g., 0.9 = 90% of screen width)
  static double widthRatio(BuildContext context, double ratio) {
    final width = MediaQuery.sizeOf(context).width;
    return width * ratio.clamp(0.0, 1.0);
  }

  /// Height based on screen ratio (e.g., 0.3 = 30% of screen height)
  static double heightRatio(BuildContext context, double ratio) {
    final height = MediaQuery.sizeOf(context).height;
    return height * ratio.clamp(0.0, 1.0);
  }

  // ==================== SCREEN DIMENSIONS ====================

  /// Full screen width (safer than double.infinity)
  static double screenWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  /// Full screen height
  static double screenHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  /// Safe area top padding
  static double safeAreaTop(BuildContext context) =>
      MediaQuery.paddingOf(context).top;

  /// Safe area bottom padding
  static double safeAreaBottom(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom;

  // ==================== ORIENTATION METHODS ====================

  /// Check if device is landscape
  static bool isLandscape(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.landscape;

  /// Check if device is portrait
  static bool isPortrait(BuildContext context) => !isLandscape(context);

  // ==================== BREAKPOINT METHODS ====================

  /// Get current breakpoint name
  static String? currentBreakpoint(BuildContext context) =>
      ResponsiveBreakpoints.of(context).breakpoint.name;

  /// Check if current device is mobile
  static bool isMobile(BuildContext context) =>
      ResponsiveBreakpoints.of(context).isMobile;

  /// Check if current device is tablet
  static bool isTablet(BuildContext context) =>
      ResponsiveBreakpoints.of(context).isTablet;

  /// Check if current device is desktop
  static bool isDesktop(BuildContext context) =>
      ResponsiveBreakpoints.of(context).isDesktop;

  // ==================== UTILITY METHODS ====================

  /// Get responsive value based on breakpoint
  static T responsiveValue<T>(
      BuildContext context, {
        required T mobile,
        T? tablet,
        T? desktop,
      }) {
    if (isDesktop(context) && desktop != null) return desktop;
    if (isTablet(context) && tablet != null) return tablet;
    return mobile;
  }

  /// Get responsive padding
  static EdgeInsets responsivePadding(BuildContext context) {
    return EdgeInsets.all(
      responsiveValue(
        context,
        mobile: 12.0,
        tablet: 16.0,
        desktop: 24.0,
      ),
    );
  }

  /// Get responsive horizontal padding
  static EdgeInsets responsiveHorizontalPadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: responsiveValue(
        context,
        mobile: 16.0,
        tablet: 24.0,
        desktop: 32.0,
      ),
    );
  }

  /// Get responsive font size
  static double responsiveFontSize(
      BuildContext context, {
        required double mobile,
        double? tablet,
        double? desktop,
      }) {
    return responsiveValue(
      context,
      mobile: mobile,
      tablet: tablet ?? mobile * 1.3,
      desktop: desktop ?? mobile * 1.5,
    );
  }
}

// ==================== EXTENSION FOR CLEANER SYNTAX ====================
// This provides an alternative: context.scaled(100) instead of context.scaled( 100)

extension AppDimensExtension on BuildContext {
  double scaled(num base) => AppDimens.scaled(this, base);
  double widthRatio(double ratio) => AppDimens.widthRatio(this, ratio);
  double heightRatio(double ratio) => AppDimens.heightRatio(this, ratio);
  double fontSize(double size) => AppDimens.responsiveFontSize(this, mobile: size);
  double get screenWidth => AppDimens.screenWidth(this);
  double get screenHeight => AppDimens.screenHeight(this);
  double get safeAreaTop => AppDimens.safeAreaTop(this);
  double get safeAreaBottom => AppDimens.safeAreaBottom(this);
  bool get isLandscape => AppDimens.isLandscape(this);
  bool get isPortrait => AppDimens.isPortrait(this);
  bool get isMobile => AppDimens.isMobile(this);
  bool get isTablet => AppDimens.isTablet(this);
  bool get isDesktop => AppDimens.isDesktop(this);

  T responsiveValue<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) => AppDimens.responsiveValue(this, mobile: mobile, tablet: tablet, desktop: desktop);

  EdgeInsets get responsivePadding => AppDimens.responsivePadding(this);
  EdgeInsets get responsiveHorizontalPadding => AppDimens.responsiveHorizontalPadding(this);
}