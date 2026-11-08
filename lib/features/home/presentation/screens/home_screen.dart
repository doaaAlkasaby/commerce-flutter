import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/app_theme.dart';
import 'package:ecommerce/core/widgets/app_scaffold.dart';
import 'package:ecommerce/core/utils/app_update_helper.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/features/home/presentation/providers/home_provider.dart';
import 'package:ecommerce/features/home/presentation/widgets/home_header.dart';
import 'package:ecommerce/features/home/presentation/widgets/home_categories.dart';
import 'package:ecommerce/features/home/presentation/widgets/home_sections.dart';
import 'package:ecommerce/features/home/presentation/widgets/promo_banner.dart';
import 'package:ecommerce/features/auth/presentation/providers/user_provider.dart';

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
            padding: EdgeInsets.symmetric(
              horizontal: 20.w(context),
              vertical: 12.h(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomeHeaderWidget(
                  strings: strings,
                  isDark: isDark,
                  isLoggedIn: isLoggedIn,
                  userName: userName,
                  currentLang: currentLang,
                ),
                SizedBox(height: 14.h(context)),
                HomeCategoriesWidget(homeDataAsync: homeDataAsync),
                SizedBox(height: 10.h(context)),
                homeDataAsync.when(
                  data: (homeResponse) => PromoBanner(
                    banners: homeResponse.data.banners,
                    onShopNow: () {},
                  ),
                  loading: () => SizedBox(
                    height: 160.h(context),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, st) => const SizedBox.shrink(),
                ),
                SizedBox(height: 26.h(context)),
                HomeSectionsWidget(
                  homeDataAsync: homeDataAsync,
                  strings: strings,
                ),
                SizedBox(height: 24.h(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
