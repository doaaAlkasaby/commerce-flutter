import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/features/home/presentation/widgets/product_card.dart';
import 'package:ecommerce/features/search/presentation/providers/search_provider.dart';

class SearchProductGrid extends ConsumerWidget {
  final ScrollController scrollController;
  final PaginatedProductsState paginatedState;
  final AppStrings strings;

  const SearchProductGrid({
    super.key,
    required this.scrollController,
    required this.paginatedState,
    required this.strings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = paginatedState.items;

    return CustomScrollView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.all(20.w(context)),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
              childAspectRatio: 0.68,
              crossAxisSpacing: 16.w(context),
              mainAxisSpacing: 16.h(context),
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final product = products[index];
              return ProductCard(
                product: product,
                onFavoriteTap: () {},
                onAddTap: () {},
              );
            }, childCount: products.length),
          ),
        ),
        if (paginatedState.isLoadingMore)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h(context)),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
        if (paginatedState.loadMoreError != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h(context)),
              child: Column(
                children: [
                  Text(
                    strings.failedToLoadMoreProducts,
                    style: context.textTheme.redTitleSmall,
                  ),
                  SizedBox(height: 8.h(context)),
                  ElevatedButton(
                    onPressed: () {
                      ref
                          .read(searchControllerProvider.notifier)
                          .loadNextPage();
                    },
                    child: Text(strings.retry),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
