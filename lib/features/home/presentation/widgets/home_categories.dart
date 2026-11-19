import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/features/home/models/home_response_model.dart';
import 'package:ecommerce/features/home/presentation/widgets/category_item.dart';

import '../../../categories/models/category_detail_model.dart';
import '../../../categories/presentation/screens/category_children_screen.dart';
import '../../../product/presentation/screens/product_list_screen.dart';

class HomeCategoriesWidget extends ConsumerWidget {
  final AsyncValue<HomeResponseModel> homeDataAsync;

  const HomeCategoriesWidget({super.key, required this.homeDataAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 70.h(context),
      child: homeDataAsync.when(
        data: (homeResponse) {
          final categoriesList = homeResponse.data.categories;
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: categoriesList.length,
            itemBuilder: (context, index) {
              final MainCategoryModel category = categoriesList[index];
              return CategoryItemWidget(
                category: category,
                onTap: () {
                  if (category.hasChildren) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            CategoryChildrenScreen(category: category),
                      ),
                    );
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProductListScreen(
                          title: category.name,
                          endpoint: '/products?categoryId=${category.id}',
                        ),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
