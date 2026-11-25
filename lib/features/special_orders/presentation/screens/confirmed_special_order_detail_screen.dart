import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/widgets/app_error_widget.dart';
import 'package:ecommerce/core/widgets/app_price_text.dart';
import 'package:ecommerce/core/widgets/app_scaffold.dart';
import '../providers/special_orders_provider.dart';

class ConfirmedSpecialOrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const ConfirmedSpecialOrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(confirmedSpecialOrderDetailProvider(orderId));
    final localizationAsync = ref.watch(appLocalizationLoaderProvider);
    final currentLang = ref.watch(languageProvider);
    final strings = AppStrings(localizationAsync.value ?? {}, currentLang);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      appBar: AppBar(
        title: Text(strings.confirmedSpecialOrderDetails),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: orderAsync.when(
          data: (order) {
            if (order == null) {
              return Center(child: Text(strings.failedToLoadSpecialOrders));
            }

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.all(20.w(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Summary Header Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w(context)),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardBg : AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16.w(context)),
                      border: Border.all(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${strings.get('order_number_hash').replaceAll('{number}', '')}${order.orderNumber}',
                              style: context.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w(context),
                                vertical: 4.h(context),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12.w(context)),
                              ),
                              child: Text(
                                order.status,
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h(context)),
                        Text(
                          order.createdAt,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        SizedBox(height: 12.h(context)),
                        Row(
                          children: [
                            Text(
                              '${strings.paymentStatus}: ',
                              style: context.textTheme.bodySmall,
                            ),
                            Text(
                              order.paymentStatus,
                              style: context.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h(context)),

                  // Price Breakdown
                  Text(
                    strings.priceSummary,
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h(context)),

                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w(context)),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardBg : AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16.w(context)),
                      border: Border.all(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(strings.subtotalLabel, style: context.textTheme.bodyMedium),
                            AppPriceTextRow(price: order.subtotal, currency: order.currency),
                          ],
                        ),
                        SizedBox(height: 8.h(context)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(strings.shippingLabel, style: context.textTheme.bodyMedium),
                            AppPriceTextRow(price: order.shippingFee, currency: order.currency),
                          ],
                        ),
                        SizedBox(height: 8.h(context)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(strings.taxLabel, style: context.textTheme.bodyMedium),
                            AppPriceTextRow(price: order.taxAmount, currency: order.currency),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              strings.total,
                              style: context.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            AppPriceTextRow(
                              price: order.totalAmount,
                              currency: order.currency,
                              isLarge: true,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => AppErrorWidget(
            message: strings.failedToLoadSpecialOrders,
            onRetry: () => ref.invalidate(confirmedSpecialOrderDetailProvider(orderId)),
          ),
        ),
      ),
    );
  }
}
