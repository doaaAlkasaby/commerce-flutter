import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import '../providers/orders_provider.dart';

class OrderFilterChips extends ConsumerWidget {
  final AsyncValue<PaginatedOrdersState> ordersAsync;
  final String selectedFilter;
  final AppStrings strings;
  final bool isDark;

  const OrderFilterChips({
    super.key,
    required this.ordersAsync,
    required this.selectedFilter,
    required this.strings,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ordersAsync.when(
      data: (paginated) {
        final allCount = paginated.items.length;
        final pendingCount = paginated.items
            .where((o) => o.status.toUpperCase() == 'PENDING')
            .length;
        final confirmedCount = paginated.items
            .where((o) => o.status.toUpperCase() == 'CONFIRMED')
            .length;
        final procCount = paginated.items
            .where((o) => o.status.toUpperCase() == 'PROCESSING')
            .length;
        final shipCount = paginated.items
            .where((o) => o.status.toUpperCase() == 'SHIPPED')
            .length;
        final delivCount = paginated.items
            .where(
              (o) =>
                  ['DELIVERED', 'COMPLETED'].contains(o.status.toUpperCase()),
            )
            .length;
        final cancelCount = paginated.items
            .where((o) => o.status.toUpperCase() == 'CANCELLED')
            .length;

        final filterChips = [
          {'id': 'All', 'label': strings.allFilter, 'count': allCount},
          {
            'id': 'PENDING',
            'label': strings.pendingStatus,
            'count': pendingCount,
          },
          {
            'id': 'CONFIRMED',
            'label': strings.confirmedStatus,
            'count': confirmedCount,
          },
          {
            'id': 'PROCESSING',
            'label': strings.processingStatus,
            'count': procCount,
          },
          {'id': 'SHIPPED', 'label': strings.shippedStatus, 'count': shipCount},
          {
            'id': 'DELIVERED',
            'label': strings.deliveredStatus,
            'count': delivCount,
          },
          {
            'id': 'CANCELLED',
            'label': strings.cancelledStatus,
            'count': cancelCount,
          },
        ];

        return SizedBox(
          height: 34.h(context),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 20.w(context)),
            itemCount: filterChips.length,
            itemBuilder: (context, index) {
              final item = filterChips[index];
              final id = item['id'] as String;
              final label = item['label'] as String;
              final count = item['count'] as int;
              final isSelected = selectedFilter == id;

              return GestureDetector(
                onTap: () {
                  ref.read(orderFilterProvider.notifier).setFilter(id);
                },
                child: Container(
                  margin: EdgeInsets.only(right: 8.w(context)),
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w(context),
                    vertical: 3.h(context),
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.darkSurface : Colors.white),
                    borderRadius: BorderRadius.circular(22.w(context)),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        label,
                        style: isSelected
                            ? context.textTheme.whiteLabelSmall
                            : context.textTheme.bodySmall,
                      ),
                      SizedBox(width: 6.w(context)),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w(context),
                          vertical: 2.h(context),
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.25)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10.w(context)),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 10.sp(context),
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
