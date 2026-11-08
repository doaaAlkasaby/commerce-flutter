import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/network/dio_client.dart';
import '../../data/notifications_repository.dart';
import '../../models/notification_model.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  late Future<List<NotificationModel>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    _notificationsFuture = NotificationsRepository(
      ref.read(dioClientProvider),
    ).getNotifications();
  }

  Future<void> _markAllAsRead() async {
    try {
      final repo = NotificationsRepository(ref.read(dioClientProvider));
      await repo.markAllAsRead();
      setState(() {
        _loadNotifications();
      });
    } catch (_) {}
  }

  Future<void> _deleteNotification(String id) async {
    try {
      final repo = NotificationsRepository(ref.read(dioClientProvider));
      await repo.deleteNotification(id);
      setState(() {
        _loadNotifications();
      });
    } catch (_) {}
  }

  Future<void> _markAsRead(String id) async {
    try {
      final repo = NotificationsRepository(ref.read(dioClientProvider));
      await repo.markAsRead(id);
      setState(() {
        _loadNotifications();
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final localizationAsync = ref.watch(appLocalizationLoaderProvider);
    final currentLang = ref.watch(languageProvider);
    final strings = AppStrings(localizationAsync.value ?? {}, currentLang);
    final isArabic = currentLang == AppLanguage.ar;
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
                isArabic ? Icons.arrow_forward_ios : Icons.arrow_back_ios_new,
                size: 16.sp(context),
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: Text(
          strings.notifications,
          style: context.textTheme.titleLarge?.copyWith(
            fontSize: 20.sp(context),
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: Text(
              strings.markAllRead,
              style: context.textTheme.labelLarge?.copyWith(
                fontSize: 12.sp(context),
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<NotificationModel>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24.w(context)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none_outlined,
                      size: 64.sp(context),
                      color: AppColors.lightTextSecondary,
                    ),
                    SizedBox(height: 16.h(context)),
                    Text(
                      strings.noNotifications,
                      style: context.textTheme.boldTitleLarge?.copyWith(
                        fontSize: 18.sp(context),
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    SizedBox(height: 6.h(context)),
                    Text(
                      strings.noNotificationsDesc,
                      textAlign: TextAlign.center,
                      style: context.textTheme.description?.copyWith(
                        fontSize: 13.sp(context),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              setState(() {
                _loadNotifications();
              });
              await _notificationsFuture;
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.all(20.w(context)),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Dismissible(
                  key: Key(notification.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _deleteNotification(notification.id),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 20.w(context)),
                    decoration: BoxDecoration(
                      color: AppColors.badgeRed,
                      borderRadius: BorderRadius.circular(20.w(context)),
                    ),
                    child: Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 22.sp(context),
                    ),
                  ),
                  child: GestureDetector(
                    onTap: () => _markAsRead(notification.id),
                    child: Container(
                      margin: EdgeInsets.only(bottom: 14.h(context)),
                      padding: EdgeInsets.all(16.w(context)),
                      decoration: BoxDecoration(
                        color: notification.isRead
                            ? (isDark ? AppColors.darkCardBg : Colors.white)
                            : AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20.w(context)),
                        border: Border.all(
                          color: notification.isRead
                              ? Colors.transparent
                              : AppColors.primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: Offset(0, 4.h(context)),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40.w(context),
                            height: 40.h(context),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              notification.isRead
                                  ? Icons.notifications_outlined
                                  : Icons.notifications_active,
                              color: AppColors.primary,
                              size: 20.sp(context),
                            ),
                          ),
                          SizedBox(width: 14.w(context)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notification.title,
                                        style: context.textTheme.boldTitleMedium
                                            ?.copyWith(
                                              fontSize: 15.sp(context),
                                              color: isDark
                                                  ? AppColors.darkTextPrimary
                                                  : AppColors.lightTextPrimary,
                                            ),
                                      ),
                                    ),
                                    Text(
                                      notification.createdAt,
                                      style: context.textTheme.bodySmall
                                          ?.copyWith(fontSize: 11.sp(context)),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 6.h(context)),
                                Text(
                                  notification.message,
                                  style: context.textTheme.addressBody
                                      ?.copyWith(
                                        fontSize: 13.sp(context),
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
