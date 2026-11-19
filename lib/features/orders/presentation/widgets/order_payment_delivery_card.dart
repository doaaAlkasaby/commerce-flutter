import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/app_error_utils.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/features/checkout/models/payment_models.dart';
import 'package:ecommerce/features/checkout/presentation/providers/payment_provider.dart';
import 'package:ecommerce/features/checkout/utils/payment_url_launcher.dart';
import 'package:ecommerce/features/orders/models/order_model.dart';

class OrderPaymentDeliveryCard extends ConsumerStatefulWidget {
  final OrderModel order;
  final PaymentModel? primaryPayment;
  final bool canInitiate;
  final bool canOpenLink;
  final bool canVerify;
  final bool isVerifying;
  final AppStrings strings;
  final bool isDark;

  const OrderPaymentDeliveryCard({
    super.key,
    required this.order,
    this.primaryPayment,
    required this.canInitiate,
    required this.canOpenLink,
    required this.canVerify,
    required this.isVerifying,
    required this.strings,
    required this.isDark,
  });

  @override
  ConsumerState<OrderPaymentDeliveryCard> createState() =>
      _OrderPaymentDeliveryCardState();
}

class _OrderPaymentDeliveryCardState
    extends ConsumerState<OrderPaymentDeliveryCard> {
  bool _isInitiating = false;

  String _formatPaymentMethod(String? rawMethod, AppStrings strings) {
    if (rawMethod == null || rawMethod.isEmpty) return strings.codMethodLabel;
    switch (rawMethod.toUpperCase()) {
      case 'CASH_ON_DELIVERY':
        return strings.codMethodLabel;
      case 'CARD':
      case 'MYFATOORAH':
        return strings.cardMethodLabel;
      default:
        return rawMethod.replaceAll('_', ' ');
    }
  }

  String _formatPaymentSubtitle(String? rawMethod, AppStrings strings) {
    if (rawMethod == null || rawMethod.toUpperCase() == 'CASH_ON_DELIVERY') {
      return strings.payCourierOnDelivery;
    }
    return strings.paidOnlineViaGateway;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w(context)),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkCardBg : Colors.white,
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
          // Payment Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.strings.paymentStatus,
                    style: context.textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10.h(context)),
                  Text(
                    _formatPaymentMethod(
                      widget.primaryPayment?.method,
                      widget.strings,
                    ),
                    style: context.textTheme.titleSmall,
                  ),
                  SizedBox(height: 4.h(context)),
                  Text(
                    _formatPaymentSubtitle(
                      widget.primaryPayment?.method,
                      widget.strings,
                    ),
                    style: context.textTheme.labelMedium,
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10.w(context),
                  vertical: 4.h(context),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12.w(context)),
                ),
                child: Text(
                  widget.primaryPayment?.status ?? widget.order.paymentStatus,
                  style: context.textTheme.badgeTextOrange,
                ),
              ),
            ],
          ),

          if (widget.canInitiate || widget.canOpenLink || widget.canVerify) ...[
            SizedBox(height: 12.h(context)),
            if (widget.canInitiate)
              ElevatedButton.icon(
                onPressed: _isInitiating
                    ? null
                    : () async {
                        setState(() => _isInitiating = true);
                        try {
                          final initiated = await ref
                              .read(
                                orderPaymentsControllerProvider(
                                  widget.order.id,
                                ).notifier,
                              )
                              .initiatePayment(widget.primaryPayment!.id);
                          if (initiated?.checkoutUrl != null &&
                              initiated!.checkoutUrl!.isNotEmpty) {
                            await PaymentUrlLauncher.launchPaymentUrl(
                              initiated.checkoutUrl!,
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppErrorUtils.extractErrorMessage(e),
                                ),
                              ),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isInitiating = false);
                        }
                      },
                icon: const Icon(Icons.payment, size: 16),
                label: Text(widget.strings.resumePayment),
              ),
            if (widget.canOpenLink)
              OutlinedButton.icon(
                onPressed: () => PaymentUrlLauncher.launchPaymentUrl(
                  widget.primaryPayment!.checkoutUrl!,
                ),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text(widget.strings.openPaymentLink),
              ),
            if (widget.canVerify)
              ElevatedButton.icon(
                onPressed: widget.isVerifying
                    ? null
                    : () async {
                        try {
                          await ref
                              .read(
                                orderPaymentsControllerProvider(
                                  widget.order.id,
                                ).notifier,
                              )
                              .verifyPayment(widget.primaryPayment!.id);
                        } catch (_) {}
                      },
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(widget.strings.verifyPaymentStatus),
              ),
          ],

          SizedBox(height: 14.h(context)),
          Divider(height: 1, color: Colors.grey.shade200),
          SizedBox(height: 14.h(context)),

          // Deliver To Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.strings.deliverToLabel,
                style: context.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10.h(context)),
              Text(
                widget.order.shippingAddress != null
                    ? '${widget.order.shippingAddress!.addressLine1}${widget.order.shippingAddress!.addressLine2 != null && widget.order.shippingAddress!.addressLine2!.isNotEmpty ? ", " + widget.order.shippingAddress!.addressLine2! : ""}'
                    : widget.strings.developmentDeliveryAddress,
                style: context.textTheme.titleSmall,
              ),
              SizedBox(height: 4.h(context)),
              Text(
                widget.order.shippingAddress != null
                    ? '${widget.order.shippingAddress!.city}${widget.order.shippingAddress!.countryCode.isNotEmpty ? ", " + widget.order.shippingAddress!.countryCode : ""}'
                    : widget.strings.defaultCityCountry,
                style: context.textTheme.labelMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
