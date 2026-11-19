import 'package:flutter/material.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';

class OrderProgressStepper extends StatelessWidget {
  final String currentStatus;
  final AppStrings strings;

  const OrderProgressStepper({
    super.key,
    required this.currentStatus,
    required this.strings,
  });

  int _getStatusStepIndex(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 0;
      case 'CONFIRMED':
        return 1;
      case 'PROCESSING':
        return 2;
      case 'SHIPPED':
        return 3;
      case 'DELIVERED':
      case 'COMPLETED':
        return 4;
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeStep = _getStatusStepIndex(currentStatus);
    final stepLabels = [
      strings.confirmedStatus,
      strings.processingStatus,
      strings.shippedStatus,
      strings.deliveredStatus,
    ];

    const totalSteps = 4;
    final isArabic = strings.isArabic;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(totalSteps * 2 - 1, (index) {
            if (index.isEven) {
              // Circle Node
              final stepIndex = index ~/ 2;
              final isCompleted = stepIndex <= activeStep;
              final isCurrent = stepIndex == activeStep;

              if (isCurrent) {
                return Container(
                  width: 22.w(context),
                  height: 22.w(context),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 12.w(context),
                    height: 12.w(context),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }

              return Container(
                width: 12.w(context),
                height: 12.w(context),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.primary
                      : const Color(0xFFF8F4EE),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted
                        ? AppColors.primary
                        : const Color(0xFFE2D8CC),
                    width: 2,
                  ),
                ),
              );
            } else {
              // Connecting Line between nodes
              final lineIndex = index ~/ 2;
              final isCompletedLine = lineIndex < activeStep;

              return Expanded(
                child: Container(
                  height: 2.h(context),
                  color: isCompletedLine
                      ? AppColors.primary
                      : const Color(0xFFE2D8CC),
                ),
              );
            }
          }),
        ),
        SizedBox(height: 8.h(context)),
        // Label Row matching exact node positions
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(totalSteps, (index) {
            final isCompleted = index <= activeStep;
            final isCurrent = index == activeStep;

            TextAlign align = TextAlign.center;
            if (index == 0) {
              align = isArabic ? TextAlign.right : TextAlign.left;
            } else if (index == totalSteps - 1) {
              align = isArabic ? TextAlign.left : TextAlign.right;
            }

            return Expanded(
              child: Text(
                stepLabels[index],
                textAlign: align,
                style: TextStyle(
                  fontSize: 10.sp(context),
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  color: isCompleted
                      ? AppColors.primary
                      : const Color(0xFF9E8E81),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
