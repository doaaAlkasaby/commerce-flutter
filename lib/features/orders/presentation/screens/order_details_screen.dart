import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/config/tenant_config.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/widgets/app_error_widget.dart';
import 'package:ecommerce/features/auth/presentation/providers/user_provider.dart';
import 'package:ecommerce/features/checkout/presentation/providers/payment_provider.dart';
import 'package:ecommerce/features/orders/models/order_model.dart';
import 'package:ecommerce/features/orders/presentation/providers/orders_provider.dart';
import '../widgets/order_items_list_card.dart';
import '../widgets/order_payment_delivery_card.dart';
import '../widgets/order_price_summary_card.dart';
import '../widgets/order_status_timeline_card.dart';

class OrderDetailsScreen extends ConsumerStatefulWidget {
  final String? orderId;

  const OrderDetailsScreen({super.key, this.orderId});

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed &&
        widget.orderId != null &&
        widget.orderId!.isNotEmpty) {
      final requestTenantSlug = ref.read(selectedTenantSlugProvider);
      final requestUserId = ref.read(currentUserProvider).value?.id;

      await ref
          .read(orderPaymentsControllerProvider(widget.orderId!).notifier)
          .refresh();

      if (!mounted ||
          ref.read(selectedTenantSlugProvider) != requestTenantSlug ||
          ref.read(currentUserProvider).value?.id != requestUserId) {
        return;
      }

      final paymentData = ref
          .read(orderPaymentsControllerProvider(widget.orderId!))
          .value;
      final paymentsList = paymentData?.payments ?? [];
      final primaryPayment = paymentsList.isNotEmpty
          ? paymentsList.first
          : null;

      if (primaryPayment != null &&
          primaryPayment.provider == 'MYFATOORAH' &&
          primaryPayment.providerPaymentId != null &&
          primaryPayment.providerPaymentId!.isNotEmpty &&
          [
            'PENDING',
            'REQUIRES_ACTION',
            'UNKNOWN',
          ].contains(primaryPayment.status) &&
          !(paymentData?.isVerifying(primaryPayment.id) ?? false)) {
        try {
          await ref
              .read(orderPaymentsControllerProvider(widget.orderId!).notifier)
              .verifyPayment(primaryPayment.id);
        } catch (_) {}
      }
    }
  }

  Widget _buildDefaultOrderView(BuildContext context, AppStrings strings) {
    return Center(
      child: Text(strings.orderDetails, style: context.textTheme.bodyMedium),
    );
  }

  PreferredSizeWidget _appbarWidget(
    bool isDark,
    bool isArabic,
    AppStrings strings,
    AsyncValue<OrderModel?>? orderAsync,
  ) {
    return AppBar(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : const Color(0xFFF8F4EE),
      elevation: 0,
      leading: Padding(
        padding: EdgeInsets.all(8.w(context)),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: Offset(0, 2.h(context)),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              size: 16.sp(context),
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          orderAsync?.when(
                data: (order) {
                  if (order == null) return Text(strings.orderDetails);
                  final shortRef = order.id.startsWith('ord-')
                      ? order.id
                      : (order.orderNumber.length > 12
                            ? order.orderNumber.split('-').last
                            : order.orderNumber);
                  return Text(
                    strings
                        .get('order_number_hash')
                        .replaceAll('{number}', shortRef),
                    style: context.textTheme.titleMedium,
                  );
                },
                loading: () => Text(strings.orderDetails),
                error: (_, __) => Text(strings.orderDetails),
              ) ??
              Text(strings.orderDetails),
          orderAsync?.when(
                data: (order) {
                  if (order == null) return const SizedBox.shrink();
                  return Text(
                    '${order.formatHumanDate(isArabic)} · GMT+3',
                    style: context.textTheme.labelSmall,
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      actions: [
        Container(
          margin: EdgeInsets.only(right: 8.w(context)),
          width: 36.w(context),
          height: 36.w(context),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(Icons.copy_rounded, size: 16.sp(context)),
            onPressed: () {
              final fullId = widget.orderId ?? '';
              if (fullId.isNotEmpty) {
                Clipboard.setData(ClipboardData(text: fullId));
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(strings.copiedOrderId)));
              }
            },
          ),
        ),
        Container(
          margin: EdgeInsets.only(right: 16.w(context)),
          width: 36.w(context),
          height: 36.w(context),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(Icons.more_horiz_rounded, size: 18.sp(context)),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = ref.watch(languageProvider);
    final localizationAsync = ref.watch(appLocalizationLoaderProvider);
    final strings = AppStrings(localizationAsync.value ?? {}, currentLang);
    final isArabic = strings.isArabic;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tenant = ref.watch(tenantProvider);
    final fallbackCurrency = tenant.currencySymbol.isNotEmpty
        ? tenant.currencySymbol
        : 'KWD';

    final orderAsync = (widget.orderId != null && widget.orderId!.isNotEmpty)
        ? ref.watch(orderDetailsProvider(widget.orderId!))
        : null;

    final paymentsAsync = (widget.orderId != null && widget.orderId!.isNotEmpty)
        ? ref.watch(orderPaymentsControllerProvider(widget.orderId!))
        : null;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : const Color(0xFFF8F4EE),
      appBar: _appbarWidget(isDark, isArabic, strings, orderAsync),
      body: orderAsync == null
          ? _buildDefaultOrderView(context, strings)
          : orderAsync.when(
              data: (order) {
                if (order == null) {
                  return Center(
                    child: Text(
                      strings.orderNotFound,
                      style: context.textTheme.bodyMedium,
                    ),
                  );
                }

                final paymentData = paymentsAsync?.value;
                final paymentsList = paymentData?.payments ?? [];
                final primaryPayment = paymentsList.isNotEmpty
                    ? paymentsList.first
                    : null;
                final displayCurrency = order.currency.isNotEmpty
                    ? order.currency
                    : fallbackCurrency;

                final isTerminal =
                    primaryPayment != null &&
                    [
                      'PAID',
                      'FAILED',
                      'CANCELLED',
                      'REFUNDED',
                    ].contains(primaryPayment.status);
                final canVerify =
                    !isTerminal &&
                    primaryPayment != null &&
                    primaryPayment.provider == 'MYFATOORAH' &&
                    primaryPayment.providerPaymentId != null &&
                    primaryPayment.providerPaymentId!.isNotEmpty &&
                    [
                      'PENDING',
                      'REQUIRES_ACTION',
                      'UNKNOWN',
                    ].contains(primaryPayment.status);
                final canOpenLink =
                    !isTerminal &&
                    primaryPayment?.status == 'REQUIRES_ACTION' &&
                    primaryPayment?.checkoutUrl != null &&
                    primaryPayment!.checkoutUrl!.isNotEmpty;
                final canInitiate =
                    !isTerminal &&
                    primaryPayment != null &&
                    primaryPayment.provider == 'MYFATOORAH' &&
                    (primaryPayment.initiationState == 'NOT_STARTED' ||
                        primaryPayment.initiationState == 'UNKNOWN' ||
                        primaryPayment.initiationState == 'IN_PROGRESS');
                final isVerifying =
                    primaryPayment != null &&
                    (paymentData?.isVerifying(primaryPayment.id) ?? false);

                final shippingMethod =
                    order.shippingMethodName ?? strings.standardDelivery;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    20.w(context),
                    10.h(context),
                    20.w(context),
                    110.h(context),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Order Status & Timeline Card
                      OrderStatusTimelineCard(
                        order: order,
                        shippingMethod: shippingMethod,
                        strings: strings,
                        isArabic: isArabic,
                        isDark: isDark,
                      ),

                      SizedBox(height: 16.h(context)),

                      // 2. Payment & Delivery Card
                      OrderPaymentDeliveryCard(
                        order: order,
                        primaryPayment: primaryPayment,
                        canInitiate: canInitiate,
                        canOpenLink: canOpenLink,
                        canVerify: canVerify,
                        isVerifying: isVerifying,
                        strings: strings,
                        isDark: isDark,
                      ),

                      SizedBox(height: 20.h(context)),

                      // 3. Items List Card
                      OrderItemsListCard(
                        order: order,
                        displayCurrency: displayCurrency,
                        strings: strings,
                        isDark: isDark,
                      ),

                      SizedBox(height: 20.h(context)),

                      // 4. Price Summary Card
                      OrderPriceSummaryCard(
                        order: order,
                        shippingMethod: shippingMethod,
                        displayCurrency: displayCurrency,
                        strings: strings,
                        isDark: isDark,
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => AppErrorWidget(
                message: strings.failedToLoadOrderDetails,
                onRetry: () =>
                    ref.invalidate(orderDetailsProvider(widget.orderId!)),
              ),
            ),
    );
  }
}
