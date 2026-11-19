import 'package:flutter/material.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/features/product/models/review_models.dart';

class ReviewCardTile extends StatelessWidget {
  final ProductReviewModel review;
  final bool isOwner;
  final bool isDark;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ReviewCardTile({
    super.key,
    required this.review,
    required this.isOwner,
    required this.isDark,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h(context)),
      padding: EdgeInsets.all(16.w(context)),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(20.w(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: Offset(0, 3.h(context)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16.w(context),
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        review.user.name.isNotEmpty
                            ? review.user.name[0].toUpperCase()
                            : 'P',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w(context)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review.user.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.titleMedium,
                          ),
                          Text(
                            review.createdAt.contains('T')
                                ? review.createdAt.split('T').first
                                : review.createdAt,
                            style: context.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Row(
                    children: List.generate(5, (i) {
                      return Icon(
                        i < review.rating ? Icons.star : Icons.star_border,
                        color: AppColors.starYellow,
                        size: 16.sp(context),
                      );
                    }),
                  ),
                  if (isOwner) ...[
                    SizedBox(width: 4.w(context)),
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      onPressed: onEdit,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: AppColors.badgeRed,
                      ),
                      onPressed: onDelete,
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (review.title != null && review.title!.isNotEmpty) ...[
            SizedBox(height: 10.h(context)),
            Text(review.title!, style: context.textTheme.titleMedium),
          ],
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            SizedBox(height: 6.h(context)),
            Text(review.comment!, style: context.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}
