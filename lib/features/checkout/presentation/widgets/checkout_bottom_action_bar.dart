import 'package:flutter/material.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/widgets/app_button.dart';
import 'package:ecommerce/features/cart/models/cart_model.dart';
import 'package:ecommerce/features/checkout/models/checkout_models.dart';

class CheckoutBottomActionBar extends StatelessWidget {
  final CartModel cart;
  final CheckoutPreviewModel? preview;
  final bool isSubmitting;
  final bool isPreviewLoading;
  final bool isUncertainSubmission;
  final String? previewError;
  final String totalMoneyDisplay;
  final bool isDark;
  final AppStrings strings;
  final Future<void> Function() onPlaceOrder;

  const CheckoutBottomActionBar({
    super.key,
    required this.cart,
    this.preview,
    required this.isSubmitting,
    required this.isPreviewLoading,
    required this.isUncertainSubmission,
    this.previewError,
    required this.totalMoneyDisplay,
    required this.isDark,
    required this.strings,
    required this.onPlaceOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          20.w(context),
          12.h(context),
          20.w(context),
          24.h(context),
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: Offset(0, -4.h(context)),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              strings.termsAcceptNotice,
              textAlign: TextAlign.center,
              style: context.textTheme.labelSmall,
            ),
            SizedBox(height: 8.h(context)),
            AppButton(
              text: isUncertainSubmission
                  ? strings.retryPlacingOrder
                  : strings
                        .get('place_order_with_total')
                        .replaceAll('{total}', totalMoneyDisplay),
              isLoading: isSubmitting,
              onPressed:
                  (isSubmitting ||
                      isPreviewLoading ||
                      preview == null ||
                      previewError != null)
                  ? null
                  : onPlaceOrder,
            ),
          ],
        ),
      ),
    );
  }
}
