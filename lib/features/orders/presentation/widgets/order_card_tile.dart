import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/features/orders/models/order_model.dart';
import '../../../../core/widgets/app_price_text.dart';
import '../screens/order_details_screen.dart';
import 'order_progress_stepper.dart';

class OrderCardTile extends StatelessWidget {
  final OrderModel order;
  final String fallbackCurrency;
  final AppStrings strings;
  final bool isDark;

  const OrderCardTile({
    super.key,
    required this.order,
    required this.fallbackCurrency,
    required this.strings,
    required this.isDark,
  });

  Color _getStatusBgColor(String status) {
    switch (status.toUpperCase()) {
      case 'DELIVERED':
      case 'COMPLETED':
        return const Color(0xFFE8F5E9);
      case 'SHIPPED':
        return const Color(0xFFE3F2FD);
      case 'PROCESSING':
        return const Color(0xFFFFF3E0);
      case 'CONFIRMED':
        return const Color(0xFFFBEAEA);
      case 'PENDING':
        return const Color(0xFFFFF8E1);
      case 'CANCELLED':
        return const Color(0xFFEEEEEE);
      default:
        return const Color(0xFFFBEAEA);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toUpperCase()) {
      case 'DELIVERED':
      case 'COMPLETED':
        return const Color(0xFF2E7D32);
      case 'SHIPPED':
        return const Color(0xFF1565C0);
      case 'PROCESSING':
        return const Color(0xFFE65100);
      case 'CONFIRMED':
        return AppColors.primary;
      case 'PENDING':
        return const Color(0xFFF57F17);
      case 'CANCELLED':
        return Colors.grey.shade700;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusUpper = order.status.toUpperCase();
    final isDelivered =
        statusUpper == 'DELIVERED' || statusUpper == 'COMPLETED';
    final displayCurrency = order.currency.isNotEmpty
        ? order.currency
        : fallbackCurrency;
    final humanDate = order.formatHumanDate(strings.isArabic);
    final quietId = order.orderNumber;
    final city =
        order.shippingAddress?.city ??
        strings.defaultCityCountry.split(',').first;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h(context)),
      padding: EdgeInsets.all(18.w(context)),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Date & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(humanDate, style: context.textTheme.titleMedium),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10.w(context),
                  vertical: 4.h(context),
                ),
                decoration: BoxDecoration(
                  color: _getStatusBgColor(statusUpper),
                  borderRadius: BorderRadius.circular(6.w(context)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6.w(context),
                      height: 6.w(context),
                      decoration: BoxDecoration(
                        color: _getStatusTextColor(statusUpper),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 6.w(context)),
                    Text(
                      order.status,
                      style: TextStyle(
                        fontSize: 11.sp(context),
                        fontWeight: FontWeight.bold,
                        color: _getStatusTextColor(statusUpper),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h(context)),
          // Quiet ID
          Text(
            quietId,
            style: context.textTheme.labelSmall?.copyWith(
              fontSize: 10.sp(context),
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 14.h(context)),

          // Thumbnail Row
          Row(
            children: [
              ...order.items
                  .take(3)
                  .map(
                    (item) => Padding(
                      padding: EdgeInsets.only(right: 8.w(context)),
                      child: Container(
                        width: 40.w(context),
                        height: 40.h(context),
                        decoration: BoxDecoration(
                          color: AppColors.lightCategoryBg,
                          borderRadius: BorderRadius.circular(11.w(context)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11.w(context)),
                          child: CachedNetworkImage(
                            imageUrl: item.imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => const Icon(
                              Icons.shopping_bag_outlined,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              if (order.items.length > 3)
                Container(
                  width: 40.w(context),
                  height: 40.h(context),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(11.w(context)),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      style: BorderStyle.solid,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '+${order.items.length - 3}',
                    style: context.textTheme.titleSmall,
                  ),
                ),
            ],
          ),
          SizedBox(height: 10.h(context)),

          // Sub-info
          Text(
            strings
                .get('order_items_city')
                .replaceAll('{itemsCount}', '${order.items.length}')
                .replaceAll('{city}', city),
            style: context.textTheme.bodySmall,
          ),
          SizedBox(height: 14.h(context)),

          // Progress Stepper Timeline
          if (!isDelivered) ...[
            OrderProgressStepper(currentStatus: statusUpper, strings: strings),
            SizedBox(height: 12.h(context)),
            // ETA Banner
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: 12.w(context),
                vertical: 8.h(context),
              ),
              decoration: BoxDecoration(
                color: AppColors.darkBkg,
                borderRadius: BorderRadius.circular(12.w(context)),
              ),
              child: Text(
                '${strings.arrives} 18–20 Nov · ${strings.standardDelivery}',
                style: context.textTheme.bodySmall?.copyWith(
                  color: AppColors.lightTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 16.h(context)),
          ],

          const Divider(height: 1),
          SizedBox(height: 12.h(context)),

          // Action Zone (Total + Buttons)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strings.total, style: context.textTheme.labelSmall),
                  SizedBox(height: 2.h(context)),
                  AppPriceTextRow(
                    price: formatOrderMoney(
                      order.totalAmount,
                      displayCurrency,
                      strings.isArabic,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OrderDetailsScreen(orderId: order.id),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w(context),
                        vertical: 10.h(context),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.w(context)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          isDelivered ? strings.reorder : strings.trackOrder,
                          style: context.textTheme.whiteLabelMedium,
                        ),
                        SizedBox(width: 4.w(context)),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 10.sp(context),
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
