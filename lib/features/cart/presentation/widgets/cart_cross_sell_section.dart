import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/features/home/models/home_response_model.dart';
import 'package:ecommerce/features/orders/models/order_model.dart';

class CartCrossSellSection extends StatelessWidget {
  final AsyncValue<HomeResponseModel> homeDataAsync;
  final String currencyStr;
  final AppStrings strings;
  final Function(String productId) onNavigateToDetails;

  const CartCrossSellSection({
    super.key,
    required this.homeDataAsync,
    required this.currencyStr,
    required this.strings,
    required this.onNavigateToDetails,
  });

  @override
  Widget build(BuildContext context) {
    return homeDataAsync.when(
      data: (homeData) {
        final crossSellProducts = homeData.data.sections
            .expand((s) => s.products)
            .take(5)
            .toList();

        if (crossSellProducts.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  strings.youMayAlsoLike,
                  style: context.textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    strings.seeAll,
                    style: context.textTheme.primaryTitleSmall,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h(context)),
            SizedBox(
              height: 160.h(context),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: crossSellProducts.length,
                itemBuilder: (context, index) {
                  final p = crossSellProducts[index];
                  return GestureDetector(
                    onTap: () => onNavigateToDetails(p.id),
                    child: Container(
                      width: 110.w(context),
                      margin: EdgeInsets.only(right: 12.w(context)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 110.w(context),
                            height: 100.h(context),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBF7F2),
                              borderRadius: BorderRadius.circular(
                                16.w(context),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                16.w(context),
                              ),
                              child: CachedNetworkImage(
                                imageUrl: p.image,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.shopping_bag_outlined),
                              ),
                            ),
                          ),
                          SizedBox(height: 6.h(context)),
                          Text(
                            p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.titleSmall,
                          ),
                          Text(
                            formatOrderMoney(
                              '${p.priceInfo.finalPrice}',
                              currencyStr,
                              strings.isArabic,
                            ),
                            style: context.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16.h(context)),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
