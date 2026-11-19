import 'package:flutter/material.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';

class ProductReviewTile extends StatelessWidget {
  final String name;
  final String date;
  final int rating;
  final String? title;
  final String comment;

  const ProductReviewTile({
    super.key,
    required this.name,
    required this.date,
    required this.rating,
    this.title,
    required this.comment,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(16.w(context)),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(20.w(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: Offset(0, 2.h(context)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: context.textTheme.titleMedium),
              Text(date, style: context.textTheme.bodySmall),
            ],
          ),
          SizedBox(height: 6.h(context)),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < rating ? Icons.star : Icons.star_border,
                color: AppColors.starYellow,
                size: 14.sp(context),
              );
            }),
          ),
          if (title != null && title!.isNotEmpty) ...[
            SizedBox(height: 8.h(context)),
            Text(title!, style: context.textTheme.titleMedium),
          ],
          if (comment.isNotEmpty) ...[
            SizedBox(height: 6.h(context)),
            Text(comment, style: context.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}
