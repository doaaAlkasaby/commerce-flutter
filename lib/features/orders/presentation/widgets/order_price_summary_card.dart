import 'package:flutter/material.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/widgets/app_price_text.dart';
import 'package:ecommerce/features/orders/models/order_model.dart';

class OrderPriceSummaryCard extends StatelessWidget {
  final OrderModel order;
  final String shippingMethod;
  final String displayCurrency;
  final AppStrings strings;
  final bool isDark;

  const OrderPriceSummaryCard({
    super.key,
    required this.order,
    required this.shippingMethod,
    required this.displayCurrency,
    required this.strings,
    required this.isDark,
  });

  Widget _buildPriceRow(
    BuildContext context,
    String label,
    String value,
    bool isDark, {
    Color? valueColor,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: isTotal
                ? context.textTheme.titleMedium
                : context.textTheme.bodyMedium,
          ),
        ),
        SizedBox(width: 8.w(context)),
        AppPriceTextRow(
          price: value,
          currency: "",
          priceStyle: isTotal ? null : context.textTheme.titleMedium,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(strings.priceSummary, style: context.textTheme.titleLarge),
        SizedBox(height: 8.h(context)),
        Container(
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
          child: Column(
            children: [
              _buildPriceRow(
                context,
                strings.subtotalLabel,
                formatOrderMoney(
                  order.subtotal,
                  displayCurrency,
                  strings.isArabic,
                ),
                isDark,
              ),
              SizedBox(height: 10.h(context)),
              _buildPriceRow(
                context,
                shippingMethod,
                formatOrderMoney(
                  order.shippingAmount,
                  displayCurrency,
                  strings.isArabic,
                ),
                isDark,
              ),
              if (double.tryParse(order.discountAmount) != null &&
                  double.parse(order.discountAmount) > 0) ...[
                SizedBox(height: 10.h(context)),
                _buildPriceRow(
                  context,
                  strings.discountLabel,
                  '-${formatOrderMoney(order.discountAmount, displayCurrency, strings.isArabic)}',
                  isDark,
                  valueColor: AppColors.mintTeal,
                ),
              ],
              if (double.tryParse(order.taxAmount) != null &&
                  double.parse(order.taxAmount) > 0) ...[
                SizedBox(height: 10.h(context)),
                _buildPriceRow(
                  context,
                  strings.taxLabel,
                  formatOrderMoney(
                    order.taxAmount,
                    displayCurrency,
                    strings.isArabic,
                  ),
                  isDark,
                ),
              ],
              SizedBox(height: 12.h(context)),
              Divider(height: 1, color: Colors.grey.shade200),
              SizedBox(height: 12.h(context)),
              _buildPriceRow(
                context,
                strings.total,
                formatOrderMoney(
                  order.totalAmount,
                  displayCurrency,
                  strings.isArabic,
                ),
                isDark,
                isTotal: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
