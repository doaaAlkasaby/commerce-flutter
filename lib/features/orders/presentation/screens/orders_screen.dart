import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/config/tenant_config.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/constants/app_assets.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/widgets/app_empty_widget.dart';
import 'package:ecommerce/core/widgets/app_error_widget.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/features/orders/models/order_model.dart';
import 'package:ecommerce/features/special_orders/presentation/widgets/special_orders_banner.dart';
import '../../../main_shell_screen.dart';
import '../providers/orders_provider.dart';
import '../widgets/order_card_tile.dart';
import '../widgets/order_filter_chips.dart';
import '../widgets/order_header_area.dart';
import '../widgets/order_section_header.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String _sortOrder = 'NEWEST';

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(myOrdersControllerProvider);
    final selectedFilter = ref.watch(orderFilterProvider);
    final localizationAsync = ref.watch(appLocalizationLoaderProvider);
    final currentLang = ref.watch(languageProvider);
    final strings = AppStrings(localizationAsync.value ?? {}, currentLang);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tenant = ref.watch(tenantProvider);
    final fallbackCurrency = tenant.currencySymbol.isNotEmpty
        ? tenant.currencySymbol
        : 'KWD';

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Area
            OrderHeaderArea(ordersAsync: ordersAsync, strings: strings),

            // 2. Filter Chips Bar
            OrderFilterChips(
              ordersAsync: ordersAsync,
              selectedFilter: selectedFilter,
              strings: strings,
              isDark: isDark,
            ),

            SizedBox(height: 12.h(context)),

            // Special Orders Banner
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w(context)),
              child: const SpecialOrdersBanner(
                bannerContext: SpecialOrdersBannerContext.orders,
              ),
            ),

            SizedBox(height: 12.h(context)),

            // 3. Section Header & Sort Bar
            OrderSectionHeader(
              sortOrder: _sortOrder,
              strings: strings,
              onSortChanged: (newSort) => setState(() => _sortOrder = newSort),
            ),

            SizedBox(height: 8.h(context)),

            // 4. Orders List
            Expanded(
              child: ordersAsync.when(
                data: (paginated) {
                  var orders = List<OrderModel>.from(paginated.items);

                  if (_sortOrder == 'OLDEST') {
                    orders.sort((a, b) => a.createdAt.compareTo(b.createdAt));
                  } else {
                    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  }

                  if (orders.isEmpty) {
                    return AppEmptyWidget(
                      title: strings.noOrdersFound,
                      svgAsset: AppAssets.orderSVG,
                      actionText: strings.shopNow,
                      onActionPressed: () {
                        ref.read(navigationIndexProvider.notifier).setIndex(0);
                      },
                    );
                  }

                  return NotificationListener<ScrollNotification>(
                    onNotification: (scrollInfo) {
                      if (scrollInfo.metrics.pixels >=
                          scrollInfo.metrics.maxScrollExtent - 200) {
                        ref
                            .read(myOrdersControllerProvider.notifier)
                            .loadNextPage();
                      }
                      return false;
                    },
                    child: RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async {
                        ref.read(myOrdersControllerProvider.notifier).refresh();
                      },
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w(context),
                          vertical: 10.h(context),
                        ),
                        itemCount:
                            orders.length +
                            (paginated.isLoadingMore ||
                                    paginated.loadMoreError != null
                                ? 1
                                : 0),
                        itemBuilder: (context, index) {
                          if (index == orders.length) {
                            if (paginated.loadMoreError != null) {
                              return Padding(
                                padding: EdgeInsets.all(16.w(context)),
                                child: Column(
                                  children: [
                                    Text(
                                      strings.failedToLoadMoreOrders,
                                      style: context.textTheme.redTitleSmall,
                                    ),
                                    SizedBox(height: 8.h(context)),
                                    ElevatedButton(
                                      onPressed: () {
                                        ref
                                            .read(
                                              myOrdersControllerProvider
                                                  .notifier,
                                            )
                                            .loadNextPage();
                                      },
                                      child: Text(strings.retry),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return Padding(
                              padding: EdgeInsets.all(16.w(context)),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final order = orders[index];
                          return OrderCardTile(
                            order: order,
                            fallbackCurrency: fallbackCurrency,
                            strings: strings,
                            isDark: isDark,
                          );
                        },
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => AppErrorWidget(
                  message: strings.failedToLoadOrders,
                  onRetry: () =>
                      ref.read(myOrdersControllerProvider.notifier).refresh(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
