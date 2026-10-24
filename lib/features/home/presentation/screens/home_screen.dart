import 'dart:developer';

import 'package:ecommerce/core/constants/app_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/app_theme.dart';
import 'package:ecommerce/core/widgets/app_scaffold.dart';
import 'package:ecommerce/core/widgets/section_header.dart';
import 'package:ecommerce/core/utils/app_update_helper.dart';
import 'package:ecommerce/features/home/presentation/providers/home_provider.dart';
import 'package:ecommerce/features/home/models/home_response_model.dart';
import 'package:ecommerce/features/home/presentation/widgets/category_item.dart';
import 'package:ecommerce/features/home/presentation/widgets/product_card.dart';
import 'package:ecommerce/features/home/presentation/widgets/promo_banner.dart';
import 'package:ecommerce/features/auth/presentation/providers/user_provider.dart';
import 'package:ecommerce/features/search/presentation/screens/search_filter_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.invalidate(currentUserProvider);
      await AppUpdateHelper.checkAndShowUpdateDialog(context, ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    final homeDataAsync = ref.watch(homeDataProvider);
    final localizationAsync = ref.watch(appLocalizationLoaderProvider);
    final currentLang = ref.watch(languageProvider);
    final themeMode = ref.watch(themeProvider);
    final userAsync = ref.watch(currentUserProvider);

    final strings = AppStrings(localizationAsync.value ?? {}, currentLang);
    final isDark = themeMode == ThemeMode.dark;
    final isLoggedIn = userAsync.value != null;
    final userName = isLoggedIn
        ? (userAsync.value?.firstName ?? 'User')
        : 'Guest';

    return AppScaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(homeDataProvider);
            ref.invalidate(currentUserProvider);
            await ref.read(homeDataProvider.future);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(
                  context,
                  strings,
                  isDark,
                  isLoggedIn,
                  userName,
                  currentLang,
                ),

                const SizedBox(height: 14),
                SizedBox(
                  height: 96,
                  child: homeDataAsync.when(
                    data: (homeResponse) {
                      final List<CategoryModel> categoriesList =
                          homeResponse.data.categories;
                      return Column(
                        children: [
                          const SizedBox(height: 26),
                          SectionHeader(
                            title: strings.categories,
                            onSeeAll: () {},
                          ),

                          ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: categoriesList.length,
                            itemBuilder: (context, index) {
                              final CategoryModel category =
                                  categoriesList[index];
                              return CategoryItem(
                                category: category,
                                onTap: () {},
                              );
                            },
                          ),
                        ],
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, st) {
                      log("Error: $e");
                      return Center(child: Text('Error: Unable to load data'));
                    },
                  ),
                ),
                const SizedBox(height: 10),
                homeDataAsync.when(
                  data: (homeResponse) => PromoBanner(
                    banners: homeResponse.data.banners,
                    onShopNow: () {},
                  ),
                  loading: () => const SizedBox(
                    height: 160,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, st) {
                    log("Error: $e");
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 26),
                // Loop on sectionsList displaying section header and horizontal list view of products
                homeDataAsync.when(
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
                                  final ProductModel product =
                                      productsList[productIndex];
                                  //'https://placehold.co/800x800'
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 16),
                                    child: SizedBox(
                                      width: 170,
                                      child: ProductCard(
                                        product: product,
                                        onFavoriteTap: () {},
                                        onAddTap: () {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '${strings.addedToCart}: ${product.name}',
                                              ),
                                              duration: const Duration(
                                                seconds: 1,
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
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
                  error: (e, st) {
                    log("Error: $e");
                    return Center(child: Text('Error: Unable to load data'));
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppStrings strings,
    bool isDark,
    bool isLoggedIn,
    String userName,
    AppLanguage currentLang,
  ) {
    final isArabic = currentLang == AppLanguage.ar;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isLoggedIn
                  ? strings.goodMorning
                  : (isArabic ? 'مرحباً بك في المتجر' : 'Welcome to Store'),
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isLoggedIn
                  ? 'Hi, $userName!'
                  : (isArabic
                  ? 'أهلاً بك، زائرنا الكريم'
                  : 'Hello, Guest!'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  Icons.search,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  size: 20,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SearchFilterScreen(),
                    ),
                  );
                },
                padding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(width: 10),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                      size: 20,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('You have 5 unread notifications'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    padding: EdgeInsets.zero,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.badgeRed,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: const Text(
                      '5',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Image.asset(
              AppAssets.logo,
              width: 60,
              height: 60,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ],
    );
  }
}
