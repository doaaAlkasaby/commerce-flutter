import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/features/home/models/home_response_model.dart';
import 'package:ecommerce/features/home/presentation/widgets/category_item.dart';

class HomeCategoriesWidget extends ConsumerWidget {
  final AsyncValue<HomeResponseModel> homeDataAsync;

  const HomeCategoriesWidget({super.key, required this.homeDataAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 96,
      child: homeDataAsync.when(
        data: (homeResponse) {
          final categoriesList = homeResponse.data.categories;
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: categoriesList.length,
            itemBuilder: (context, index) {
              final CategoryModel category = categoriesList[index];
              return CategoryItem(category: category, onTap: () {});
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
