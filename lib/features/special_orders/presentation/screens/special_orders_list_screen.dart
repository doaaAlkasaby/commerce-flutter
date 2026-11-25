import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/widgets/app_empty_widget.dart';
import 'package:ecommerce/core/widgets/app_error_widget.dart';
import 'package:ecommerce/core/widgets/app_price_text.dart';
import 'package:ecommerce/core/widgets/app_scaffold.dart';
import 'package:ecommerce/core/widgets/app_unauth_widget.dart';
import 'package:ecommerce/features/storefront/presentation/providers/storefront_provider.dart';
import '../providers/special_orders_availability_provider.dart';
import '../providers/special_orders_provider.dart';
import 'confirmed_special_order_detail_screen.dart';
import 'special_order_request_detail_screen.dart';

class SpecialOrdersListScreen extends ConsumerStatefulWidget {
  const SpecialOrdersListScreen({super.key});

  @override
  ConsumerState<SpecialOrdersListScreen> createState() =>
      _SpecialOrdersListScreenState();
}

class _SpecialOrdersListScreenState
    extends ConsumerState<SpecialOrdersListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'NEW':
        return Colors.blue;
      case 'UNDER_REVIEW':
        return Colors.orange;
      case 'QUOTED':
        return Colors.purple;
      case 'ACCEPTED':
      case 'CONFIRMED':
      case 'COMPLETED':
        return Colors.green;
      case 'REJECTED':
      case 'CANCELLED':
        return AppColors.badgeRed;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = ref.watch(authTokenProvider);
    final isLoggedIn = token != null && token.isNotEmpty;

    final storefrontAsync = ref.watch(storefrontProvider);
    final storefront = storefrontAsync.value;
    final isSubmissionEnabled = ref.watch(specialOrdersAvailabilityProvider);

    final localizationAsync = ref.watch(appLocalizationLoaderProvider);
    final currentLang = ref.watch(languageProvider);
    final strings = AppStrings(localizationAsync.value ?? {}, currentLang);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canPop = Navigator.of(context).canPop();

    final instructions = currentLang == AppLanguage.ar
        ? storefront?.specialOrders.instructionsAr
        : storefront?.specialOrders.instructionsEn;

    if (!isLoggedIn) {
      return AppScaffold(
        appBar: canPop
            ? AppBar(
                title: Text(strings.mySpecialOrders),
                backgroundColor: Colors.transparent,
                elevation: 0,
              )
            : null,
        body: SafeArea(
          child: AppUnauthWidget(
            screenTitle: strings.mySpecialOrders,
            description: strings.loginRequiredDesc,
          ),
        ),
      );
    }

    return AppScaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Area
            Padding(
              padding: EdgeInsets.fromLTRB(
                16.w(context),
                12.h(context),
                16.w(context),
                8.h(context),
              ),
              child: Row(
                children: [
                  if (canPop) ...[
                    const BackButton(),
                    SizedBox(width: 4.w(context)),
                  ],
                  Expanded(
                    child: Text(
                      strings.mySpecialOrders,
                      style: context.textTheme.displayLarge,
                    ),
                  ),
                ],
              ),
            ),

            // Storefront submission status or instructions banner
            if (!isSubmissionEnabled)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w(context),
                  vertical: 4.h(context),
                ),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w(context),
                    vertical: 8.h(context),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.w(context)),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18.sp(context),
                        color: Colors.orange.shade800,
                      ),
                      SizedBox(width: 8.w(context)),
                      Expanded(
                        child: Text(
                          strings.submissionsDisabledNotice,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (instructions != null && instructions.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w(context),
                  vertical: 4.h(context),
                ),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w(context),
                    vertical: 8.h(context),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12.w(context)),
                  ),
                  child: Text(
                    instructions,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

            SizedBox(height: 8.h(context)),

            // Segmented Tab Bar (Requests / Confirmed Orders)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w(context)),
              child: Container(
                height: 44.h(context),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(22.w(context)),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(22.w(context)),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  labelStyle: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  tabs: [
                    Tab(text: strings.requestsTab),
                    Tab(text: strings.confirmedOrdersTab),
                  ],
                ),
              ),
            ),

            SizedBox(height: 12.h(context)),

            // Tab Views Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Requests List
                  _RequestsListView(
                    strings: strings,
                    isDark: isDark,
                    getStatusColor: _getStatusColor,
                  ),

                  // Tab 2: Confirmed Orders List
                  _ConfirmedOrdersListView(
                    strings: strings,
                    isDark: isDark,
                    getStatusColor: _getStatusColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestsListView extends ConsumerWidget {
  final AppStrings strings;
  final bool isDark;
  final Color Function(String status) getStatusColor;

  const _RequestsListView({
    required this.strings,
    required this.isDark,
    required this.getStatusColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(mySpecialOrdersRequestsControllerProvider);

    return requestsAsync.when(
      data: (paginated) {
        final items = paginated.items;
        if (items.isEmpty) {
          return AppEmptyWidget(
            title: strings.noSpecialOrderRequests,
            icon: Icons.assignment_outlined,
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.read(mySpecialOrdersRequestsControllerProvider.notifier).refresh();
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 16.w(context),
              vertical: 4.h(context),
            ),
            itemCount: items.length + (paginated.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == items.length) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final item = items[index];
              final statusColor = getStatusColor(item.status);

              return Card(
                margin: EdgeInsets.only(bottom: 10.h(context)),
                elevation: 0,
                color: isDark ? AppColors.darkCardBg : AppColors.cardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.w(context)),
                  side: BorderSide(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14.w(context),
                    vertical: 8.h(context),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${strings.requestNumber.replaceAll('{number}', '')} ${item.requestNumber}',
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w(context),
                          vertical: 2.h(context),
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.w(context)),
                        ),
                        child: Text(
                          item.status,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: EdgeInsets.only(top: 6.h(context)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.items.isNotEmpty)
                          Text(
                            item.items.map((i) => i.name).join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.bodySmall,
                          ),
                        SizedBox(height: 4.h(context)),
                        Text(
                          item.createdAt,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                            fontSize: 10.sp(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SpecialOrderRequestDetailScreen(
                          requestId: item.id,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => AppErrorWidget(
        message: strings.failedToLoadSpecialOrders,
        onRetry: () =>
            ref.read(mySpecialOrdersRequestsControllerProvider.notifier).refresh(),
      ),
    );
  }
}

class _ConfirmedOrdersListView extends ConsumerWidget {
  final AppStrings strings;
  final bool isDark;
  final Color Function(String status) getStatusColor;

  const _ConfirmedOrdersListView({
    required this.strings,
    required this.isDark,
    required this.getStatusColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final confirmedAsync = ref.watch(myConfirmedSpecialOrdersControllerProvider);

    return confirmedAsync.when(
      data: (paginated) {
        final items = paginated.items;
        if (items.isEmpty) {
          return AppEmptyWidget(
            title: strings.noConfirmedSpecialOrders,
            icon: Icons.shopping_bag_outlined,
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref
                .read(myConfirmedSpecialOrdersControllerProvider.notifier)
                .refresh();
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 16.w(context),
              vertical: 4.h(context),
            ),
            itemCount: items.length + (paginated.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == items.length) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final item = items[index];
              final statusColor = getStatusColor(item.status);

              return Card(
                margin: EdgeInsets.only(bottom: 10.h(context)),
                elevation: 0,
                color: isDark ? AppColors.darkCardBg : AppColors.cardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.w(context)),
                  side: BorderSide(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14.w(context),
                    vertical: 8.h(context),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${strings.get('order_number_hash').replaceAll('{number}', '')}${item.orderNumber}',
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AppPriceTextRow(
                        price: item.totalAmount,
                        currency: item.currency,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: EdgeInsets.only(top: 6.h(context)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.createdAt,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                            fontSize: 10.sp(context),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w(context),
                            vertical: 2.h(context),
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8.w(context)),
                          ),
                          child: Text(
                            item.status,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ConfirmedSpecialOrderDetailScreen(
                          orderId: item.id,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => AppErrorWidget(
        message: strings.failedToLoadSpecialOrders,
        onRetry: () => ref
            .read(myConfirmedSpecialOrdersControllerProvider.notifier)
            .refresh(),
      ),
    );
  }
}
