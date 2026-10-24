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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
