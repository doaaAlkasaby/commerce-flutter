import 'package:flutter/material.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/features/orders/models/order_model.dart';

class OrderStatusTimelineCard extends StatelessWidget {
  final OrderModel order;
  final String shippingMethod;
  final AppStrings strings;
  final bool isArabic;
  final bool isDark;

  const OrderStatusTimelineCard({
    super.key,
    required this.order,
    required this.shippingMethod,
    required this.strings,
    required this.isArabic,
    required this.isDark,
  });

  String _formatStatusSubtitle(String status, AppStrings strings) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return strings.statusSubtitlePending;
      case 'CONFIRMED':
        return strings.statusSubtitleConfirmed;
      case 'PROCESSING':
        return strings.statusSubtitleProcessing;
      case 'SHIPPED':
        return strings.statusSubtitleShipped;
      case 'DELIVERED':
        return strings.statusSubtitleDelivered;
      case 'COMPLETED':
        return strings.statusSubtitleCompleted;
      case 'CANCELLED':
        return strings.statusSubtitleCancelled;
      default:
        return strings.statusSubtitleInProgress;
    }
  }

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
      case 'CANCELLED':
        return -1;
      default:
        return 1;
    }
  }

  Widget _buildVerticalTimeline(BuildContext context) {
    final statusUpper = order.status.toUpperCase();
    final activeStep = _getStatusStepIndex(statusUpper);
    final isCancelled = statusUpper == 'CANCELLED';

    final steps = [
      {
        'title': strings.orderPlacedStep,
        'subtitle': order.formatHumanDate(isArabic),
        'isDone': activeStep >= 0 && !isCancelled,
        'isCurrent': activeStep == 0 && !isCancelled,
      },
      {
        'title': strings.confirmedStatus,
        'subtitle': isCancelled
            ? strings.orderCancelled
            : strings.estimatedDispatch,
        'isDone': activeStep >= 1 && !isCancelled,
        'isCurrent': activeStep == 1 && !isCancelled,
      },
      {
        'title': strings.processingStatus,
        'subtitle': strings.statusSubtitlePacking,
        'isDone': activeStep >= 2 && !isCancelled,
        'isCurrent': activeStep == 2 && !isCancelled,
      },
      {
        'title': strings.shippedStatus,
        'subtitle': strings.trackingLinkHint,
        'isDone': activeStep >= 3 && !isCancelled,
        'isCurrent': activeStep == 3 && !isCancelled,
      },
      {
        'title': statusUpper == 'COMPLETED'
            ? strings.completedStatus
            : strings.deliveredStatus,
        'subtitle': strings.estimatedDeliveryRange,
        'isDone': activeStep >= 4 && !isCancelled,
        'isCurrent': activeStep == 4 && !isCancelled,
      },
    ];

    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isDone = step['isDone'] as bool;
        final isCurrent = step['isCurrent'] as bool;
        final isLast = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 16.w(context),
                  height: 16.w(context),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? Colors.greenAccent
                        : (isDone ? Colors.greenAccent : Colors.white),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDone || isCurrent
                          ? Colors.green.withValues(alpha: 0.4)
                          : Colors.grey.shade300,
                      width: 3,
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2.w(context),
                    height: 36.h(context),
                    color: isDone
                        ? Colors.green.withValues(alpha: 0.8)
                        : Colors.grey.shade300,
                  ),
              ],
            ),
            SizedBox(width: 12.w(context)),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 12.h(context)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step['title'] as String,
                      style: isCurrent || isDone
                          ? context.textTheme.titleSmall?.copyWith(
                              color: isCurrent
                                  ? Colors.green
                                  : AppColors.lightTextPrimary,
                            )
                          : context.textTheme.bodySmall,
                    ),
                    SizedBox(height: 2.h(context)),
                    Text(
                      step['subtitle'] as String,
                      style: context.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w(context)),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(24.w(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: Offset(0, 4.h(context)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8.w(context),
                    height: 8.w(context),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 6.w(context)),
                  Text(
                    order.status,
                    style: context.textTheme.titleSmall?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    strings.arrives1820Nov,
                    style: context.textTheme.titleSmall,
                  ),
                  Text(shippingMethod, style: context.textTheme.labelSmall),
                ],
              ),
            ],
          ),
          SizedBox(height: 2.h(context)),
          Text(
            _formatStatusSubtitle(order.status, strings),
            style: context.textTheme.bodySmall,
          ),
          SizedBox(height: 16.h(context)),

          // Vertical Timeline
          _buildVerticalTimeline(context),
        ],
      ),
    );
  }
}
