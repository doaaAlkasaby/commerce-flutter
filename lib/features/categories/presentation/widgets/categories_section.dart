import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/widgets/app_image_container.dart';
import 'package:ecommerce/features/product/presentation/screens/product_list_screen.dart';
import '../screens/category_children_screen.dart';
import '../../models/category_detail_model.dart';

class CategoriesSection extends ConsumerWidget {
  final AsyncValue<List<MainCategoryModel>> categoriesAsync;
  final AppStrings strings;

  const CategoriesSection({
    super.key,
    required this.categoriesAsync,
    required this.strings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return categoriesAsync.when(
      data: (categories) => SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: 20.w(context)),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final category = categories[index];
              return GestureDetector(
                onTap: () {
                  if (category.hasChildren) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CategoryChildrenScreen(category: category),
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
                child: Container(
                  padding: EdgeInsets.all(16.w(context)),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardBg : Colors.white,
                    borderRadius: BorderRadius.circular(28.w(context)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppImageContainer(
                        width: 88.w(context),
                        height: 88.h(context),
                        borderRadius: BorderRadius.circular(32),
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: category.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (context, url, error) => const Icon(Icons.category_outlined, size: 36, color: AppColors.primary),
                          ),
                        ),
                      ),
                      SizedBox(height: 14.h(context)),
                      Text(
                        category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontSize: 16.sp(context),
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              );
            },
            childCount: categories.length,
          ),
        ),
      ),
      loading: () => SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(40.w(context)),
            child: const CircularProgressIndicator(),
          ),
        ),
      ),
      error: (e, st) => SliverToBoxAdapter(
        child: Center(child: Text('Error: $e')),
      ),
    );
  }
}
