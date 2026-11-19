import 'package:flutter/material.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/features/home/models/home_response_model.dart';
import 'package:ecommerce/features/home/presentation/widgets/product_card.dart';

class ProductGrid extends StatelessWidget {
  final ScrollController scrollController;
  final List<ProductModel> products;
  final bool hasMore;
  final bool paginationError;
  final AppStrings strings;
  final VoidCallback onFetchMore;
  final ValueChanged<ProductModel> onAddToCart;

  const ProductGrid({
    super.key,
    required this.scrollController,
    required this.products,
    required this.hasMore,
    required this.paginationError,
    required this.strings,
    required this.onFetchMore,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.all(20.w(context)),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 16.w(context),
        mainAxisSpacing: 16.h(context),
      ),
      itemCount: products.length + (hasMore || paginationError ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == products.length) {
          if (paginationError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(8.w(context)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      strings.failedToLoadMore,
                      style: context.textTheme.redTitleSmall,
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: AppColors.primary),
                      onPressed: onFetchMore,
                    ),
                  ],
                ),
              ),
            );
          }
          return hasMore
              ? Padding(
                  padding: EdgeInsets.all(16.w(context)),
                  child: const Center(child: CircularProgressIndicator()),
                )
              : const SizedBox.shrink();
        }
        final product = products[index];
        return ProductCard(
          product: product,
          onFavoriteTap: () {},
          onAddTap: () => onAddToCart(product),
        );
      },
    );
  }
}
