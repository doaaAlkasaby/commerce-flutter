import 'package:flutter/material.dart';
import 'package:ecommerce/core/constants/app_colors.dart';

class AppImagePlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final IconData icon;

  const AppImagePlaceholder({
    super.key,
    this.width,
    this.height,
    this.icon = Icons.image_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: Icon(icon, size: 24, color: AppColors.primary)
        ),
      ),
    );
  }
}
