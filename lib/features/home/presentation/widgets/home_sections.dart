import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/widgets/section_header.dart';
import 'package:ecommerce/features/home/models/home_response_model.dart';
import 'package:ecommerce/features/home/presentation/widgets/product_card.dart';

class HomeSectionsWidget extends ConsumerWidget {
  final AsyncValue<HomeResponseModel> homeDataAsync;
  final AppStrings strings;

  const HomeSectionsWidget({
    super.key,
    required this.homeDataAsync,
    required this.strings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return homeDataAsync.when(
      data: (homeResponse) {
        final sectionsList = homeResponse.data.sections;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sectionsList.length,
          itemBuilder: (context, sectionIndex) {
            final section = sectionsList[sectionIndex];
            final productsList = section.products;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: section.title,
                  onSeeAll: () {},
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 230,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: productsList.length,
                    itemBuilder: (context, productIndex) {
                      final ProductModel product = productsList[productIndex];
//'https://placehold.co/800x800'
                      return Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: SizedBox(
                          width: 170,
                          child: ProductCard(
                            product: product,
                            onFavoriteTap: () {},
                            onAddTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${strings.addedToCart}: ${product.name}'),
                                  duration: const Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            );
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, st) => Center(child: Text('Error loading sections: $e')),
    );
  }
}
