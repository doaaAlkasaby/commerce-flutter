import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ecommerce/core/constants/app_assets.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/widgets/app_price_text.dart';
import 'package:ecommerce/core/widgets/app_text_field.dart';
import 'package:ecommerce/features/cart/models/cart_model.dart';
import 'package:ecommerce/features/checkout/models/checkout_models.dart';
import 'package:ecommerce/features/orders/models/order_model.dart';

class CheckoutPriceSummaryCard extends StatelessWidget {
  final CartModel cart;
  final CheckoutPreviewModel? preview;
  final List<ShippingOptionModel> shippingOptions;
  final String? selectedShippingMethodCode;
  final String? appliedCouponCode;
  final bool isPreviewLoading;
  final bool isUncertainSubmission;
  final String currencyStr;
  final String totalMoneyDisplay;
  final bool isDark;
  final AppStrings strings;
  final TextEditingController couponController;
  final VoidCallback onApplyCoupon;
  final VoidCallback onRemoveCoupon;

  const CheckoutPriceSummaryCard({
    super.key,
    required this.cart,
    this.preview,
    required this.shippingOptions,
    this.selectedShippingMethodCode,
    this.appliedCouponCode,
    required this.isPreviewLoading,
    required this.isUncertainSubmission,
    required this.currencyStr,
    required this.totalMoneyDisplay,
    required this.isDark,
    required this.strings,
    required this.couponController,
    required this.onApplyCoupon,
    required this.onRemoveCoupon,
  });

  Widget _buildPriceRow(
    BuildContext context,
    String label,
    String value,
    bool isDark, {
    Color? valueColor,
    bool isTotal = false,
    Color? bkgColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 20.h(context),
        vertical: bkgColor == null ? 0 : 4.h(context),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: isTotal
                  ? context.textTheme.titleMedium
                  : context.textTheme.bodySmall,
            ),
          ),
          SizedBox(width: 8.w(context)),
          AppPriceTextRow(price: value, currency: '', color: valueColor),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasCouponDiscount =
        preview?.couponDiscount != null &&
        double.tryParse(preview!.couponDiscount) != null &&
        double.parse(preview!.couponDiscount) > 0;

    final selectedMethodName = shippingOptions
        .firstWhere(
          (opt) => opt.methodCode == selectedShippingMethodCode,
          orElse: () => ShippingOptionModel(
            methodCode: selectedShippingMethodCode ?? 'local',
            methodName: strings.standardDelivery,
            currency: currencyStr,
            amount: '0.000',
            totalAmount: '0.000',
            fulfillment: const FulfillmentModel(
              warehouseId: '',
              warehouseCode: '',
            ),
          ),
        )
        .methodName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(strings.priceSummary, style: context.textTheme.titleMedium),
        SizedBox(height: 10.h(context)),

        // Coupon Input Row
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: couponController,
                hintText: strings.enterCouponCodeHint,
                bkgColor: Theme.of(context).cardColor,
                borderColor: Theme.of(context).cardColor,
              ),
            ),
            SizedBox(width: 10.w(context)),
            appliedCouponCode != null
                ? OutlinedButton(
                    onPressed: isUncertainSubmission ? null : onRemoveCoupon,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: AppColors.badgeRed,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w(context),
                        vertical: 11.h(context),
                      ),
                      side: const BorderSide(color: AppColors.badgeRed),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.w(context)),
                      ),
                    ),
                    child: Text(strings.remove),
                  )
                : ElevatedButton(
                    onPressed: isUncertainSubmission ? null : onApplyCoupon,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w(context),
                        vertical: 11.h(context),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.w(context)),
                      ),
                    ),
                    child: Text(
                      strings.apply,
                      style: context.textTheme.whiteTitleSmall,
                    ),
                  ),
          ],
        ),
        SizedBox(height: 14.h(context)),

        // Applied Coupon Banner
        if (appliedCouponCode != null)
          Container(
            margin: EdgeInsets.only(bottom: 12.h(context)),
            padding: EdgeInsets.symmetric(
              horizontal: 16.w(context),
              vertical: 12.h(context),
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.mintTeal.withValues(alpha: 0.15)
                  : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(16.w(context)),
              border: Border.all(
                color: AppColors.mintTeal.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  AppAssets.couponSVG,
                  colorFilter: const ColorFilter.mode(
                    AppColors.mintTeal,
                    BlendMode.srcIn,
                  ),
                  width: 20.sp(context),
                ),
                SizedBox(width: 10.w(context)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appliedCouponCode!,
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.mintTeal
                              : const Color(0xFF2E7D32),
                        ),
                      ),
                      if (hasCouponDiscount)
                        Text(
                          '-${formatOrderMoney(preview!.couponDiscount, currencyStr, strings.isArabic)}',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.mintTeal
                                : const Color(0xFF2E7D32),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.badgeRed,
                    size: 18,
                  ),
                  onPressed: isUncertainSubmission ? null : onRemoveCoupon,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

        // Breakdown Container
        Container(
          padding: EdgeInsets.symmetric(vertical: 20.w(context)),
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
          child: isPreviewLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _buildPriceRow(
                      context,
                      strings
                          .get('subtotal_items')
                          .replaceAll('{itemCount}', '${cart.itemCount}'),
                      formatOrderMoney(
                        preview?.subtotal ?? cart.subtotal,
                        currencyStr,
                        strings.isArabic,
                      ),
                      isDark,
                      valueColor: AppColors.lightTextPrimary,
                    ),
                    if (hasCouponDiscount) ...[
                      SizedBox(height: 8.h(context)),
                      _buildPriceRow(
                        context,
                        strings.get('coupon_discount'),
                        '-${formatOrderMoney(preview!.couponDiscount, currencyStr, strings.isArabic)}',
                        isDark,
                        valueColor: AppColors.mintTeal,
                        bkgColor: AppColors.mintTeal.withValues(alpha: 0.15),
                      ),
                    ],
                    SizedBox(height: 8.h(context)),
                    _buildPriceRow(
                      context,
                      strings
                          .get('delivery_method_summary')
                          .replaceAll('{method}', selectedMethodName),
                      formatOrderMoney(
                        preview?.shippingAmount ?? '0.000',
                        currencyStr,
                        strings.isArabic,
                      ),
                      isDark,
                      valueColor: AppColors.lightTextPrimary,
                    ),
                    if (preview?.taxAmount != null &&
                        double.tryParse(preview!.taxAmount) != null &&
                        double.parse(preview!.taxAmount) > 0) ...[
                      SizedBox(height: 8.h(context)),
                      _buildPriceRow(
                        context,
                        strings.taxLabel,
                        formatOrderMoney(
                          preview!.taxAmount,
                          currencyStr,
                          strings.isArabic,
                        ),
                        isDark,
                        valueColor: AppColors.lightTextPrimary,
                      ),
                    ],
                    Divider(height: 24.h(context), color: Colors.grey.shade200),
                    _buildPriceRow(
                      context,
                      strings.total,
                      formatOrderMoney(
                        preview?.totalAmount ?? cart.subtotal,
                        currencyStr,
                        strings.isArabic,
                      ),
                      isDark,
                      isTotal: true,
                    ),
                  ],
                ),
        ),

        // Savings Badge
        if (hasCouponDiscount) ...[
          SizedBox(height: 12.h(context)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 16.w(context),
              vertical: 10.h(context),
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.mintTeal.withValues(alpha: 0.15)
                  : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(14.w(context)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF2E7D32),
                  size: 18,
                ),
                SizedBox(width: 8.w(context)),
                Expanded(
                  child: Text(
                    strings.isArabic
                        ? 'وفّرت ${formatOrderMoney(preview!.couponDiscount, currencyStr, true)} مع الخصم ${appliedCouponCode ?? ""}'
                        : 'You saved ${formatOrderMoney(preview!.couponDiscount, currencyStr, false)} with ${appliedCouponCode ?? ""}',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF2E7D32),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
