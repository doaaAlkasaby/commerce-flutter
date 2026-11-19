import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/features/product/presentation/screens/product_list_screen.dart';
import '../providers/categories_provider.dart';
import '../../models/category_detail_model.dart';

class CategoryChildrenScreen extends ConsumerStatefulWidget {
  final MainCategoryModel category;

  const CategoryChildrenScreen({super.key, required this.category});

  @override
  ConsumerState<CategoryChildrenScreen> createState() =>
      _CategoryChildrenScreenState();
}

class _CategoryChildrenScreenState
    extends ConsumerState<CategoryChildrenScreen> {
  late Future<List<MainCategoryModel>> _childrenFuture;

  @override
  void initState() {
    super.initState();
    final repo = ref.read(categoriesRepositoryProvider);
    _childrenFuture = repo.getCategoryChildren(widget.category.id);
  }

  @override
  Widget build(BuildContext context) {
    final localizationAsync = ref.watch(appLocalizationLoaderProvider);
    final currentLang = ref.watch(languageProvider);
    final strings = AppStrings(localizationAsync.value ?? {}, currentLang);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        elevation: 0,
        leading: Padding(
          padding: EdgeInsets.all(8.w(context)),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: Offset(0, 2.h(context)),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                size: 16.sp(context),
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: Text(widget.category.name, style: context.textTheme.titleLarge),
      ),
      body: FutureBuilder<List<MainCategoryModel>>(
        future: _childrenFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final subCategories = snapshot.data ?? [];

          if (subCategories.isEmpty) {
            return Center(
              child: Text(
                strings.noProductsFound,
                style: context.textTheme.bodyMedium,
              ),
            );
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.all(20.w(context)),
            itemCount: subCategories.length,
            itemBuilder: (context, index) {
              final sub = subCategories[index];
              return GestureDetector(
                onTap: () {
                  if (sub.hasChildren) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CategoryChildrenScreen(category: sub),
                      ),
                    );
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProductListScreen(
                          title: sub.name,
                          endpoint: '/products?categoryId=${sub.id}',
                        ),
                      ),
                    );
                  }
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24.w(context)),
                  child: Container(
                    margin: EdgeInsets.only(bottom: 16.h(context)),
                    height: 90.h(context),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardBg : Colors.white,
                      borderRadius: BorderRadius.circular(20.w(context)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: Offset(0, 4.h(context)),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20.w(context)),
                          child: SizedBox(
                            width: 90.w(context),
                            height: 90.h(context),
                            child: CachedNetworkImage(
                              imageUrl: sub.imageUrl,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.category_outlined),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(16.w(context)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  sub.name,
                                  style: context.textTheme.titleMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w(context),
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios,
                            size: 16.sp(context),
                            color: AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
