import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';

class AppEmptyWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? svgAsset;
  final String? pngAsset;
  final IconData? icon;
  final String? actionText;
  final VoidCallback? onActionPressed;
  final double? size;

  const AppEmptyWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.svgAsset,
    this.pngAsset,
    this.icon,
    this.actionText,
    this.onActionPressed,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w(context)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (svgAsset != null && svgAsset!.isNotEmpty)
              SvgPicture.asset(svgAsset!, width: size ?? 180.w(context))
            else if (pngAsset != null && pngAsset!.isNotEmpty)
              Image.asset(pngAsset!, width: size ?? 180.w(context))
            else if (icon != null)
              Icon(
                icon,
                size: size ?? 64.sp(context),
                color: Colors.grey.shade400,
              ),
            SizedBox(height: 16.h(context)),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium,
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              SizedBox(height: 6.h(context)),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: context.textTheme.labelSmall,
              ),
            ],
            if (actionText != null && onActionPressed != null) ...[
              SizedBox(height: 20.h(context)),
              ElevatedButton(
                onPressed: onActionPressed,
                child: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
