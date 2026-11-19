import 'package:flutter/material.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/widgets/app_button.dart';
import 'package:ecommerce/core/widgets/app_text_field.dart';

class ProductWriteReviewSection extends StatelessWidget {
  final double userRating;
  final TextEditingController titleController;
  final TextEditingController reviewController;
  final AppStrings strings;
  final ValueChanged<double> onRatingChanged;
  final VoidCallback onSubmitReview;

  const ProductWriteReviewSection({
    super.key,
    required this.userRating,
    required this.titleController,
    required this.reviewController,
    required this.strings,
    required this.onRatingChanged,
    required this.onSubmitReview,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
        SizedBox(height: 20.h(context)),
        Text(strings.writeReview, style: context.textTheme.titleMedium),
        SizedBox(height: 12.h(context)),
        Text(strings.yourRating, style: context.textTheme.bodySmall),
        SizedBox(height: 8.h(context)),
        Row(
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap: () => onRatingChanged(index + 1.0),
              child: Icon(
                index < userRating ? Icons.star : Icons.star_border,
                color: AppColors.starYellow,
                size: 28.sp(context),
              ),
            );
          }),
        ),
        SizedBox(height: 12.h(context)),
        AppTextField(
          controller: titleController,
          hintText: strings.reviewTitleOptional,
          bkgColor: Theme.of(context).cardColor,
        ),
        SizedBox(height: 12.h(context)),
        AppTextField(
          controller: reviewController,
          hintText: strings.tellParents,
          maxLines: 4,
          bkgColor: Theme.of(context).cardColor,
        ),
        SizedBox(height: 16.h(context)),
        AppButton(
          text: strings.postReview,
          onPressed: onSubmitReview,
          height: 50.h(context),
        ),
      ],
    );
  }
}
