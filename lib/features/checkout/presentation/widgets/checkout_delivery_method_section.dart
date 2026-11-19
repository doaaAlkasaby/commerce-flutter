import 'package:flutter/material.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/widgets/app_price_text.dart';
import 'package:ecommerce/features/checkout/models/checkout_models.dart';

class CheckoutDeliveryMethodSection extends StatelessWidget {
  final List<ShippingOptionModel> shippingOptions;
  final String? selectedShippingMethodCode;
  final String? previewError;
  final bool isPreviewLoading;
  final bool isUncertainSubmission;
  final String currencyStr;
  final bool isDark;
  final AppStrings strings;
  final ValueChanged<String> onSelectShippingMethod;

  const CheckoutDeliveryMethodSection({
    super.key,
    required this.shippingOptions,
    required this.selectedShippingMethodCode,
    this.previewError,
    required this.isPreviewLoading,
    required this.isUncertainSubmission,
    required this.currencyStr,
    required this.isDark,
    required this.strings,
    required this.onSelectShippingMethod,
  });

  String _formatDeliveryEstimate(String methodCode, AppStrings strings) {
    final code = methodCode.toLowerCase();
    if (code.contains('local') || code.contains('express')) {
      return strings.arrivesTomorrow;
    }
    return strings.arrives1820Nov;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10.h(context)),
        Text(strings.deliveryMethod, style: context.textTheme.titleMedium),
        SizedBox(height: 8.h(context)),
        if (shippingOptions.isNotEmpty)
          Container(
            padding: EdgeInsets.fromLTRB(
              16.w(context),
              16.w(context),
              16.w(context),
              4.w(context),
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardBg : Colors.white,
              borderRadius: BorderRadius.circular(20.w(context)),
            ),
            child: Column(
              children: shippingOptions.map((opt) {
                final isSelected = opt.methodCode == selectedShippingMethodCode;
                return GestureDetector(
                  onTap: isUncertainSubmission
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(strings.uncertainOrderAttempt),
                            ),
                          );
                        }
                      : () => onSelectShippingMethod(opt.methodCode),
                  child: Container(
                    margin: EdgeInsets.only(bottom: 10.h(context)),
                    padding: EdgeInsets.fromLTRB(
                      0,
                      6.h(context),
                      8.h(context),
                      6.w(context),
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.lightBackground
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14.w(context)),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.peach
                            : Colors.transparent,
                        width: isSelected ? 1 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Radio<String>(
                          value: opt.methodCode,
                          groupValue: selectedShippingMethodCode,
                          activeColor: AppColors.primary,
                          onChanged: isUncertainSubmission
                              ? (val) {}
                              : (val) {
                                  if (val != null) onSelectShippingMethod(val);
                                },
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                opt.methodName,
                                style: context.textTheme.titleSmall,
                              ),
                              SizedBox(height: 2.h(context)),
                              Text(
                                _formatDeliveryEstimate(
                                  opt.methodCode,
                                  strings,
                                ),
                                style: context.textTheme.bodyMini?.copyWith(
                                  color: AppColors.badgeRed,
                                ),
                              ),
                            ],
                          ),
                        ),
                        (double.tryParse(opt.amount) ?? -1) == 0
                            ? Text(
                                strings.isArabic ? 'مجاني' : 'Free',
                                style: context.textTheme.titleSmall?.copyWith(
                                  color: AppColors.mintTeal,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : AppPriceTextRow(
                                price: opt.amount,
                                currency: currencyStr,
                              ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          )
        else
          Container(
            padding: EdgeInsets.all(16.w(context)),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkCardBg
                  : (previewError != null
                        ? AppColors.badgeRed.withValues(alpha: 0.1)
                        : Theme.of(context).cardColor),
              borderRadius: BorderRadius.circular(12.w(context)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isPreviewLoading && previewError == null)
                  SizedBox(
                    width: 18.w(context),
                    height: 18.w(context),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                else
                  Icon(
                    Icons.warning_amber_rounded,
                    color: previewError != null ? AppColors.badgeRed : null,
                  ),
                SizedBox(width: 8.w(context)),
                Flexible(
                  child: Text(
                    previewError ??
                        (isPreviewLoading
                            ? strings.calculatingShipping
                            : strings.failedToCalcShipping),
                    style: TextStyle(
                      color: previewError != null ? AppColors.badgeRed : null,
                      fontSize: 12.sp(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
