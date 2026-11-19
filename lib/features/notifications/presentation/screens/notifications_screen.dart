import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/constants/app_assets.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/app_error_utils.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/widgets/app_empty_widget.dart';
import 'package:ecommerce/core/widgets/app_error_widget.dart';
import '../providers/notifications_provider.dart';
import '../widgets/notification_item_tile.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(notificationControllerProvider.notifier).loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizationAsync = ref.watch(appLocalizationLoaderProvider);
    final currentLang = ref.watch(languageProvider);
    final strings = AppStrings(localizationAsync.value ?? {}, currentLang);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final notifAsync = ref.watch(notificationControllerProvider);

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
        title: Text(strings.notifications, style: context.textTheme.titleLarge),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await ref
                    .read(notificationControllerProvider.notifier)
                    .markAllAsRead();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppErrorUtils.extractErrorMessage(
                          e,
                          fallback: strings.failedToMarkAllRead,
                        ),
                      ),
                    ),
                  );
                }
              }
            },
            child: Text(
              strings.markAllRead,
              style: context.textTheme.primaryTitleSmall,
            ),
          ),
        ],
      ),
      body: notifAsync.when(
        data: (paginatedState) {
          final notifications = paginatedState.items;

          if (notifications.isEmpty) {
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                await ref
                    .read(notificationControllerProvider.notifier)
                    .refresh();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                children: [
                  SizedBox(height: 120.h(context)),
                  AppEmptyWidget(
                    title: strings.noNotifications,
                    subtitle: strings.noNotificationsDesc,
                    pngAsset: AppAssets.alarm,
                    size: 80.w(context),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              await ref.read(notificationControllerProvider.notifier).refresh();
            },
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.all(20.w(context)),
              itemCount:
                  notifications.length +
                  (paginatedState.isLoadingMore ||
                          paginatedState.loadMoreError != null
                      ? 1
                      : 0),
              itemBuilder: (context, index) {
                if (index == notifications.length) {
                  if (paginatedState.isLoadingMore) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.h(context)),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (paginatedState.loadMoreError != null) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.h(context)),
                      child: Column(
                        children: [
                          Text(
                            strings.failedToLoadMore,
                            style: context.textTheme.redTitleSmall,
                          ),
                          SizedBox(height: 8.h(context)),
                          ElevatedButton(
                            onPressed: () {
                              ref
                                  .read(notificationControllerProvider.notifier)
                                  .loadNextPage();
                            },
                            child: Text(strings.retry),
                          ),
                        ],
                      ),
                    );
                  }
                }

                final notification = notifications[index];
                return NotificationItemTile(
                  notification: notification,
                  isDark: isDark,
                  strings: strings,
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => AppErrorWidget(
          message: strings.failedToLoadNotifications,
          icon: Icons.notifications_none_outlined,
          onRetry: () => ref.invalidate(notificationControllerProvider),
        ),
      ),
    );
  }
}
