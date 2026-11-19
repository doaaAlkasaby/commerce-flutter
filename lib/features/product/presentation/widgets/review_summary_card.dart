import 'package:flutter/material.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/features/product/models/review_models.dart';

class ReviewSummaryCard extends StatelessWidget {
  final ProductRatingSummaryModel summary;
  final AppStrings strings;
  final bool isDark;

  const ReviewSummaryCard({
    super.key,
    required this.summary,
    required this.strings,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(20.w(context)),
      padding: EdgeInsets.all(20.w(context)),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(24.w(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: Offset(0, 4.h(context)),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                summary.average.toStringAsFixed(1),
                style: context.textTheme.primaryDisplayLarge,
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < summary.average.round()
                        ? Icons.star
                        : Icons.star_border,
                    color: AppColors.starYellow,
                    size: 16.sp(context),
                  );
                }),
              ),
              SizedBox(height: 4.h(context)),
              Text(
                '${summary.count} ${strings.reviewsCount}',
                style: context.textTheme.labelSmall,
              ),
            ],
          ),
          SizedBox(width: 24.w(context)),
          Expanded(
            child: Column(
              children: List.generate(5, (index) {
                final starNum = 5 - index;
                final count = summary.distribution[starNum] ?? 0;
                final pct = summary.count > 0 ? count / summary.count : 0.0;
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 2.h(context)),
                  child: Row(
                    children: [
                      Text('$starNum', style: context.textTheme.bodySmall),
                      SizedBox(width: 4.w(context)),
                      Icon(
                        Icons.star,
                        color: AppColors.starYellow,
                        size: 12.sp(context),
                      ),
                      SizedBox(width: 8.w(context)),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4.w(context)),
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation(
                              AppColors.primary,
                            ),
                            minHeight: 6.h(context),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w(context)),
                      Text('$count', style: context.textTheme.bodySmall),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
