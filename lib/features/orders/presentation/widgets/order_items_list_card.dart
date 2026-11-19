import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/app_error_utils.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/widgets/app_price_text.dart';
import 'package:ecommerce/features/orders/models/order_model.dart';
import 'package:ecommerce/features/product/data/product_repository.dart';
import 'package:ecommerce/features/product/presentation/screens/product_details_screen.dart';

class OrderItemsListCard extends ConsumerWidget {
  final OrderModel order;
  final String displayCurrency;
  final AppStrings strings;
  final bool isDark;

  const OrderItemsListCard({
    super.key,
    required this.order,
    required this.displayCurrency,
    required this.strings,
    required this.isDark,
  });

  Widget _buildOrderItem(
    BuildContext context,
    WidgetRef ref, {
    required AppStrings strings,
    required String imageUrl,
    required String name,
    required String variantAttr,
    required String price,
    required bool isLast,
    required bool isDark,
    required int quantity,
    required String productId,
  }) {
    return InkWell(
      onTap: () async {
        try {
          final repo = ProductRepository(ref.read(dioClientProvider));
          final fullProduct = await repo.getProductDetails(productId);
          if (context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProductDetailsScreen(product: fullProduct),
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppErrorUtils.extractErrorMessage(e))),
            );
          }
        }
      },
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(14.w(context)),
            child: Row(
              children: [
                Container(
                  width: 56.w(context),
                  height: 56.h(context),
                  decoration: BoxDecoration(
                    color: AppColors.lightCategoryBg,
                    borderRadius: BorderRadius.circular(12.w(context)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.w(context)),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                ),
                SizedBox(width: 12.w(context)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.titleSmall,
                      ),
                      SizedBox(height: 4.h(context)),
                      if (variantAttr.isNotEmpty)
                        Text(
                          variantAttr,
                          style: context.textTheme.grayBodySmall,
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            strings
                                .get('qty_label')
                                .replaceAll('{quantity}', '$quantity'),
                            style: context.textTheme.grayBodySmall,
                          ),
                          AppPriceTextRow(price: price, currency: ''),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!isLast)
            Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${strings.items} (${order.items.length})',
              style: context.textTheme.titleLarge,
            ),
            Text(
              strings
                  .get('in_product')
                  .replaceAll(
                    '{amount}',
                    formatOrderMoney(
                      order.subtotal,
                      displayCurrency,
                      strings.isArabic,
                    ),
                  ),
              style: context.textTheme.bodySmall,
            ),
          ],
        ),
        SizedBox(height: 10.h(context)),
        Container(
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
            children: List.generate(order.items.length, (index) {
              final item = order.items[index];
              return _buildOrderItem(
                context,
                ref,
                strings: strings,
                imageUrl: item.imageUrl,
                name: item.name,
                variantAttr: item.variantAttributesSummary,
                quantity: item.quantity,
                price: formatOrderMoney(
                  item.totalPrice,
                  displayCurrency,
                  strings.isArabic,
                ),
                isLast: index == order.items.length - 1,
                isDark: isDark,
                productId: item.productId,
              );
            }),
          ),
        ),
      ],
    );
  }
}
