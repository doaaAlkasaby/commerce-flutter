import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/widgets/app_button.dart';
import '../providers/orders_provider.dart';
import 'order_details_screen.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(myOrdersProvider);
    final selectedFilter = ref.watch(orderFilterProvider);
    final localizationAsync = ref.watch(appLocalizationLoaderProvider);
    final currentLang = ref.watch(languageProvider);
    final strings = AppStrings(localizationAsync.value ?? {}, currentLang);
    final isArabic = currentLang == AppLanguage.ar;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filters = ['All', 'Processing', 'Shipped', 'Delivered'];

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                20.w(context),
                16.h(context),
                20.w(context),
                12.h(context),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isArabic ? 'طلباتي' : 'My orders',
                    style: context.textTheme.displayMedium?.copyWith(
                      fontSize: 26.sp(context),
                    ),
                  ),
                  Container(
                    width: 40.w(context),
                    height: 40.w(context),
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
                    child: Icon(
                      Icons.search,
                      size: 20.sp(context),
                      color: AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 50.h(context),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w(context)),
                itemCount: filters.length,
                itemBuilder: (context, index) {
                  final filter = filters[index];
                  final isSelected = selectedFilter == filter;
                  return GestureDetector(
                    onTap: () {
                      ref.read(orderFilterProvider.notifier).setFilter(filter);
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: 10.w(context)),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w(context),
                        vertical: 10.h(context),
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? AppColors.darkSurface : Colors.white),
                        borderRadius: BorderRadius.circular(24.w(context)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: Offset(0, 2.h(context)),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        filter,
                        style: context.textTheme.boldTitleSmall?.copyWith(
                          fontSize: 13.sp(context),
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 10.h(context)),
            Expanded(
              child: ordersAsync.when(
                data: (orders) {
                  final filteredOrders = orders.where((o) {
                    if (selectedFilter == 'All') {
                      return true;
                    }
                    if (selectedFilter == 'Delivered') {
                      return o.status == 'DELIVERED';
                    }
                    if (selectedFilter == 'Processing') {
                      return o.status == 'IN_TRANSIT' || o.status == 'PROCESSING';
                    }
                    if (selectedFilter == 'Shipped') {
                      return o.status == 'SHIPPED';
                    }
                    return true;
                  }).toList();

                  if (filteredOrders.isEmpty) {
                    return Center(
                      child: Text(
                        strings.noProductsFound,
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontSize: 14.sp(context),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w(context),
                      vertical: 10.h(context),
                    ),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      Color badgeColor = AppColors.mintTeal;
                      if (order.status == 'DELIVERED') {
                        badgeColor = Colors.green;
                      }
                      if (order.status == 'CANCELLED') {
                        badgeColor = Colors.grey;
                      }

                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const OrderDetailsScreen(),
                            ),
                          );
                        },
                        child: Container(
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
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    order.orderNumber,
                                    style: context.textTheme.boldTitleMedium
                                        ?.copyWith(
                                          fontSize: 16.sp(context),
                                          color: isDark
                                              ? AppColors.darkTextPrimary
                                              : AppColors.lightTextPrimary,
                                        ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w(context),
                                      vertical: 4.h(context),
                                    ),
                                    decoration: BoxDecoration(
                                      color: badgeColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(
                                        10.w(context),
                                      ),
                                    ),
                                    child: Text(
                                      order.status.replaceAll('_', ' '),
                                      style: context.textTheme.labelSmall
                                          ?.copyWith(
                                            fontSize: 10.sp(context),
                                            color: badgeColor,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4.h(context)),
                              Text(
                                order.placedDate,
                                style: context.textTheme.bodySmall?.copyWith(
                                  fontSize: 12.sp(context),
                                ),
                              ),
                              SizedBox(height: 14.h(context)),
                              Row(
                                children: [
                                  ...order.items
                                      .take(3)
                                      .map(
                                        (item) => Padding(
                                          padding: EdgeInsets.only(
                                            right: 8.w(context),
                                          ),
                                          child: Container(
                                            width: 48.w(context),
                                            height: 48.h(context),
                                            decoration: BoxDecoration(
                                              color: AppColors.lightCategoryBg,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    12.w(context),
                                                  ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    12.w(context),
                                                  ),
                                              child: CachedNetworkImage(
                                                imageUrl: item.imageUrl,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  if (order.items.length > 3)
                                    Container(
                                      width: 48.w(context),
                                      height: 48.h(context),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(
                                          12.w(context),
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '+${order.items.length - 3}',
                                        style: context.textTheme.boldTitleSmall
                                            ?.copyWith(
                                              fontSize: 13.sp(context),
                                              color:
                                                  AppColors.lightTextSecondary,
                                            ),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 16.h(context)),
                              const Divider(height: 1),
                              SizedBox(height: 12.h(context)),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        strings.total,
                                        style: context.textTheme.labelLarge
                                            ?.copyWith(
                                              fontSize: 10.sp(context),
                                              color:
                                                  AppColors.lightTextSecondary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      SizedBox(height: 2.h(context)),
                                      Text(
                                        '\$${order.totalAmount.toStringAsFixed(2)}',
                                        style: context.textTheme.boldTitleMedium
                                            ?.copyWith(
                                              fontSize: 16.sp(context),
                                              color: isDark
                                                  ? AppColors.darkTextPrimary
                                                  : AppColors.lightTextPrimary,
                                            ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: 38.h(context),
                                    child: AppButton(
                                      text: order.status == 'IN_TRANSIT'
                                          ? 'Track order'
                                          : (order.status == 'CANCELLED'
                                                ? 'View refund'
                                                : 'Buy again'),
                                      onPressed: () {},
                                      type: AppButtonType.outlined,
                                      height: 38.h(context),
                                      width: 130.w(context),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
