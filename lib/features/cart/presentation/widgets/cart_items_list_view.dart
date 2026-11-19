import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/utils/app_error_utils.dart';
import 'package:ecommerce/features/cart/models/cart_model.dart';
import 'package:ecommerce/features/cart/presentation/providers/cart_provider.dart';
import 'cart_item_tile.dart';

class CartItemsListView extends ConsumerWidget {
  final List<CartItemModel> items;
  final String currencyStr;
  final AppStrings strings;
  final bool isDark;
  final Function(String productId) onNavigateToDetails;

  const CartItemsListView({
    super.key,
    required this.items,
    required this.currencyStr,
    required this.strings,
    required this.isDark,
    required this.onNavigateToDetails,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return CartItemTile(
          item: item,
          currencyStr: currencyStr,
          strings: strings,
          isDark: isDark,
          onNavigateToDetails: () =>
              onNavigateToDetails(item.variant.product.id),
          onIncrement: () async {
            try {
              await ref
                  .read(cartProvider.notifier)
                  .updateQuantity(item.variantId, item.quantity + 1);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppErrorUtils.extractErrorMessage(e))),
                );
              }
            }
          },
          onDecrement: () async {
            try {
              if (item.quantity > 1) {
                await ref
                    .read(cartProvider.notifier)
                    .updateQuantity(item.variantId, item.quantity - 1);
              } else {
                await ref
                    .read(cartProvider.notifier)
                    .deleteItem(item.variantId);
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppErrorUtils.extractErrorMessage(e))),
                );
              }
            }
          },
          onDelete: () async {
            try {
              await ref.read(cartProvider.notifier).deleteItem(item.variantId);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(strings.failedToRemoveItem)),
                );
              }
            }
          },
        );
      },
    );
  }
}
