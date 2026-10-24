import 'package:flutter/material.dart';
import 'package:ecommerce/core/constants/app_colors.dart';

class AppImageContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final List<Color>? gradientColors;

  const AppImageContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius,
    this.padding,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        gradient: RadialGradient(
          colors: [
            AppColors.peach.withValues(alpha: 0.0),
            AppColors.peach.withValues(alpha: 0.25),
          ],
          stops: const [0.0, 1.0],
        ),
        borderRadius: borderRadius ?? BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        child: child,
      ),
    );
  }
}
