import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerce/core/constants/app_colors.dart';
import 'package:ecommerce/core/localization/app_localizations.dart';
import 'package:ecommerce/core/theme/text_theme_extension.dart';
import 'package:ecommerce/core/utils/app_error_utils.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/features/notifications/models/notification_model.dart';
import 'package:ecommerce/features/notifications/presentation/providers/notifications_provider.dart';

class NotificationItemTile extends ConsumerWidget {
  final NotificationModel notification;
  final bool isDark;
  final AppStrings strings;

  const NotificationItemTile({
    super.key,
    required this.notification,
    required this.isDark,
    required this.strings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        try {
          await ref
              .read(notificationControllerProvider.notifier)
              .deleteNotification(notification.id);
          return true;
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppErrorUtils.extractErrorMessage(
                    e,
                    fallback: strings.failedToDeleteNotification,
                  ),
                ),
              ),
            );
          }
          return false;
        }
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w(context)),
        decoration: BoxDecoration(
          color: AppColors.badgeRed,
          borderRadius: BorderRadius.circular(20.w(context)),
        ),
        child: Icon(Icons.delete, color: Colors.white, size: 22.sp(context)),
      ),
      child: GestureDetector(
        onTap: () async {
          try {
            await ref
                .read(notificationControllerProvider.notifier)
                .markAsRead(notification.id);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppErrorUtils.extractErrorMessage(e))),
              );
            }
          }
        },
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.titleMedium,
                          ),
                        ),
                        SizedBox(width: 8.w(context)),
                        Flexible(
                          child: Text(
                            notification.createdAt.contains('T')
                                ? notification.createdAt.split('T').first
                                : notification.createdAt,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.labelSmall,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h(context)),
                    Text(
                      notification.message,
                      style: context.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
