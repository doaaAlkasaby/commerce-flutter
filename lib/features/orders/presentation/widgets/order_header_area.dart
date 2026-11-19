import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import '../providers/orders_provider.dart';

class OrderHeaderArea extends ConsumerWidget {
  final AsyncValue<PaginatedOrdersState> ordersAsync;
  final AppStrings strings;

  const OrderHeaderArea({
    super.key,
    required this.ordersAsync,
    required this.strings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        12.w(context),
        16.h(context),
        12.w(context),
        12.h(context),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(strings.myOrders, style: context.textTheme.displayLarge),
              SizedBox(height: 2.h(context)),
              ordersAsync.when(
                data: (paginated) {
                  final inTransit = paginated.items
                      .where(
                        (o) => [
                          'PENDING',
                          'CONFIRMED',
                          'PROCESSING',
                          'SHIPPED',
                        ].contains(o.status.toUpperCase()),
                      )
                      .length;
                  return Text(
                    strings
                        .get('orders_summary')
                        .replaceAll(
                          '{ordersCount}',
                          '${paginated.items.length}',
                        )
                        .replaceAll('{inTransit}', '$inTransit'),
                    style: context.textTheme.bodySmall,
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
